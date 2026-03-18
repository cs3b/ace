# frozen_string_literal: true

require "fileutils"
require "pathname"
require "time"
require "yaml"
require "open3"
require "ace/support/fs"
require "ace/b36ts"
require "ace/bundle/atoms/bundle_normalizer"

module Ace
  module Review
    module Organisms
      # Main orchestrator for code review workflow
      class ReviewManager
        attr_reader :preset_manager, :prompt_resolver, :prompt_composer,
                    :subject_extractor, :context_extractor

        def initialize(project_root: nil)
          @project_root = project_root
          @preset_manager = Ace::Review::Molecules::PresetManager.new(project_root: project_root)
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

          # Step 2: Create session directory early (needed for ace-bundle)
          cache_dir = create_cache_directory
          session_dir = create_session_directory(options, cache_dir)

          # Step 3: Extract content
          content_result = extract_review_content(config_result[:config], options)
          return content_result unless content_result[:success]

          # Step 4: Compose prompts via ace-bundle
          prompt_result = compose_review_prompt(
            config_result[:config],
            content_result[:context],
            content_result[:subject],
            session_dir,
            options,  # Pass options to check for PR mode
            content_result[:typed_subject_config]  # Pass typed subject config directly
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
          preset_name = options.preset

          unless preset_name
            return {
              success: false,
              error: "No preset specified. Use --preset NAME or set defaults.preset in .ace/review/config.yml"
            }
          end

          unless @preset_manager.preset_exists?(preset_name)
            available = @preset_manager.available_presets.join(", ")
            return {
              success: false,
              error: "Preset '#{preset_name}' not found. Available: #{available}"
            }
          end

          # Resolve preset with options
          config = @preset_manager.resolve_preset(preset_name, options.to_h)

          # Check for composition failure (circular deps, missing refs return nil)
          unless config
            return {
              success: false,
              error: "Failed to load preset '#{preset_name}'. Check for circular dependencies or missing preset references."
            }
          end

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

          # Handle array of subjects - merge configs without extraction
          # This allows multiple --subject flags to be combined into a single ace-bundle config
          if subject_config.is_a?(Array)
            merged_config = @subject_extractor.merge_typed_subject_configs(subject_config)
            if merged_config
              cache_dir = options.session_dir || create_cache_directory
              context_config = options.context || config[:context]
              context = extract_context(context_config, cache_dir)

              return {
                success: true,
                typed_subject_config: merged_config,  # Pass merged config, not content
                subject: nil,  # No pre-extracted content
                context: context,
                cache_dir: cache_dir
              }
            end
          end

          # Check for typed subject - pass config directly to ace-bundle (no extraction)
          # This avoids extracting content only to save it and re-read it
          if subject_config.is_a?(String)
            typed_config = @subject_extractor.parse_typed_subject_config(subject_config)
            if typed_config
              # Create cache directory for context.md if not provided
              cache_dir = options.session_dir || create_cache_directory

              # Extract context (background info)
              context_config = options.context || config[:context]
              context = extract_context(context_config, cache_dir)

              return {
                success: true,
                typed_subject_config: typed_config,  # Pass config, not content
                subject: nil,  # No pre-extracted content
                context: context,
                cache_dir: cache_dir
              }
            end
          end

          # Fall back to legacy flow for non-typed subjects
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

          # Fetch PR comments if enabled
          if options.include_pr_comments?
            comments_result = Ace::Review::Molecules::GhPrCommentFetcher.fetch(pr_identifier, fetch_options)
            if comments_result[:success]
              if Ace::Review::Molecules::GhPrCommentFetcher.has_comments?(comments_result)
                options.pr_comment_data = comments_result
              end
            else
              # Log warning but continue with review (comments are optional enhancement)
              warn "Warning: Failed to fetch PR comments: #{comments_result[:error]}. " \
                   "Review will proceed without developer feedback."
            end
          end

          # Create cache directory
          cache_dir = options.session_dir || create_cache_directory

          # Extract context (background info) and enrich with task behavioral spec when available.
          context_config = options.context || config[:context]
          spec_aware_context = build_pr_context_with_task_spec(
            context_config: context_config,
            pr_metadata: result[:metadata]
          )
          context = extract_context(spec_aware_context, cache_dir)

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

        # Add task behavioral spec file to PR context when task can be detected.
        def build_pr_context_with_task_spec(context_config:, pr_metadata:)
          spec_path = Molecules::PrTaskSpecResolver.resolve_spec_path(pr_metadata)
          return context_config unless spec_path

          case context_config
          when nil, false, "none"
            { "files" => [spec_path] }
          when String
            { "presets" => [context_config], "files" => [spec_path] }
          when Hash
            deep_merge_context(context_config, { "files" => [spec_path] })
          else
            { "files" => [spec_path] }
          end
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

        # Step 3: Generate system and user prompts via ace-bundle
        def compose_review_prompt(config, context, subject, session_dir, options = nil, typed_subject_config = nil)
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
          subject_config = resolve_subject_config(
            config: config,
            subject: subject,
            session_dir: session_dir,
            options: options,
            typed_subject_config: typed_subject_config
          )

          unless subject_config
            return {
              success: false,
              error: "No subject found in config. All presets must use subject format."
            }
          end
          user_context_path = create_context_file(session_dir, subject_config, nil, "user.context.md")

          # Step 3c: Generate system.prompt.md via ace-bundle
          system_prompt_path = File.join(session_dir, "system.prompt.md")
          begin
            execute_ace_context(system_context_path, system_prompt_path)
          rescue Errors::MissingDependencyError, Errors::BundleProcessingError => e
            return { success: false, error: "Failed to generate system prompt: #{e.message}" }
          end

          # Step 3d: Generate user.prompt.md via ace-bundle
          user_prompt_path = File.join(session_dir, "user.prompt.md")
          begin
            execute_ace_context(user_context_path, user_prompt_path)
          rescue Errors::MissingDependencyError, Errors::BundleProcessingError => e
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

        # Unified context file processor - pass configuration directly to ace-bundle
        def create_context_file(session_dir, context_config, additional_context, output_filename)
          # Build complete ace-bundle configuration
          ace_context_config = {}

          # Normalize and merge context_config if provided
          if context_config
            normalized_config = Ace::Bundle::Atoms::BundleNormalizer.normalize_config(context_config)
            ace_context_config = deep_merge_context(ace_context_config, normalized_config)
          end

          # Add additional context as "bundle" key for ace-bundle, but avoid duplicates
          if additional_context && additional_context != "none" && !additional_context.empty?
            ace_context_config["bundle"] ||= {}
            if additional_context.is_a?(String)
              # Check if this preset is already included in the sections to avoid duplication
              existing_presets = extract_presets_from_sections(ace_context_config)
              unless existing_presets.include?(additional_context)
                ace_context_config["bundle"]["presets"] ||= []
                ace_context_config["bundle"]["presets"] << additional_context
              end
            elsif additional_context.is_a?(Hash)
              additional_normalized = Ace::Bundle::Atoms::BundleNormalizer.normalize_config(additional_context)
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
          # Use centralized DeepMerger with :union strategy for array deduplication
          Ace::Support::Config::Atoms::DeepMerger.merge(base, overlay, array_strategy: :union)
        end

        # Extract preset names from sections to avoid duplication
        def extract_presets_from_sections(config)
          presets = []
          return presets unless config.is_a?(Hash)

          # Check if config has bundle with sections
          bundle = config["bundle"] || config[:bundle]
          return presets unless bundle.is_a?(Hash)

          sections = bundle["sections"] || bundle[:sections]
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


        # Execute ace-bundle to generate prompts using Ruby API
        # @param input_file [String] Path to context configuration file
        # @param output_file [String] Path to write rendered context
        # @raise [Errors::MissingDependencyError] If ace-bundle gem not available
        # @raise [Errors::BundleProcessingError] If context processing fails
        # @return [true] On success
        def execute_ace_context(input_file, output_file)
          # Ensure ace-bundle is available
          begin
            require 'ace/bundle'
          rescue LoadError => e
            raise Errors::MissingDependencyError.new(
              "ace-bundle",
              "gem install ace-bundle"
            )
          end

          # Check if Ace::Bundle is actually defined (might fail silently)
          unless defined?(Ace::Bundle)
            raise Errors::MissingDependencyError.new(
              "ace-bundle",
              "gem install ace-bundle"
            )
          end

          begin
            # Load context using ace-bundle Ruby API
            context_result = Ace::Bundle.load_file(input_file)

            # Check for fatal error in metadata
            if context_result.metadata[:error]
              error_message = context_result.metadata[:error]
              raise Errors::BundleProcessingError.new(
                "Failed to process context file: #{error_message}",
                { input_file: input_file, error: error_message }
              )
            end

            # Surface non-fatal errors (e.g., PR fetch failures) as warnings
            # These are stored in metadata[:errors] array by ace-bundle
            if context_result.metadata[:errors]&.any?
              context_result.metadata[:errors].each do |error_msg|
                warn "[ace-review] Warning: #{error_msg}"
              end
            end

            # Write the rendered content to output file
            File.write(output_file, context_result.content)
            true
          rescue Errors::BundleProcessingError
            # Re-raise our own errors
            raise
          rescue StandardError => e
            raise Errors::BundleProcessingError.new(
              "ace-bundle processing failed: #{e.message}",
              { input_file: input_file, error: e.message, backtrace: e.backtrace.first(5) }
            )
          end
        end

        # Build the complete review data structure
        def build_review_data(options, config, content, prompt_result, cache_dir)
          # v0.13.0 architecture: only supports system/user prompt format
          effective_models = options.effective_models(config[:models])

          review_data = {
            preset: options.preset,
            config: config,
            subject: content[:subject],
            context: content[:context],
            model: effective_models.first,
            models: effective_models,
            cache_dir: cache_dir,
            system_prompt: prompt_result[:system_prompt],
            user_prompt: prompt_result[:user_prompt],
            system_prompt_path: prompt_result[:system_prompt_path],
            user_prompt_path: prompt_result[:user_prompt_path]
          }

          # Include PR comment data if available
          review_data[:pr_comment_data] = options.pr_comment_data if options.pr_comment_data

          review_data
        end

        # Resolve subject configuration from multiple sources
        # Priority: typed subject config > --pr flag > preset subject config
        # @param config [Hash] Preset configuration
        # @param subject [String, nil] Pre-extracted subject content (for --pr flag only)
        # @param session_dir [String] Session directory for saving intermediate files
        # @param options [ReviewOptions, nil] Review options
        # @param typed_subject_config [Hash, nil] Parsed typed subject (pr:, files:, diff:, task:)
        # @return [Hash, nil] Resolved subject configuration for ace-bundle
        def resolve_subject_config(config:, subject:, session_dir:, options:, typed_subject_config:)
          # Handle typed subject config (pr:, files:, diff:, task:) - pass directly to ace-bundle
          # This is the primary path - ace-bundle handles all content extraction
          if typed_subject_config
            return typed_subject_config
          end

          # Handle --pr flag (full PR mode with GhPrFetcher)
          if subject && !subject.empty? && options&.pr_review?
            pr_diff_path = File.join(session_dir, "pr-diff.patch")
            File.write(pr_diff_path, subject)

            return {
              "bundle" => {
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

          # Fallback to preset subject config
          config["subject"] || config[:subject]
        end

        def extract_subject(subject_config)
          return "" unless subject_config
          @subject_extractor.extract(subject_config)
        end

        def extract_context(context_config, cache_dir = nil)
          @context_extractor.extract(context_config, cache_dir)
        end

        def execute_with_llm(review_data, session_dir, options = nil)
          models = review_data[:models]

          # Detect single vs multi-model execution
          if models.size == 1
            # Single model execution (existing path)
            execute_single_model(review_data, session_dir, options, models.first)
          else
            # Multi-model execution (new path)
            execute_multi_model(review_data, session_dir, options, models)
          end
        end

        # Execute single model review (existing behavior)
        def execute_single_model(review_data, session_dir, options, model)
          executor = Ace::Review::Molecules::LlmExecutor.new

          # v0.13.0 architecture: only supports system/user prompt format
          result = executor.execute(
            system_prompt: review_data[:system_prompt],
            user_prompt: review_data[:user_prompt],
            model: model,
            session_dir: session_dir
          )

          if result[:success]
            # Save Ruby API metadata if available
            save_ruby_api_metadata(session_dir, result) if result[:metadata]

            # Copy final review to release folder
            release_path = copy_to_release(session_dir, review_data)

            # Handle PR comment posting if requested
            comment_result = handle_pr_comment_posting(options, result[:output_file], review_data)

            # Build response with comment info if applicable
            response = build_success_response(result, release_path, comment_result)

            # Extract feedback after successful single model review (if enabled)
            feedback_result = maybe_extract_single_model_feedback(
              result, session_dir, review_data, options, model
            )

            # Add feedback info to response if extraction succeeded
            if feedback_result && feedback_result[:success]
              response[:feedback_count] = feedback_result[:items_count]
              response[:feedback_paths] = feedback_result[:paths]
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

        # Execute multi-model review (new capability)
        def execute_multi_model(review_data, session_dir, options, models)
          require_relative '../molecules/multi_model_executor'
          executor = Ace::Review::Molecules::MultiModelExecutor.new

          # Execute all models concurrently
          result = executor.execute(
            models: models,
            system_prompt: review_data[:system_prompt],
            user_prompt: review_data[:user_prompt],
            session_dir: session_dir
          )

          if result[:success]
            # Save metadata for all models
            save_multi_model_metadata(session_dir, result)

            # For multi-model, we don't copy to a single release location
            # Each model has its own output file already in session_dir

            # Extract feedback (always runs if we have results)
            feedback_result = nil
            if should_extract_feedback?(result, options)
              feedback_result = extract_feedback(result, session_dir, review_data, options)
            end

            # Build multi-model success response
            build_multi_model_response(result, session_dir, feedback_result)
          else
            {
              success: false,
              error: "All models failed to execute"
            }
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
          # Subject and context are handled directly via ace-bundle workflow, no need for separate files

          # Save metadata (committable - no .tmp extension)
          metadata = create_metadata(review_data)
          File.write(File.join(session_dir, "metadata.yml"), YAML.dump(metadata))

          # Save PR comments as developer feedback report if available
          if review_data[:pr_comment_data]
            feedback_report = Ace::Review::Atoms::PrCommentFormatter.format(review_data[:pr_comment_data])
            if feedback_report && !feedback_report.empty?
              feedback_file = File.join(session_dir, "review-dev-feedback.md")
              File.write(feedback_file, feedback_report)
            end
          end
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
          compact_id = Ace::B36ts.encode(Time.now)

          # All reviews use the same naming pattern
          session_dir = File.join(cache_dir, "review-#{compact_id}")

          FileUtils.mkdir_p(session_dir)
          session_dir
        end

        def create_cache_directory
          # Create cache directory in .ace-local/review/sessions/ relative to project root
          # Use @project_root if set (e.g., in tests), otherwise use ProjectRootFinder
          root = @project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          base_cache_path = File.join(root, ".ace-local", "review", "sessions")
          FileUtils.mkdir_p(base_cache_path)
          base_cache_path
        end


        def copy_to_release(session_dir, review_data)
          # Copy final review reports to release folder
          release_base_path = @preset_manager.review_base_path
          FileUtils.mkdir_p(release_base_path)

          # Create output filename
          model_slug = Ace::Review::Atoms::SlugGenerator.generate(review_data[:model])
          compact_id = Ace::B36ts.encode(Time.now)
          release_filename = "review-report-#{model_slug}-#{compact_id}.md"
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
            "has_context" => !review_data[:context].to_s.empty?,
            "subject_size" => review_data[:subject]&.length || 0,
            "system_prompt_size" => review_data[:system_prompt]&.length || 0,
            "user_prompt_size" => review_data[:user_prompt]&.length || 0
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

        # Save metadata for multi-model execution
        def save_multi_model_metadata(session_dir, result)
          metadata_file = File.join(session_dir, "metadata.yml")
          models_metadata = result[:results].map do |model, model_result|
            {
              "name" => model,
              "status" => model_result[:success] ? "success" : "failed",
              "duration" => model_result[:duration],
              "output_file" => model_result[:output_file] ? File.basename(model_result[:output_file]) : nil,
              "error" => model_result[:error],
              "model_slug" => model_result[:model_slug]
            }
          end

          metadata_content = {
            "timestamp" => Time.now.iso8601,
            "models" => models_metadata,
            "summary" => result[:summary]
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

        # Handle PR comment posting workflow
        # @param options [ReviewOptions] Review options
        # @param review_file [String] Path to review file
        # @param review_data [Hash] Review metadata
        # @return [Hash, nil] Comment result or nil if no posting needed
        def handle_pr_comment_posting(options, review_file, review_data)
          return nil unless options && options.should_post_comment?
          post_pr_comment(options, review_file, review_data)
        end

        # Build success response with optional comment info
        # @param result [Hash] LLM execution result
        # @param release_path [String] Path to saved release file
        # @param comment_result [Hash, nil] Comment posting result
        # @return [Hash] Final response hash
        def build_success_response(result, release_path, comment_result)
          # Build result message
          messages = []
          messages << "Review saved to #{release_path}" if release_path
          messages << "Review saved to #{result[:output_file]}" if messages.empty?

          # Build base response
          response = {
            success: true,
            output_file: release_path || result[:output_file],
            message: messages.join("\n"),
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
        end

        # Determine if feedback extraction should be triggered
        # Feedback extraction always runs if we have successful results,
        # unless explicitly disabled via --no-feedback CLI flag.
        # @param result [Hash] multi-model execution result
        # @param options [ReviewOptions, nil] review options
        # @return [Boolean] true if feedback extraction should run
        def should_extract_feedback?(result, options)
          # Check if feedback is disabled via CLI flag (--no-feedback)
          return false if options&.no_feedback == true

          # Need at least 1 successful result
          success_count = result[:results].count { |_, r| r[:success] }
          success_count >= 1
        end

        # Extract feedback for single-model reviews
        # Wraps the single model result in the multi-model format and delegates to extract_feedback
        # @param result [Hash] LLM execution result (single model)
        # @param session_dir [String] session directory
        # @param review_data [Hash] review metadata
        # @param options [ReviewOptions, nil] review options
        # @param model [String] model name used for review
        # @return [Hash, nil] feedback extraction result or nil if disabled/failed
        def maybe_extract_single_model_feedback(result, session_dir, review_data, options, model)
          # Check if feedback is disabled via CLI flag (--no-feedback)
          return nil if options&.no_feedback == true

          # Build a result structure compatible with extract_feedback (multi-model format)
          single_model_result = {
            results: { model => { success: true, output_file: result[:output_file] } }
          }

          extract_feedback(single_model_result, session_dir, review_data, options)
        end

        # Extract feedback items from review reports and save them
        # @param result [Hash] multi-model execution result
        # @param session_dir [String] session directory
        # @param review_data [Hash] review metadata
        # @param options [ReviewOptions, nil] review options
        # @return [Hash, nil] feedback extraction result or nil on failure
        def extract_feedback(result, session_dir, review_data, options)
          require_relative 'feedback_manager'

          # Collect successful report paths
          report_paths = collect_report_paths(result, session_dir)

          return nil if report_paths.empty?

          # Determine feedback base path
          base_path = determine_feedback_path(review_data, session_dir)

          # Build ordered list of models to try: primary + fallbacks
          models_to_try = build_synthesis_model_list(options, review_data)

          feedback_manager = FeedbackManager.new
          last_error = nil

          models_to_try.each do |model|
            feedback_result = feedback_manager.extract_and_save(
              report_paths: report_paths,
              base_path: base_path,
              model: model,
              session_dir: File.join(session_dir, "feedback-synthesis")
            )

            if feedback_result[:success]
              feedback_result[:synthesis_model] = model
              return feedback_result
            end

            last_error = feedback_result[:error]
            warn "Feedback synthesis failed with #{model}: #{last_error}"
          end

          # All models failed
          { success: false, error: last_error, models_tried: models_to_try }
        rescue => e
          warn "Feedback extraction error: #{e.message}"
          { success: false, error: e.message }
        end

        # Build ordered list of synthesis models: primary + fallbacks
        # @param options [ReviewOptions, nil] review options
        # @param review_data [Hash] review metadata
        # @return [Array<String>] ordered list of models to try
        def build_synthesis_model_list(options, review_data)
          primary = options&.feedback_model ||
                    Ace::Review.get("feedback", "synthesis_model") ||
                    review_data[:model]

          fallbacks = Ace::Review.get("feedback", "fallback_models") || []

          [primary, *fallbacks].compact.uniq
        end

        # Collect report paths for feedback synthesis
        #
        # Collects all successful model reports for FeedbackSynthesizer processing.
        # The synthesizer produces deduplicated findings with reviewer arrays.
        #
        # @param result [Hash] multi-model execution result
        # @param session_dir [String] session directory
        # @return [Array<String>] list of report file paths
        def collect_report_paths(result, session_dir)
          report_paths = []

          # Add successful model reports
          result[:results].each do |_, model_result|
            if model_result[:success] && model_result[:output_file]
              report_paths << model_result[:output_file]
            end
          end

          # Add dev-feedback report if it exists (PR comments)
          dev_feedback_path = File.join(session_dir, "review-dev-feedback.md")
          report_paths << dev_feedback_path if File.exist?(dev_feedback_path)

          report_paths.compact.uniq
        end

        # Determine the base path for feedback storage
        #
        # With session-symlink architecture, feedback always lives in the session
        # directory. The session is symlinked into task/reviews/, making feedback
        # accessible via: task/reviews/{session_name}/feedback/
        #
        # @param review_data [Hash] review metadata (unused, kept for API compatibility)
        # @param session_dir [String] session directory
        # @return [String] session directory (feedback lives in session)
        def determine_feedback_path(review_data, session_dir)
          session_dir
        end

        # Build multi-model response with optional feedback info
        # @param result [Hash] multi-model execution result
        # @param session_dir [String] session directory
        # @param feedback_result [Hash, nil] feedback extraction result
        # @return [Hash] response hash
        def build_multi_model_response(result, session_dir, feedback_result = nil)
          successful_models = result[:results].select { |_, r| r[:success] }
          failed_models = result[:results].reject { |_, r| r[:success] }

          response = {
            success: true,
            session_dir: session_dir,
            summary: result[:summary],
            models: result[:results].keys,
            successful_models: successful_models.keys,
            failed_models: failed_models.keys
          }

          # Add output files
          output_files = successful_models.values.map { |r| r[:output_file] }.compact
          response[:output_files] = output_files

          # Add feedback info
          if feedback_result && feedback_result[:success]
            response[:feedback_count] = feedback_result[:items_count]
            response[:feedback_paths] = feedback_result[:paths]
          elsif feedback_result && !feedback_result[:success]
            response[:feedback_error] = feedback_result[:error]
          end

          response
        end
      end
    end
    end
  end
