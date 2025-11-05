# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"

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

          # Step 2: Extract content
          content_result = extract_review_content(config_result[:config], options)
          return content_result unless content_result[:success]

          # Step 3: Compose prompt
          prompt_result = compose_review_prompt(
            config_result[:config],
            content_result[:context],
            content_result[:subject]
          )
          return prompt_result unless prompt_result[:success]

          # Step 4: Prepare review data structure
          review_data = build_review_data(
            options,
            config_result[:config],
            content_result,
            prompt_result[:prompt]
          )

          # Step 5: Create session directory
          session_dir = create_session_directory(options, review_data[:cache_dir])

          # Step 6: Save session files
          save_session_files(session_dir, review_data)

          # Step 7: Execute or just prepare
          if options.auto_execute
            execute_with_llm(review_data, session_dir)
          else
            {
              success: true,
              session_dir: session_dir,
              prompt_file: File.join(session_dir, "prompt.md.tmp"),
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

        # Step 3: Compose the review prompt
        def compose_review_prompt(config, context, subject)
          # Build prompt composition from options or config
          composition = config[:prompt_composition] || {}

          prompt = @prompt_composer.build_review_prompt(
            composition,
            context,
            subject,
            config_dir: File.dirname(@preset_manager.config_path || ".")
          )

          if prompt.nil? || prompt.empty?
            return { success: false, error: "Failed to compose prompt" }
          end

          { success: true, prompt: prompt }
        end

        # Build the complete review data structure
        def build_review_data(options, config, content, prompt)
          {
            preset: options.preset,
            config: config,
            subject: content[:subject],
            context: content[:context],
            prompt: prompt,
            model: options.effective_model(config[:model]),
            cache_dir: content[:cache_dir]
          }
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

          result = executor.execute(
            prompt: review_data[:prompt],
            model: review_data[:model],
            session_dir: session_dir
          )

          if result[:success]
            # Copy final review to release folder
            release_path = copy_to_release(session_dir, review_data)

            # Return the release path for backward compatibility
            {
              success: true,
              output_file: release_path || result[:output_file],
              message: release_path ? "Review saved to #{release_path}" : "Review saved to #{result[:output_file]}"
            }
          else
            result
          end
        end

        def save_session_files(session_dir, review_data)
          # Split prompt into system and user files (no .tmp extension)
          split_and_save_prompts(session_dir, review_data[:prompt])

          # Save subject (no .tmp extension)
          File.write(File.join(session_dir, "subject.md"), review_data[:subject])

          # Save context if present (no .tmp extension)
          unless review_data[:context].empty?
            File.write(File.join(session_dir, "context.md"), review_data[:context])
          end

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

        def split_and_save_prompts(session_dir, prompt)
          # Split prompt into system and user parts
          # Look for system/user separator or split evenly
          if prompt.include?("---")
            # Split at YAML frontmatter separator
            parts = prompt.split("---", 2)
            system_prompt = parts[0].strip
            user_prompt = parts[1].strip
          elsif prompt.include?("\n\n")
            # Split at first double newline (simple heuristic)
            parts = prompt.split("\n\n", 2)
            system_prompt = parts[0].strip
            user_prompt = parts[1].strip
          else
            # Split evenly as fallback
            mid_point = prompt.length / 2
            system_prompt = prompt[0...mid_point].strip
            user_prompt = prompt[mid_point..-1].strip
          end

          # Save system and user prompts
          File.write(File.join(session_dir, "prompt-system.md"), system_prompt)
          File.write(File.join(session_dir, "prompt-user.md"), user_prompt)
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
            "prompt_size" => review_data[:prompt].length
          }
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