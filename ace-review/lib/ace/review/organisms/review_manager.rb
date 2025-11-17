# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"
require "open3"
require "ace/core/molecules/project_root_finder"

module Ace
  module Review
    module Organisms
      # Main orchestrator for code review workflow
      class ReviewManager
        attr_reader :preset_manager, :prompt_resolver, :prompt_composer,
                    :subject_extractor, :context_extractor
        attr_accessor :task_reference

        def initialize
          @preset_manager = Ace::Review::Molecules::PresetManager.new
          @prompt_resolver = Ace::Review::Molecules::NavPromptResolver.new
          @prompt_composer = Ace::Review::Molecules::PromptComposer.new(resolver: @prompt_resolver)
          @subject_extractor = Ace::Review::Molecules::SubjectExtractor.new
          @context_extractor = Ace::Review::Molecules::ContextExtractor.new
          @task_reference = nil
        end

        # Execute a code review with the given options
        # @param options [ReviewOptions] review options object
        # @return [Hash] review results
        def execute_review(options)
          # Convert to ReviewOptions if needed
          options = ensure_review_options(options)

          # Capture task reference for later use
          @task_reference = options.task

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
            execute_with_llm(review_data, session_dir, options)
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
          prompts = @prompt_resolver.list_available
          prompts.is_a?(Hash) ? prompts.keys : []
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
          # Handle PR mode
          if options.pr_review?
            return extract_pr_content(options.pr, config, options)
          end

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

        # Extract PR content (diff and metadata)
        def extract_pr_content(pr_identifier, config, options)
          # Fetch PR diff and metadata
          fetch_options = options.gh_timeout ? { timeout: options.gh_timeout } : {}
          result = Ace::Review::Molecules::GhPrFetcher.fetch_pr(pr_identifier, fetch_options)

          unless result[:success]
            return { success: false, error: result[:error] }
          end

          # Store PR metadata in options for later use
          options.pr_metadata = result[:metadata]

          # Create cache directory
          cache_dir = options.session_dir || create_cache_directory

          # Extract context (background info)
          context_config = options.context || config[:context]
          context = extract_context(context_config, cache_dir)

          # Add PR metadata to context
          pr_info = format_pr_metadata(result[:metadata])

          {
            success: true,
            subject: result[:diff],
            context: context.empty? ? pr_info : "#{context}\n\n#{pr_info}",
            cache_dir: cache_dir,
            pr_metadata: result[:metadata]
          }
        end

        # Format PR metadata for context
        def format_pr_metadata(metadata)
          info = "## Pull Request Information\n\n"
          info += "- **Title**: #{metadata['title']}\n"
          info += "- **Number**: ##{metadata['number']}\n"
          info += "- **Author**: #{metadata['author']['login']}\n" if metadata['author']
          info += "- **State**: #{metadata['state']}\n"
          info += "- **Draft**: #{metadata['isDraft'] ? 'Yes' : 'No'}\n"
          info += "- **Base**: #{metadata['baseRefName']}\n"
          info += "- **Head**: #{metadata['headRefName']}\n"
          info += "- **URL**: #{metadata['url']}\n"
          info
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

          # If no subject config but we have subject content (e.g., from PR mode),
          # save to file and create subject config referencing the file.
          # This allows us to feed the PR diff into the standard ace-context composition
          # process without altering the core workflow - the PR diff becomes just another
          # context source that ace-context knows how to handle.
          if !subject_config && subject && !subject.empty?
            # Save PR diff to session file
            pr_diff_path = File.join(session_dir, "pr-diff.patch")
            File.write(pr_diff_path, subject)

            # Create subject config referencing the file
            subject_config = {
              "context" => {
                "sections" => {
                  "pr_changes" => {
                    "title" => "Pull Request Changes",
                    "description" => "Code changes from GitHub Pull Request",
                    "files" => [pr_diff_path]
                  }
                }
              }
            }
          end

          unless subject_config
            return {
              success: false,
              error: "No subject found in config. All presets must use subject format."
            }
          end
          user_context_path = create_context_file(session_dir, subject_config, nil, "user.context.md")

          # Step 3c: Generate system.prompt.md via ace-context
          system_prompt_path = File.join(session_dir, "system.prompt.md")
          begin
            execute_ace_context(system_context_path, system_prompt_path)
          rescue Errors::MissingDependencyError, Errors::ContextProcessingError => e
            return { success: false, error: "Failed to generate system prompt: #{e.message}" }
          end

          # Step 3d: Generate user.prompt.md via ace-context
          user_prompt_path = File.join(session_dir, "user.prompt.md")
          begin
            execute_ace_context(user_context_path, user_prompt_path)
          rescue Errors::MissingDependencyError, Errors::ContextProcessingError => e
            return { success: false, error: "Failed to generate user prompt: #{e.message}" }
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
            normalized_config = Atoms::ContextNormalizer.normalize_context_config(context_config)
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
              additional_normalized = Atoms::ContextNormalizer.normalize_context_config(additional_context)
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

        # Deep merge two context configurations (top-level wrapper)
        #
        # Merges overlay into base with smart type handling. This is a simplified
        # version that delegates to deep_merge_hash for all hash values.
        #
        # @param base [Hash] Base configuration (lower priority)
        # @param overlay [Hash] Overlay configuration (higher priority)
        # @return [Hash] Merged configuration
        #
        # @example Simple merge
        #   deep_merge_context({a: 1}, {b: 2})
        #   #=> {a: 1, b: 2}
        #
        # @example Nested hash merge
        #   deep_merge_context({a: {b: 1}}, {a: {c: 2}})
        #   #=> {a: {b: 1, c: 2}}
        #
        # @api private
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

        # Deep merge two hashes with smart type handling
        #
        # Recursively merges two hashes following these rules:
        # - Hashes: Recursively merged (keys from both hashes preserved)
        # - Arrays: Concatenated and deduplicated (first occurrence preserved)
        # - Scalars: Overlay value wins (replaces base value)
        # - Type conflicts: Overlay value wins (e.g., hash vs array)
        #
        # @param base [Hash] Base hash (lower priority)
        # @param overlay [Hash] Overlay hash (higher priority)
        # @return [Hash] Deeply merged result
        #
        # @example Simple merge
        #   deep_merge_hash({a: 1}, {b: 2})
        #   #=> {a: 1, b: 2}
        #
        # @example Nested hash merge (3 levels)
        #   base = {context: {sections: {code: {files: ["a.rb"]}}}}
        #   overlay = {context: {sections: {code: {files: ["b.rb"]}}}}
        #   deep_merge_hash(base, overlay)
        #   #=> {context: {sections: {code: {files: ["a.rb", "b.rb"]}}}}
        #
        # @example Array concatenation with deduplication
        #   deep_merge_hash({files: ["a.rb", "b.rb"]}, {files: ["b.rb", "c.rb"]})
        #   #=> {files: ["a.rb", "b.rb", "c.rb"]}  # "b.rb" appears only once
        #
        # @example Scalar override
        #   deep_merge_hash({model: "gpt-4"}, {model: "claude"})
        #   #=> {model: "claude"}
        #
        # @example Type conflict (hash vs array)
        #   deep_merge_hash({files: {a: 1}}, {files: ["a.rb"]})
        #   #=> {files: ["a.rb"]}  # overlay array wins over base hash
        #
        # @note Array merge preserves order of first occurrence. The concatenation
        #   is (base + overlay).uniq, so if an element appears in both arrays,
        #   it will appear at its position in the base array.
        #
        # @api private
        def deep_merge_hash(base, overlay)
          result = base.dup

          overlay.each do |key, value|
            if result[key].is_a?(Hash) && value.is_a?(Hash)
              # Recursively merge nested hashes
              result[key] = deep_merge_hash(result[key], value)
            elsif result[key].is_a?(Array) && value.is_a?(Array)
              # Concatenate arrays and remove duplicates (first occurrence wins)
              result[key] = (result[key] + value).uniq
            else
              # For scalars or type conflicts, overlay wins
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
        # @param input_file [String] Path to context configuration file
        # @param output_file [String] Path to write rendered context
        # @raise [Errors::MissingDependencyError] If ace-context gem not available
        # @raise [Errors::ContextProcessingError] If context processing fails
        # @return [true] On success
        def execute_ace_context(input_file, output_file)
          # Ensure ace-context is available
          begin
            require 'ace/context'
          rescue LoadError => e
            raise Errors::MissingDependencyError.new(
              "ace-context",
              "gem install ace-context"
            )
          end

          # Check if Ace::Context is actually defined (might fail silently)
          unless defined?(Ace::Context)
            raise Errors::MissingDependencyError.new(
              "ace-context",
              "gem install ace-context"
            )
          end

          begin
            # Load context using ace-context Ruby API
            context_result = Ace::Context.load_file(input_file)

            # Check for errors in metadata
            if context_result.metadata[:error]
              error_message = context_result.metadata[:error]
              raise Errors::ContextProcessingError.new(
                "Failed to process context file: #{error_message}",
                { input_file: input_file, error: error_message }
              )
            end

            # Write the rendered content to output file
            File.write(output_file, context_result.content)
            true
          rescue Errors::ContextProcessingError
            # Re-raise our own errors
            raise
          rescue StandardError => e
            raise Errors::ContextProcessingError.new(
              "ace-context processing failed: #{e.message}",
              { input_file: input_file, error: e.message, backtrace: e.backtrace.first(5) }
            )
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

        def execute_with_llm(review_data, session_dir, options = nil)
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

            # Save to task directory if --task flag provided
            task_path = save_to_task_if_requested(review_data, session_dir)

            # Handle PR comment posting if requested
            comment_result = nil
            if options && options.should_post_comment?
              comment_result = post_pr_comment(options, result[:output_file], review_data)
            end

            # Build result message
            messages = []
            messages << "Review saved to #{release_path}" if release_path
            messages << "Review saved to #{task_path}" if task_path
            messages << "Review saved to #{result[:output_file]}" if messages.empty?

            # Build response with comment info if applicable
            response = {
              success: true,
              output_file: release_path || task_path || result[:output_file],
              message: messages.join("\n"),
              task_path: task_path,
              usage: result[:usage],
              model_info: result[:model_info],
              provider_info: result[:provider_info]
            }

            # Add comment info to response
            if comment_result && comment_result[:success]
              if comment_result[:dry_run]
                # Dry-run mode: add preview to response
                response[:dry_run_preview] = comment_result[:preview]
              else
                # Actual posting: add comment URL
                response[:comment_url] = comment_result[:comment_url]
                response[:message] += "\n✓ Review posted to PR: #{comment_result[:comment_url]}"
              end
            elsif comment_result && !comment_result[:success]
              response[:comment_error] = comment_result[:error]
              response[:message] += "\n✗ Failed to post comment: #{comment_result[:error]}"
            end

            response
          else
            # Enhanced error information from Ruby API
            error_result = result.dup
            if result[:error_type]
              error_result[:enhanced_error] = "#{result[:error_type]}: #{result[:error]}"
            end
            error_result
          end
        end

        # Post review comment to PR
        def post_pr_comment(options, review_file, review_data)
          return { success: false, error: "No review file to post" } unless File.exist?(review_file)

          # Read review content
          review_content = File.read(review_file)

          # Prepare metadata for comment
          metadata = {
            preset: review_data[:preset],
            model: review_data[:model],
            timestamp: Time.now.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
          }

          # Post comment
          Ace::Review::Molecules::GhCommentPoster.post_comment(
            options.pr,
            review_content,
            metadata: metadata,
            dry_run: options.dry_run
          )
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

          # All reviews use the same naming pattern
          session_dir = File.join(cache_dir, "review-#{timestamp}")

          FileUtils.mkdir_p(session_dir)
          session_dir
        end

        def create_cache_directory
          # Create cache directory in .cache/ace-review/sessions/ relative to project root
          # Use ProjectRootFinder to support both main repos and git worktrees
          project_root = Ace::Core::Molecules::ProjectRootFinder.find_or_current
          base_cache_path = File.join(project_root, ".cache", "ace-review", "sessions")
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

        # Save review report to task directory if --task flag provided
        # @param review_data [Hash] Review metadata
        # @param session_dir [String] Session directory path
        # @return [String, nil] Path to saved report or nil if not saved
        def save_to_task_if_requested(review_data, session_dir)
          return nil unless @task_reference

          begin
            # Lazily require taskflow components to keep it an optional dependency.
            # This allows ace-review to function even if ace-taskflow is not installed.
            require_relative '../molecules/task_resolver'
            require_relative '../molecules/task_report_saver'

            # Resolve task reference to directory path
            task_info = Molecules::TaskResolver.resolve(@task_reference)

            unless task_info
              warn "Warning: Task '#{@task_reference}' not found. Review completed but report not saved to task."
              return nil
            end

            # Save report to task directory
            result = Molecules::TaskReportSaver.save(task_info[:path], session_dir, review_data)

            if result[:success]
              result[:path]
            else
              warn "Warning: #{result[:error]}. Review completed but report not saved to task."
              nil
            end
          rescue LoadError => e
            # ace-taskflow not available
            warn "Warning: ace-taskflow gem not available. Review completed but not saved to task." if $DEBUG
            nil
          rescue => e
            # Unexpected error - log but don't fail the review
            warn "Warning: Failed to save review to task: #{e.message}. Review completed." if $DEBUG
            nil
          end
        end
      end
    end
    end
  end
