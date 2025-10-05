# frozen_string_literal: true

require "optparse"

module Ace
  module Review
    # CLI interface for ace-review
    class CLI
      def initialize
        @options = {
          preset: "pr",
          save_session: true
        }
      end

      def run(argv)
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

          opts.on("--preset NAME", "Review preset from configuration (default: pr)") do |v|
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

          opts.on("--model MODEL", "LLM model to use") do |v|
            @options[:model] = v
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

          opts.on("-h", "--help", "Show this help") do
            @options[:help] = true
          end
        end

        @parser.parse!(argv)
      end

      def show_help
        puts @parser
        puts
        puts "Examples:"
        puts "  ace-review --preset pr"
        puts "  ace-review --preset security --auto-execute"
        puts "  ace-review --preset docs --output-dir ./reviews"
        puts "  ace-review --list-presets"
        puts "  ace-review --list-prompts"
      end

      def list_presets
        manager = Ace::Review::Organisms::ReviewManager.new

        presets = manager.list_presets
        if presets.empty?
          puts "No presets found"
          puts "Create presets in .ace/review/code.yml or .ace/review/presets/"
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
        if result[:output_file]
          puts "✓ Review saved: #{result[:output_file]}"
        elsif result[:session_dir]
          puts "✓ Review session prepared: #{result[:session_dir]}"
          puts "  Prompt: #{result[:prompt_file]}"
          unless @options[:dry_run]
            puts
            puts "To execute with LLM:"
            puts "  ace-llm query --file #{result[:prompt_file]}"
          end
        end
      end

      def handle_error(result)
        puts "✗ Error: #{result[:error]}"
        exit 1
      end
    end
  end
end