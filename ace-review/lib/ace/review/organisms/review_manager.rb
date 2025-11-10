# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"
require "open3"

module Ace
  module Review
    module Organisms
      # Main orchestrator for code review workflow
      class ReviewManager
        attr_reader :preset_manager, :prompt_resolver, :prompt_composer,
                    :subject_extractor, :context_extractor

        def initialize
          @preset_manager = Ace::Review::Molecules::PresetManager.new
          @prompt_resolver = Ace::Review::Molecules::NavPromptResolver.new
          @prompt_composer = Ace::Review::Molecules::PromptComposer.new(resolver: @prompt_resolver)
          @subject_extractor = Ace::Review::Molecules::SubjectExtractor.new
          @context_extractor = Ace::Review::Molecules::ContextExtractor.new
        end

        # Execute a code review with the given options
        # @param options [ReviewOptions] review options object
        # @return [Hash] review results
        def execute_review(options)
          # Convert to ReviewOptions if needed
          options = ensure_review_options(options)

          # Step 1: Prepare configuration
          config_result = prepare_review_config(options)
          return config_result unless config_result[:success]

          # Step 2: Create session directory early (needed for ace-context)
          cache_dir = create_cache_directory
          session_dir = create_session_directory(options, cache_dir)

          # Step 3: Extract content
          content_result = extract_review_content(config_result[:config], options)
          return content_result unless content_result[:success]

          # Step 4: Compose prompts via ace-context
          prompt_result = compose_review_prompt(
            config_result[:config],
            content_result[:context],
            content_result[:subject],
            options.subject,  # Pass original subject configuration
            session_dir
          )
          return prompt_result unless prompt_result[:success]

          # Step 5: Prepare review data structure
          review_data = build_review_data(
            options,
            config_result[:config],
            content_result,
            prompt_result,  # Pass the entire prompt_result to handle both formats
            cache_dir
          )

          # Step 6: Save session files
          save_session_files(session_dir, review_data)

          # Step 7: Execute or just prepare
          if options.auto_execute
            execute_with_llm(review_data, session_dir)
          else
            {
              success: true,
              session_dir: session_dir,
              system_prompt_file: File.join(session_dir, "system.prompt.md"),
              user_prompt_file: File.join(session_dir, "user.prompt.md"),
              message: "Review session prepared in #{session_dir}"
            }
          end
        end

        # List available presets
        def list_presets
          @preset_manager.available_presets
        end

        # List available prompt modules
        def list_prompts
          @prompt_resolver.list_available
        end

        private

        # Ensure we have a ReviewOptions object
        def ensure_review_options(options)
          return options if options.is_a?(Models::ReviewOptions)
          Models::ReviewOptions.new(options.is_a?(Hash) ? options : {})
        end

        # Step 1: Prepare and validate configuration
        def prepare_review_config(options)
          preset_name = options.preset || "pr"

          unless @preset_manager.preset_exists?(preset_name)
            available = @preset_manager.available_presets.join(", ")
            return {
              success: false,
              error: "Preset '#{preset_name}' not found. Available: #{available}"
            }
          end

          # Resolve preset with options
          config = @preset_manager.resolve_preset(preset_name, options.to_h)

          # Merge options with config
          options.merge_config(config)

          { success: true, config: config }
        end

        # Step 2: Extract subject and context
        def extract_review_content(config, options)
          # Extract subject (what to review)
          subject_config = options.subject || config[:subject]
          subject = extract_subject(subject_config)

          if subject.nil? || subject.empty?
            return { success: false, error: "No code to review" }
          end

          # Extract context (background info)
          context_config = options.context || config[:context]

          # Create cache directory for context.md if not provided
          cache_dir = options.session_dir || create_cache_directory

          context = extract_context(context_config, cache_dir)

          {
            success: true,
            subject: subject,
            context: context,
            cache_dir: cache_dir
          }
        end

        # Step 3: Generate system and user prompts via ace-context
        def compose_review_prompt(config, context, subject, subject_config, session_dir)
          # Extract prompt composition and context config
          system_prompt_config = config[:system_prompt] || config["system_prompt"] || {}
          context_config = config[:context] || config["context"] || "project"

          # Step 3a: Create system.context.md with instructions configuration
          instructions_config = config["instructions"] || config[:instructions]
          unless instructions_config
            return {
              success: false,
              error: "No instructions found in config. All presets must use instructions format."
            }
          end
          system_context_path = create_context_file(session_dir, instructions_config, context_config, "system.context.md")

          # Step 3b: Create user.context.md with subject configuration
          subject_config = config["subject"] || config[:subject]
          unless subject_config
            return {
              success: false,
              error: "No subject found in config. All presets must use subject format."
            }
          end
          user_context_path = create_context_file(session_dir, subject_config, nil, "user.context.md")

          # Step 3c: Generate system.prompt.md via ace-context
          system_prompt_path = File.join(session_dir, "system.prompt.md")
          unless execute_ace_context(system_context_path, system_prompt_path)
            return { success: false, error: "Failed to generate system prompt via ace-context" }
          end

          # Step 3d: Generate user.prompt.md via ace-context
          user_prompt_path = File.join(session_dir, "user.prompt.md")
          unless execute_ace_context(user_context_path, user_prompt_path)
            return { success: false, error: "Failed to generate user prompt via ace-context" }
          end

          # Load the generated prompts
          system_prompt = File.read(system_prompt_path) if File.exist?(system_prompt_path)
          user_prompt = File.read(user_prompt_path) if File.exist?(user_prompt_path)

          if system_prompt.nil? || system_prompt.empty?
            return { success: false, error: "Failed to generate system prompt" }
          end

          {
            success: true,
            system_prompt: system_prompt,
            user_prompt: user_prompt || "Please review the provided code.",
            system_prompt_path: system_prompt_path,
            user_prompt_path: user_prompt_path
          }
        end

        # Detect whether preset uses instructions format or legacy system_prompt format
        def uses_instructions_format?(resolved_config)
          instructions = resolved_config["instructions"] || resolved_config[:instructions]
          instructions && instructions.is_a?(Hash)
        end

        # Unified context file processor - pass configuration directly to ace-context
        def create_context_file(session_dir, context_config, additional_context, output_filename)
          # Build complete ace-context configuration
          ace_context_config = {}

          # Normalize and merge context_config if provided
          if context_config
            normalized_config = normalize_context_config(context_config)
            ace_context_config = deep_merge_context(ace_context_config, normalized_config)
          end

          # Add additional context as "context" key for ace-context, but avoid duplicates
          if additional_context && additional_context != "none" && !additional_context.empty?
            ace_context_config["context"] ||= {}
            if additional_context.is_a?(String)
              # Check if this preset is already included in the sections to avoid duplication
              existing_presets = extract_presets_from_sections(ace_context_config)
              unless existing_presets.include?(additional_context)
                ace_context_config["context"]["presets"] ||= []
                ace_context_config["context"]["presets"] << additional_context
              end
            elsif additional_context.is_a?(Hash)
              additional_normalized = normalize_context_config(additional_context)
              ace_context_config = deep_merge_context(ace_context_config, additional_normalized)
            end
          end

          # Create context.md content with full configuration as frontmatter
          context_content = "#{YAML.dump(ace_context_config).strip}\n---\n\n"

          # Write to file
          context_path = File.join(session_dir, output_filename)
          File.write(context_path, context_content)

          context_path
        end

        # Normalize various input types to proper ace-context structure
        def normalize_context_config(input)
          case input
          when String
            # String input (e.g., "project", "staged") -> wrap as preset
            { "context" => { "presets" => [input] } }
          when Hash
            # Check if this config has a top-level "base" key that needs to be moved
            has_base = input.key?("base") || input.key?(:base)
            has_context = input.key?("context") || input.key?(:context)

            if has_base && !has_context
              # Config has base: at top level but no context: key
              # Need to move base under context.base and wrap other keys
              normalized = { "context" => {} }

              input.each do |key, value|
                key_str = key.to_s
                if key_str == "base"
                  # Move top-level base to context.base
                  normalized["context"]["base"] = value
                else
                  # Other top-level keys go under context
                  normalized["context"][key_str] = value
                end
              end

              normalized
            elsif has_base && has_context
              # Config has both base: and context: at top level
              # Move base under context.base
              normalized = {}
              base_value = input["base"] || input[:base]

              input.each do |key, value|
                key_str = key.to_s
                if key_str == "base"
                  # Skip - will add under context.base below
                  next
                elsif key_str == "context"
                  # Merge context and add base under it
                  context_hash = value.is_a?(Hash) ? value.dup : {}
                  context_hash["base"] = base_value
                  normalized["context"] = context_hash
                else
                  normalized[key_str] = value
                end
              end

              normalized
            else
              # Config already properly structured or doesn't need normalization
              input
            end
          else
            # Fallback for other types
            {}
          end
        end

        # Deep merge two context configurations
        def deep_merge_context(base, overlay)
          result = base.dup

          overlay.each do |key, value|
            if result[key].is_a?(Hash) && value.is_a?(Hash)
              result[key] = deep_merge_hash(result[key], value)
            else
              result[key] = value
            end
          end

          result
        end

        # Deep merge helper for nested hashes
        def deep_merge_hash(base, overlay)
          result = base.dup

          overlay.each do |key, value|
            if result[key].is_a?(Hash) && value.is_a?(Hash)
              result[key] = deep_merge_hash(result[key], value)
            elsif result[key].is_a?(Array) && value.is_a?(Array)
              result[key] = (result[key] + value).uniq
            else
              result[key] = value
            end
          end

          result
        end

        # Extract preset names from sections to avoid duplication
        def extract_presets_from_sections(config)
          presets = []
          return presets unless config.is_a?(Hash)

          # Check if config has context with sections
          context = config["context"] || config[:context]
          return presets unless context.is_a?(Hash)

          sections = context["sections"] || context[:sections]
          return presets unless sections.is_a?(Hash)

          # Extract presets from all sections
          sections.each do |section_name, section_config|
            if section_config.is_a?(Hash)
              section_presets = section_config["presets"] || section_config[:presets]
              if section_presets.is_a?(Array)
                presets.concat(section_presets)
              end
            end
          end

          presets.uniq
        end


        # Execute ace-context to generate prompts using Ruby API
        def execute_ace_context(input_file, output_file)
          begin
            require 'ace/context'
          rescue LoadError => e
            warn "Failed to load ace-context: #{e.message}" if Ace::Review.debug?
            return false
          end

          begin
            # Load context using ace-context Ruby API
            context_result = Ace::Context.load_file_as_preset(input_file)

            # Check for errors in metadata
            if context_result.metadata[:error]
              warn "ace-context failed: #{context_result.metadata[:error]}" if Ace::Review.debug?
              return false
            end

            # Write the rendered content to output file
            File.write(output_file, context_result.content)
            true
          rescue StandardError => e
            warn "ace-context failed: #{e.message}" if Ace::Review.debug?
            false
          end
        end

        # Build the complete review data structure
        def build_review_data(options, config, content, prompt_result, cache_dir)
          # v0.13.0 architecture: only supports system/user prompt format
          review_data = {
            preset: options.preset,
            config: config,
            subject: content[:subject],
            context: content[:context],
            model: options.effective_model(config[:model]),
            cache_dir: cache_dir,
            system_prompt: prompt_result[:system_prompt],
            user_prompt: prompt_result[:user_prompt],
            system_prompt_path: prompt_result[:system_prompt_path],
            user_prompt_path: prompt_result[:user_prompt_path]
          }

          review_data
        end

        def extract_subject(subject_config)
          return "" unless subject_config
          @subject_extractor.extract(subject_config)
        end

        def extract_context(context_config, cache_dir = nil)
          @context_extractor.extract(context_config, cache_dir)
        end

        def execute_with_llm(review_data, session_dir)
          executor = Ace::Review::Molecules::LlmExecutor.new

          # v0.13.0 architecture: only supports system/user prompt format
          result = executor.execute(
            system_prompt: review_data[:system_prompt],
            user_prompt: review_data[:user_prompt],
            model: review_data[:model],
            session_dir: session_dir
          )

          if result[:success]
            # Save Ruby API metadata if available
            save_ruby_api_metadata(session_dir, result) if result[:metadata]

            # Copy final review to release folder
            release_path = copy_to_release(session_dir, review_data)

            # Return enhanced result with metadata for backward compatibility
            {
              success: true,
              output_file: release_path || result[:output_file],
              message: release_path ? "Review saved to #{release_path}" : "Review saved to #{result[:output_file]}",
              usage: result[:usage],
              model_info: result[:model_info],
              provider_info: result[:provider_info]
            }
          else
            # Enhanced error information from Ruby API
            error_result = result.dup
            if result[:error_type]
              error_result[:enhanced_error] = "#{result[:error_type]}: #{result[:error]}"
            end
            error_result
          end
        end

        def save_session_files(session_dir, review_data)
          # v0.13.0+ architecture: system and user prompts are already saved as .prompt.md files
          # Subject and context are handled directly via ace-context workflow, no need for separate files

          # Save metadata (committable - no .tmp extension)
          metadata = create_metadata(review_data)
          File.write(File.join(session_dir, "metadata.yml"), YAML.dump(metadata))
        end

        def save_review_output(response, review_data, session_dir)
          # Save review to session directory as review.md
          output_file = File.join(session_dir, "review.md")

          # Add metadata header to response
          full_content = add_review_metadata(response, review_data)

          File.write(output_file, full_content)

          {
            success: true,
            output_file: output_file,
            message: "Review saved to #{output_file}"
          }
        end

        def create_session_directory(options, cache_dir)
          if options.session_dir
            FileUtils.mkdir_p(options.session_dir)
            return options.session_dir
          end

          # Use cache directory (cache-first approach)
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          session_dir = File.join(cache_dir, "review-#{timestamp}")
          FileUtils.mkdir_p(session_dir)
          session_dir
        end

        def create_cache_directory
          # Create cache directory in .cache/ace-review/sessions/
          base_cache_path = File.join(Dir.pwd, ".cache", "ace-review", "sessions")
          FileUtils.mkdir_p(base_cache_path)
          base_cache_path
        end

    
        def copy_to_release(session_dir, review_data)
          # Copy final review reports to release folder
          release_base_path = @preset_manager.review_base_path
          FileUtils.mkdir_p(release_base_path)

          # Create output filename
          model_slug = review_data[:model].gsub(/[^a-zA-Z0-9\-_]/, '-').downcase
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          release_filename = "review-report-#{model_slug}-#{timestamp}.md"
          release_path = File.join(release_base_path, release_filename)

          # Copy review file if it exists
          review_file = File.join(session_dir, "review.md")
          if File.exist?(review_file)
            FileUtils.cp(review_file, release_path)
            return release_path
          end

          nil
        end


        def create_metadata(review_data)
          {
            "timestamp" => Time.now.iso8601,
            "preset" => review_data[:preset],
            "model" => review_data[:model],
            "has_context" => !review_data[:context].empty?,
            "subject_size" => review_data[:subject].length,
            "system_prompt_size" => review_data[:system_prompt].length,
            "user_prompt_size" => review_data[:user_prompt].length
          }
        end

        def save_ruby_api_metadata(session_dir, result)
          # Save rich metadata from Ruby API
          metadata_file = File.join(session_dir, "llm_metadata.yml")
          metadata_content = {
            "timestamp" => Time.now.iso8601,
            "usage" => result[:usage],
            "model_info" => result[:model_info],
            "provider_info" => result[:provider_info],
            "raw_metadata" => result[:metadata]
          }
          File.write(metadata_file, YAML.dump(metadata_content))
        end

        def add_review_metadata(response, review_data)
          metadata = <<~METADATA
            ---
            timestamp: #{Time.now.iso8601}
            preset: #{review_data[:preset]}
            model: #{review_data[:model]}
            ---

          METADATA

          metadata + response
        end
      end
    end
    end
  end
