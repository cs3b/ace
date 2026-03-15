# frozen_string_literal: true

require "pathname"

module Ace
  module Review
    module CLI
      module Commands
      # ace-support-cli Command class for the review command
      #
      # Executes code review using presets or custom configuration.
      class Review < Ace::Support::Cli::Command
        include Ace::Core::CLI::Base

        desc <<~DESC.strip
          Execute code review using presets or custom configuration

          Presets provide pre-configured review types with focused prompts:
            code         → General code review
            code-pr      → PR-focused code review
            security     → Security-focused review
            performance  → Performance-focused review
            docs         → Documentation review

          Configuration:
            Global config:  ~/.ace/review/config.yml
            Project config: .ace/review/config.yml
            Example:        ace-review/.ace-defaults/review/config.yml

          Presets configured via review.presets
        DESC

        example [
          '--preset code-pr             # PR code review',
          '--preset security --auto-execute  # Run and apply fixes',
          '--pr 123                      # Review by PR number',
          '--preset code --subject diff:HEAD~3 --subject files:docs/**/*.md',
          '--preset security --dry-run   # Preview without executing'
        ]

        # Review configuration options
        option :preset, type: :string, desc: "Review preset from configuration"
        option :output_dir, type: :string, desc: "Custom output directory for review"
        option :output, type: :string, desc: "Specific output file path"
        option :context, type: :string, desc: "Context configuration (preset name or YAML)"
        option :subject, type: :array, desc: "Subject configuration (can be specified multiple times)"
        option :prompt_base, type: :string, desc: "Base prompt module"
        option :prompt_format, type: :string, desc: "Format module"
        option :prompt_focus, type: :string, desc: "Focus modules (comma-separated)"
        option :add_focus, type: :string, desc: "Add focus modules to preset"
        option :prompt_guidelines, type: :string, desc: "Guideline modules (comma-separated)"
        option :model, type: :array, desc: "LLM model(s) to use (can be specified multiple times)"
        option :no_feedback, type: :boolean, desc: "Skip feedback extraction from review reports"
        option :feedback_model, type: :string, desc: "Model to use for feedback extraction"
        option :dry_run, type: :boolean, desc: "Prepare review without executing"
        option :auto_execute, type: :boolean, desc: "Execute LLM query automatically"
        option :save_session, type: :boolean, desc: "Save session files (default: true)"
        option :session_dir, type: :string, desc: "Custom session directory"
        option :task, type: :string, desc: "Save review report to task directory (task number, task.NNN, or v.X.Y.Z+NNN)"
        option :no_auto_save, type: :boolean, desc: "Disable auto-save even if enabled in config"
        option :pr, type: :string, desc: "Review GitHub PR (number, URL, or owner/repo#number)"
        option :pr_comments, type: :boolean, desc: "Include PR comments as feedback source (default: true for --pr)"
        option :post_comment, type: :boolean, desc: "Post review as PR comment (requires --pr)"
        option :gh_timeout, type: :integer, desc: "Timeout for gh CLI operations in seconds (default: 30)"

        # Standard options
        option :version, type: :boolean, desc: "Show version information"
        option :list_presets, type: :boolean, desc: "List available review presets"
        option :list_prompts, type: :boolean, desc: "List available prompt modules"
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

        attr_reader :options

        def call(**cli_options)
          # Remove ace-support-cli specific keys (args is leftover arguments)
          cli_options = cli_options.reject { |k, _| k == :args }

          if cli_options[:version]
            puts "ace-review #{Ace::Review::VERSION}"
            return
          end

          if cli_options[:list_presets]
            show_list_presets
            return
          end

          if cli_options[:list_prompts]
            show_list_prompts
            return
          end

          # Type-convert numeric options (ace-support-cli returns strings, Thor converted to integers)
          cli_options[:gh_timeout] = cli_options[:gh_timeout]&.to_i if cli_options[:gh_timeout]

          # Build and store options for testing compatibility
          @options = build_review_options(cli_options)

          execute_review
        end

        private

        def execute_review
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
          raise Ace::Core::CLI::Error.new(e.message)
        end

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

          # Handle both array input (from tests/API) and string input (from CLI)
          # CLI uses ARRAY_SEPARATOR (\x1F) to preserve internal commas in subjects
          subjects = Array(options[:subject]).flat_map do |s|
            s.to_s.split(CLI::ARRAY_SEPARATOR)
          end.compact.map(&:strip).reject(&:empty?)

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

          # ace-support-cli's array option gives us an array
          models = Array(options[:model]).compact.map(&:strip).reject(&:empty?)

          if models.any?
            # Also split comma-separated values
            models = models.flat_map { |m| m.split(",").map(&:strip).reject(&:empty?) }
            # Deduplicate and validate
            models.uniq!
            validate_model_names(models)
            # Store in :models (array) not :model (expects string)
            options[:models] = models
            options.delete(:model)
          else
            options.delete(:model)
          end
        end

        def validate_model_names(models)
          models.each do |model|
            unless model.match?(/\A[a-zA-Z0-9\-_:.@]+\z/)
              raise ArgumentError, "Invalid model name '#{model}'. Model names can only contain alphanumeric characters, hyphens, underscores, colons, and dots."
            end
          end
        end

        def handle_success(result, review_options)
          # Handle multi-model results
          if result[:summary]
            handle_multi_model_success(result)
            return
          end

          # Display review saved/prepared message
          if result[:output_file]
            puts "✓ Review saved: #{result[:output_file]}"
          elsif result[:session_dir]
            puts "✓ Review session prepared: #{result[:session_dir]}"

            # Display prompt files for ace-bundle workflow
            if result[:system_prompt_file] && result[:user_prompt_file]
              puts "  System prompt: #{result[:system_prompt_file]}"
              puts "  User prompt: #{result[:user_prompt_file]}"

              unless @options[:dry_run]
                puts
                puts "To execute with LLM:"
                puts "  ace-llm --file #{result[:user_prompt_file]} --context #{result[:system_prompt_file]}"
              end
            elsif result[:prompt_file]
              puts "  Prompt: #{result[:prompt_file]}"
              unless @options[:dry_run]
                puts
                puts "To execute with LLM:"
                puts "  ace-llm --file #{result[:prompt_file]}"
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

          if result[:feedback_count]
            puts
            puts "Feedback: #{result[:feedback_count]} items extracted"
          elsif result[:feedback_error]
            puts
            puts "Feedback extraction failed: #{result[:feedback_error]}"
          end
        end

        def handle_error(result)
          raise Ace::Core::CLI::Error.new(result[:error])
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

        def show_list_presets
          manager = Organisms::ReviewManager.new

          presets = manager.list_presets
          if presets.empty?
            puts "No presets found"
            puts "Create presets in .ace/review/config.yml or .ace/review/presets/"
            return
          end

          puts "Available Review Presets:"
          puts

          # Header
          puts format("%-20s %-50s %-10s", "Preset", "Description", "Source")
          puts "-" * 80

          # Load preset manager to get descriptions
          preset_manager = Molecules::PresetManager.new

          presets.each do |name|
            preset = preset_manager.load_preset(name)
            description = preset&.dig("description") || "-"

            # Determine source
            source = if preset_manager.send(:load_preset_from_file, name)
                       "file"
                     elsif preset_manager.send(:load_preset_from_config, name)
                       "config"
                     else
                       "default"
                     end

            puts format("%-20s %-50s %-10s", name, description, source)
          end
        end

        def show_list_prompts
          manager = Organisms::ReviewManager.new

          prompts = manager.list_prompts
          if prompts.empty?
            puts "No prompt modules found"
            return
          end

          puts "Available Prompt Modules:"
          puts

          prompts.each do |category, items|
            puts "  #{category}/"
            format_prompt_items(items, "    ")
          end
        end

        def format_prompt_items(items, indent)
          case items
          when Hash
            items.each do |name, value|
              if value.is_a?(Array)
                puts "#{indent}#{name}/"
                value.each do |item|
                  source = item.is_a?(Hash) ? " (#{item[:source]})" : ""
                  item_name = item.is_a?(Hash) ? item[:name] : item
                  puts "#{indent}  #{item_name}#{source}"
                end
              else
                source = value.is_a?(String) ? " (#{value})" : ""
                puts "#{indent}#{name}#{source}"
              end
            end
          when Array
            items.each { |item| puts "#{indent}#{item}" }
          when String
            puts "#{indent}#{items}"
          end
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
end
