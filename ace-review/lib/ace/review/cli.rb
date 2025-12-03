# frozen_string_literal: true

require "optparse"

module Ace
  module Review
    # CLI interface for ace-review
    class CLI
      def initialize
        @options = {
          save_session: true
        }
      end

      def run(argv)
        # Check for subcommand
        if argv.first && !argv.first.start_with?("-")
          subcommand = argv.shift
          case subcommand
          when "synthesize"
            run_synthesize(argv)
            return
          else
            # Not a recognized subcommand, put it back
            argv.unshift(subcommand)
          end
        end

        parse_options(argv)

        # Handle list commands
        if @options[:list_presets]
          list_presets
          return
        elsif @options[:list_prompts]
          list_prompts
          return
        elsif @options[:help]
          show_help
          return
        end

        # Execute review
        execute_review
      rescue StandardError => e
        puts "✗ Error: #{e.message}"
        puts e.backtrace if @options[:verbose]
        exit 1
      end

      private

      def parse_options(argv)
        @parser = OptionParser.new do |opts|
          opts.banner = "Usage: ace-review [options]"
          opts.separator ""
          opts.separator "Execute review using presets or custom configuration"
          opts.separator ""
          opts.separator "Options:"

          opts.on("--preset NAME", "Review preset from configuration (or set defaults.preset in config)") do |v|
            @options[:preset] = v
          end

          opts.on("--output-dir DIR", "Custom output directory for review") do |v|
            @options[:output_dir] = v
          end

          opts.on("--output FILE", "Specific output file path") do |v|
            @options[:output] = v
          end

          opts.on("--context CONFIG", "Context configuration (preset name or YAML)") do |v|
            @options[:context] = v
          end

          opts.on("--subject CONFIG", "Subject configuration (git range or YAML)") do |v|
            @options[:subject] = v
          end

          opts.on("--prompt-base MODULE", "Base prompt module") do |v|
            @options[:prompt_base] = v
          end

          opts.on("--prompt-format MODULE", "Format module") do |v|
            @options[:prompt_format] = v
          end

          opts.on("--prompt-focus MODULES", "Focus modules (comma-separated)") do |v|
            @options[:prompt_focus] = v
          end

          opts.on("--add-focus MODULES", "Add focus modules to preset") do |v|
            @options[:add_focus] = v
          end

          opts.on("--prompt-guidelines MODULES", "Guideline modules (comma-separated)") do |v|
            @options[:prompt_guidelines] = v
          end

          opts.on("--model MODELS", "LLM model(s) to use (comma-separated or multiple flags)") do |v|
            # Initialize models array if not present
            @options[:models] ||= []
            # Split comma-separated values, strip whitespace, and filter blanks
            @options[:models].concat(v.split(",").map(&:strip).reject(&:empty?))
          end

          opts.on("--no-synthesize", "Skip synthesis for multi-model reviews") do
            @options[:no_synthesize] = true
          end

          opts.on("--synthesis-model MODEL", "Model to use for synthesis (default: gemini-2.5-flash)") do |v|
            @options[:synthesis_model] = v
          end

          opts.on("--list-presets", "List available presets") do
            @options[:list_presets] = true
          end

          opts.on("--list-prompts", "List available prompt modules") do
            @options[:list_prompts] = true
          end

          opts.on("--dry-run", "Prepare review without executing") do
            @options[:dry_run] = true
          end

          opts.on("-v", "--verbose", "Verbose output") do
            @options[:verbose] = true
          end

          opts.on("--auto-execute", "Execute LLM query automatically") do
            @options[:auto_execute] = true
          end

          opts.on("--[no-]save-session", "Save session files (default: true)") do |v|
            @options[:save_session] = v
          end

          opts.on("--session-dir DIR", "Custom session directory") do |v|
            @options[:session_dir] = v
          end

          opts.on("--task TASKREF", "Save review report to task directory (task number, task.NNN, or v.X.Y.Z+NNN)") do |v|
            @options[:task] = v
          end

          opts.on("--no-auto-save", "Disable auto-save even if enabled in config") do
            @options[:no_auto_save] = true
          end

          opts.on("--pr IDENTIFIER", "Review GitHub PR (number, URL, or owner/repo#number)") do |v|
            @options[:pr] = v
          end

          opts.on("--post-comment", "Post review as PR comment (requires --pr)") do
            @options[:post_comment] = true
          end

          opts.on("--gh-timeout SECONDS", Integer, "Timeout for gh CLI operations in seconds (default: 30)") do |v|
            @options[:gh_timeout] = v
          end

          opts.on("-h", "--help", "Show this help") do
            @options[:help] = true
          end
        end

        @parser.parse!(argv)

        # Deduplicate and validate models if present
        if @options[:models]
          @options[:models].uniq!
          validate_model_names(@options[:models])
        end
      end

      # Validate model names contain only expected characters
      # @param models [Array<String>] model names to validate
      # @raise [ArgumentError] if model name contains invalid characters
      def validate_model_names(models)
        models.each do |model|
          unless model.match?(/\A[a-zA-Z0-9\-_:.]+\z/)
            raise ArgumentError, "Invalid model name '#{model}'. Model names can only contain alphanumeric characters, hyphens, underscores, colons, and dots."
          end
        end
      end

      def show_help
        puts @parser
        puts
        puts "Examples:"
        puts "  ace-review --preset code-pr"
        puts "  ace-review --preset security --auto-execute"
        puts "  ace-review --preset docs --output-dir ./reviews"
        puts "  ace-review --preset code-pr --task 114"
        puts "  ace-review --preset security --task 114 --auto-execute"
        puts "  ace-review --pr 123 --auto-execute"
        puts "  ace-review --pr https://github.com/owner/repo/pull/456 --preset security"
        puts "  ace-review --pr owner/repo#789 --post-comment --auto-execute"
        puts
        puts "Multi-model examples:"
        puts "  ace-review --preset code-pr --model \"gemini,gpt-4,claude\" --auto-execute"
        puts "  ace-review --preset code-pr --model gemini --model gpt-4 --auto-execute"
        puts "  ace-review --preset security --model \"google:gemini-2.5-flash,openai:gpt-4\" --auto-execute"
        puts "  ace-review --preset code-pr --model \"gemini,gpt-4\" --no-synthesize --auto-execute"
        puts
        puts "Synthesis examples:"
        puts "  ace-review synthesize --session .cache/ace-review/sessions/review-20251201-143022/"
        puts "  ace-review synthesize --session ./session --synthesis-model gpt-4"
        puts "  ace-review synthesize --reports report1.md report2.md --output synthesis.md"
        puts
        puts "List commands:"
        puts "  ace-review --list-presets"
        puts "  ace-review --list-prompts"
      end

      def list_presets
        manager = Ace::Review::Organisms::ReviewManager.new

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
        preset_manager = Ace::Review::Molecules::PresetManager.new

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

      def list_prompts
        manager = Ace::Review::Organisms::ReviewManager.new

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

      def execute_review
        # Convert hash to ReviewOptions object
        options = Ace::Review::Models::ReviewOptions.new(@options)

        puts "Analyzing code with preset '#{options.preset}'..." if options.verbose

        manager = Ace::Review::Organisms::ReviewManager.new
        result = manager.execute_review(options)

        if result[:success]
          handle_success(result)
        else
          handle_error(result)
        end
      end

      def handle_success(result)
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
            # Legacy format for backward compatibility
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
          # Extract common directory from first path and make it relative
          first_path = result[:task_paths].first
          task_dir = File.dirname(first_path)
          relative_dir = task_dir.sub("#{Dir.pwd}/", "")
          puts "  #{relative_dir}/"
          result[:task_paths].each do |path|
            puts "  ✓ #{File.basename(path)}"
          end
        end

        puts
        puts "Total duration: #{result[:summary][:total_duration]}s"
      end

      def handle_error(result)
        puts "✗ Error: #{result[:error]}"
        exit 1
      end

      # Run synthesis subcommand
      def run_synthesize(argv)
        options = {}

        parser = OptionParser.new do |opts|
          opts.banner = "Usage: ace-review synthesize [options]"
          opts.separator ""
          opts.separator "Synthesize multiple review reports into a consolidated report"
          opts.separator ""
          opts.separator "Options:"

          opts.on("--session DIR", "Session directory containing review reports") do |v|
            options[:session_dir] = v
          end

          opts.on("--reports FILES", Array, "Explicit report files to synthesize (comma-separated)") do |v|
            options[:report_files] = v
          end

          opts.on("--synthesis-model MODEL", "Model to use for synthesis") do |v|
            options[:synthesis_model] = v
          end

          opts.on("--output FILE", "Output file path (default: synthesis-report.md)") do |v|
            options[:output] = v
          end

          opts.on("-v", "--verbose", "Verbose output") do
            options[:verbose] = true
          end

          opts.on("-h", "--help", "Show this help") do
            puts opts
            exit
          end
        end

        parser.parse!(argv)

        # Validate inputs
        if options[:session_dir].nil? && options[:report_files].nil?
          puts "✗ Error: Either --session or --reports is required"
          puts
          puts parser
          exit 1
        end

        # Determine report paths
        report_paths = if options[:report_files]
                        options[:report_files]
                      else
                        # Find all review-*.md files in session directory
                        session_dir = options[:session_dir]
                        unless Dir.exist?(session_dir)
                          puts "✗ Error: Session directory not found: #{session_dir}"
                          exit 1
                        end
                        Dir.glob(File.join(session_dir, "review-*.md"))
                      end

        # Determine session directory for output
        session_dir = if options[:session_dir]
                       options[:session_dir]
                     elsif options[:report_files] && options[:report_files].any?
                       File.dirname(options[:report_files].first)
                     else
                       Dir.pwd
                     end

        # Execute synthesis
        require_relative "molecules/report_synthesizer"
        synthesizer = Ace::Review::Molecules::ReportSynthesizer.new

        result = synthesizer.synthesize(
          report_paths: report_paths,
          model: options[:synthesis_model],
          session_dir: session_dir,
          output_file: options[:output]
        )

        if result[:success]
          # Success message already displayed by synthesizer
          exit 0
        else
          puts "✗ Synthesis failed: #{result[:error]}"
          puts result[:backtrace].join("\n") if options[:verbose] && result[:backtrace]
          exit 1
        end
      rescue StandardError => e
        puts "✗ Error: #{e.message}"
        puts e.backtrace if options[:verbose]
        exit 1
      end
    end
  end
end