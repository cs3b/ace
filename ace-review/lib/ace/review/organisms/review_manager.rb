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
          session_dir = create_session_directory(options)

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
          context = extract_context(context_config)

          {
            success: true,
            subject: subject,
            context: context
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
            model: options.effective_model(config[:model])
          }
        end

        def extract_subject(subject_config)
          return "" unless subject_config
          @subject_extractor.extract(subject_config)
        end

        def extract_context(context_config)
          @context_extractor.extract(context_config)
        end

        def execute_with_llm(review_data, session_dir)
          executor = Ace::Review::Molecules::LlmExecutor.new

          result = executor.execute(
            prompt: review_data[:prompt],
            model: review_data[:model],
            session_dir: session_dir
          )

          if result[:success]
            # LlmExecutor now saves directly to output_file
            # Just return the result with output_file path
            {
              success: true,
              output_file: result[:output_file],
              message: "Review saved to #{result[:output_file]}"
            }
          else
            result
          end
        end

        def save_session_files(session_dir, review_data)
          # Save prompt (temporary - with .tmp extension)
          File.write(File.join(session_dir, "prompt.md.tmp"), review_data[:prompt])

          # Save subject (temporary - with .tmp extension)
          File.write(File.join(session_dir, "subject.md.tmp"), review_data[:subject])

          # Save context if present (temporary - with .tmp extension)
          unless review_data[:context].empty?
            File.write(File.join(session_dir, "context.md.tmp"), review_data[:context])
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

        def create_session_directory(options)
          if options.session_dir
            FileUtils.mkdir_p(options.session_dir)
            return options.session_dir
          end

          # Use reviews folder from preset manager
          base_path = @preset_manager.review_base_path
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          session_dir = File.join(base_path, "review-#{timestamp}")
          FileUtils.mkdir_p(session_dir)
          session_dir
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