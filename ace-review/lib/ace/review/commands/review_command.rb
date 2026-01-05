# frozen_string_literal: true

require "pathname"

module Ace
  module Review
    module Commands
      class ReviewCommand
        def initialize(args, options = {})
          @args = args
          @options = build_review_options(options)
        end

        def execute
          display_config_summary

          # Convert options hash to ReviewOptions object
          review_options = Models::ReviewOptions.new(@options)

          puts "Analyzing code with preset '#{review_options.preset}'..." if review_options.verbose

          manager = Organisms::ReviewManager.new
          result = manager.execute_review(review_options)

          if result[:success]
            handle_success(result, review_options)
          else
            handle_error(result)
          end
        rescue StandardError => e
          puts "✗ Error: #{e.message}"
          puts e.backtrace if @options[:verbose]
          1
        end

        private

        def build_review_options(cli_options)
          # Start with CLI options
          options = cli_options.dup

          # Handle repeatable options
          process_subjects(options)
          process_models(options)

          # Set defaults
          options[:save_session] = true unless options.key?(:save_session)

          options
        end

        def process_subjects(options)
          return unless options[:subject]

          # Thor's repeatable option gives us an array
          subjects = Array(options[:subject]).compact.map(&:strip).reject(&:empty?)

          if subjects.any?
            # Deduplicate subjects (order preserved)
            subjects.uniq!
            # Single value: pass as-is, Multiple: pass as array
            options[:subject] = subjects.size == 1 ? subjects.first : subjects
          else
            options.delete(:subject)
          end
        end

        def process_models(options)
          return unless options[:model]

          # Thor's repeatable option gives us an array
          models = Array(options[:model]).compact.map(&:strip).reject(&:empty?)

          if models.any?
            # Also split comma-separated values
            models = models.flat_map { |m| m.split(",").map(&:strip).reject(&:empty?) }
            # Deduplicate and validate
            models.uniq!
            validate_model_names(models)
            options[:model] = models
          else
            options.delete(:model)
          end
        end

        def validate_model_names(models)
          models.each do |model|
            unless model.match?(/\A[a-zA-Z0-9\-_:.]+\z/)
              raise ArgumentError, "Invalid model name '#{model}'. Model names can only contain alphanumeric characters, hyphens, underscores, colons, and dots."
            end
          end
        end

        def handle_success(result, review_options)
          # Handle multi-model results
          if result[:summary]
            handle_multi_model_success(result)
            return 0
          end

          # Display review saved/prepared message
          if result[:output_file]
            puts "✓ Review saved: #{result[:output_file]}"
          elsif result[:session_dir]
            puts "✓ Review session prepared: #{result[:session_dir]}"

            # Display prompt files for ace-context workflow
            if result[:system_prompt_file] && result[:user_prompt_file]
              puts "  System prompt: #{result[:system_prompt_file]}"
              puts "  User prompt: #{result[:user_prompt_file]}"

              unless @options[:dry_run]
                puts
                puts "To execute with LLM:"
                puts "  ace-llm query --file #{result[:user_prompt_file]} --context #{result[:system_prompt_file]}"
              end
            elsif result[:prompt_file]
              puts "  Prompt: #{result[:prompt_file]}"
              unless @options[:dry_run]
                puts
                puts "To execute with LLM:"
                puts "  ace-llm query --file #{result[:prompt_file]}"
              end
            end
          end

          # Display comment posting results
          if result[:comment_url]
            puts "✓ Review posted to PR: #{result[:comment_url]}"
          elsif result[:comment_error]
            puts "✗ Failed to post comment: #{result[:comment_error]}"
            puts "  (Review saved locally - you can post manually)"
          end

          # Display dry-run preview
          if result[:dry_run_preview]
            puts
            puts "=== Comment Preview (Dry Run) ==="
            puts result[:dry_run_preview]
            puts "=== End Preview ==="
          end

          0
        end

        def handle_multi_model_success(result)
          puts
          puts "Reviews saved (#{result[:summary][:success_count]} of #{result[:summary][:total_models]} succeeded):"
          puts "  Session directory: #{result[:session_dir]}"
          puts

          if result[:output_files]&.any?
            result[:output_files].each do |file|
              puts "  ✓ #{File.basename(file)}"
            end
          end

          if result[:failed_models]&.any?
            puts
            puts "Failed models:"
            result[:failed_models].each do |model|
              puts "  ✗ #{model}"
            end
          end

          if result[:task_paths]&.any?
            puts
            puts "Saved to task directory:"
            first_path = result[:task_paths].first
            task_dir = File.dirname(first_path)
            relative_dir = Pathname.new(task_dir).relative_path_from(Dir.pwd).to_s
            puts "  #{relative_dir}/"
            result[:task_paths].each do |path|
              puts "  ✓ #{File.basename(path)}"
            end
          end

          puts
          puts "Total duration: #{result[:summary][:total_duration]}s"

          0
        end

        def handle_error(result)
          puts "✗ Error: #{result[:error]}"
          1
        end

        def display_config_summary
          return if @options[:quiet]

          require "ace/core"
          Ace::Core::Atoms::ConfigSummary.display(
            command: "review",
            config: Ace::Review.config,
            defaults: load_defaults,
            options: @options,
            quiet: false
          )
        end

        def load_defaults
          gem_root = Gem.loaded_specs["ace-review"]&.gem_dir ||
                     File.expand_path("../../../../../..", __dir__)
          defaults_path = File.join(gem_root, ".ace-defaults", "review", "config.yml")

          if File.exist?(defaults_path)
            require "yaml"
            YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
          else
            {}
          end
        end
      end
    end
  end
end
