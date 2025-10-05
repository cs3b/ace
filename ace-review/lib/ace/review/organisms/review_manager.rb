# frozen_string_literal: true

require "fileutils"
require "time"

module Ace
  module Review
    module Organisms
      # Main orchestrator for code review workflow
      class ReviewManager
        attr_reader :preset_manager, :prompt_resolver, :prompt_composer,
                    :subject_extractor, :context_extractor

        def initialize
          @preset_manager = Molecules::PresetManager.new
          @prompt_resolver = Molecules::PromptResolver.new
          @prompt_composer = Molecules::PromptComposer.new(@prompt_resolver)
          @subject_extractor = Molecules::SubjectExtractor.new
          @context_extractor = Molecules::ContextExtractor.new
        end

        # Execute a code review with the given options
        # @param options [Hash] review options
        # @return [Hash] review results
        def execute_review(options)
          # Resolve preset if specified
          preset_config = resolve_preset(options)
          return preset_config unless preset_config[:success]

          config = preset_config[:config]

          # Extract subject (what to review)
          subject = extract_subject(config[:subject] || options[:subject])
          return { success: false, error: "No code to review" } if subject.empty?

          # Extract context (background info)
          context = extract_context(config[:context] || options[:context])

          # Build complete prompt
          prompt = build_prompt(config, context, subject)

          # Prepare review data
          review_data = {
            preset: options[:preset],
            config: config,
            subject: subject,
            context: context,
            prompt: prompt,
            model: config[:model]
          }

          # Execute with LLM if requested
          if options[:auto_execute]
            execute_with_llm(review_data, options)
          else
            prepare_session(review_data, options)
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

        def resolve_preset(options)
          preset_name = options[:preset] || "pr"

          unless @preset_manager.preset_exists?(preset_name)
            available = @preset_manager.available_presets.join(", ")
            return {
              success: false,
              error: "Preset '#{preset_name}' not found. Available: #{available}"
            }
          end

          config = @preset_manager.resolve_preset(preset_name, options)
          { success: true, config: config }
        end

        def extract_subject(subject_config)
          return "" unless subject_config
          @subject_extractor.extract(subject_config)
        end

        def extract_context(context_config)
          @context_extractor.extract(context_config)
        end

        def build_prompt(config, context, subject)
          @prompt_composer.build_review_prompt(
            config[:prompt_composition],
            context,
            subject,
            config_dir: File.dirname(@preset_manager.config_path || ".")
          )
        end

        def execute_with_llm(review_data, options)
          require_relative "../molecules/llm_executor"
          executor = Molecules::LlmExecutor.new

          result = executor.execute(
            prompt: review_data[:prompt],
            model: review_data[:model]
          )

          if result[:success]
            save_review(result[:response], review_data, options)
          else
            result
          end
        end

        def prepare_session(review_data, options)
          session_dir = create_session_directory(options)

          # Save prompt
          prompt_file = File.join(session_dir, "prompt.md")
          File.write(prompt_file, review_data[:prompt])

          # Save subject
          subject_file = File.join(session_dir, "subject.md")
          File.write(subject_file, review_data[:subject])

          # Save context if present
          unless review_data[:context].empty?
            context_file = File.join(session_dir, "context.md")
            File.write(context_file, review_data[:context])
          end

          # Save metadata
          metadata_file = File.join(session_dir, "metadata.yml")
          File.write(metadata_file, YAML.dump(create_metadata(review_data)))

          {
            success: true,
            session_dir: session_dir,
            prompt_file: prompt_file,
            message: "Review session prepared in #{session_dir}"
          }
        end

        def save_review(response, review_data, options)
          output_file = determine_output_file(options)
          ensure_output_directory(output_file)

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
          if options[:session_dir]
            FileUtils.mkdir_p(options[:session_dir])
            return options[:session_dir]
          end

          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          session_dir = File.join(
            Dir.pwd,
            ".ace-review-sessions",
            "review-#{timestamp}"
          )
          FileUtils.mkdir_p(session_dir)
          session_dir
        end

        def determine_output_file(options)
          if options[:output]
            return options[:output]
          end

          # Use storage config
          base_path = @preset_manager.review_base_path
          FileUtils.mkdir_p(base_path)

          timestamp = Time.now.strftime("%Y-%m-%d-%H%M%S")
          File.join(base_path, "review-#{timestamp}.md")
        end

        def ensure_output_directory(file_path)
          dir = File.dirname(file_path)
          FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
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