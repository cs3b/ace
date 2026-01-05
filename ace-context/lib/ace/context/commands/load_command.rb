# frozen_string_literal: true

require "fileutils"
require "ace/support/fs"
require_relative "../atoms/line_counter"

module Ace
  module Context
    module Commands
      class LoadCommand
        def initialize(input, options = {})
          @input = input
          @options = options
        end

        def execute
          display_config_summary
          # Process repeatable options and extract mutable values
          presets, files = process_options

          # Determine input source and load context
          if @options[:inspect_config]
            result = inspect_config_mode(presets, files)
          elsif @multi_input_mode
            result = load_multiple_inputs(presets, files)
          elsif @input
            result = load_auto(@input)
          else
            result = load_auto("default")
          end

          # Handle errors
          if result[:context].metadata[:error]
            $stderr.puts "Error: #{result[:context].metadata[:error]}"
            if result[:context].metadata[:errors] && @options[:debug]
              $stderr.puts result[:context].metadata[:errors].join("\n")
            end
            return 1
          end

          # Handle output
          handle_output(result[:context], result[:input])
        end

        private

        def process_options
          # Extract and process preset options (Thor options are frozen)
          presets = Array(@options[:preset] || []).compact

          # Process --presets comma-separated option
          if @options[:presets]
            additional_presets = @options[:presets].split(",").map(&:strip).compact
            presets.concat(additional_presets)
          end

          # Extract and process file options
          files = Array(@options[:file] || []).compact

          # Determine if we're in multi-input mode
          @multi_input_mode = presets.any? || files.any?

          [presets, files]
        end

        def inspect_config_mode(presets, files)
          inputs = []
          inputs.concat(presets) if presets.any?
          inputs.concat(files) if files.any?
          inputs << @input if @input && inputs.empty?
          inputs << "default" if inputs.empty?

          context = Ace::Context.inspect_config(inputs, @options)
          { context: context, input: inputs.join("-") }
        end

        def load_multiple_inputs(presets, files)
          context = Ace::Context.load_multiple_inputs(presets, files, @options)

          # Create input string for cache filename
          all_inputs = presets + files.map { |f| File.basename(f, ".*") }
          input = all_inputs.join("-")

          { context: context, input: input }
        end

        def load_auto(input)
          context = Ace::Context.load_auto(input, @options)
          { context: context, input: input }
        end

        def handle_output(context, input)
          # Determine output mode
          # Priority: CLI flag > preset metadata > auto-format based on line count
          explicit_output = @options[:output] || context.metadata[:output]

          if explicit_output
            # Explicit output mode specified - honor it
            output_mode = explicit_output
          else
            # Auto-format: decide based on line count vs threshold
            line_count = Atoms::LineCounter.count(context.content)
            threshold = Ace::Context.auto_format_threshold

            output_mode = line_count >= threshold ? "cache" : "stdio"
          end

          # Handle output based on mode
          case output_mode
          when "stdio"
            # Output to stdout
            puts context.content
            0
          when "cache"
            # Save to cache directory
            write_to_cache(context, input)
          else
            # Save to specified file path
            write_to_file(context, output_mode)
          end
        end

        def write_to_cache(context, input)
          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          cache_dir = File.join(project_root, ".cache/ace-context")
          FileUtils.mkdir_p(cache_dir)

          # Generate cache filename from input (preset name, protocol, or sanitized file path)
          cache_name = input.gsub(/[^a-zA-Z0-9-]/, "_")
          cache_file = File.join(cache_dir, "#{cache_name}.md")
          result = Ace::Context.write_output(context, cache_file, @options)

          if result[:success]
            puts "Context saved (#{result[:lines]} lines, #{result[:size_formatted]}), output file:"
            puts cache_file
            0
          else
            $stderr.puts "Error writing cache: #{result[:error]}"
            1
          end
        end

        def write_to_file(context, file_path)
          output_dir = File.dirname(file_path)
          FileUtils.mkdir_p(output_dir) unless output_dir == "."

          result = Ace::Context.write_output(context, file_path, @options)

          if result[:success]
            puts "Context saved (#{result[:lines]} lines, #{result[:size_formatted]}), output file:"
            puts file_path
            0
          else
            $stderr.puts "Error writing file: #{result[:error]}"
            1
          end
        end

        def display_config_summary
          return if @options[:quiet]

          require "ace/core"
          Ace::Core::Atoms::ConfigSummary.display(
            command: "load",
            config: Ace::Context.config,
            defaults: load_gem_defaults,
            options: @options,
            quiet: false
          )
        end

        def load_gem_defaults
          gem_root = Gem.loaded_specs["ace-context"]&.gem_dir ||
                     File.expand_path("../../../../..", __dir__)
          defaults_path = File.join(gem_root, ".ace-defaults", "context", "config.yml")

          if File.exist?(defaults_path)
            require "yaml"
            data = YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
            data["context"] || data
          else
            {}
          end
        end
      end
    end
  end
end
