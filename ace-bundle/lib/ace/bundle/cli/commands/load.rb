# frozen_string_literal: true

require "fileutils"
require "ace/support/fs"
require_relative "../../atoms/line_counter"
require_relative "../../atoms/preset_list_formatter"

module Ace
  module Bundle
    module CLI
      module Commands
        # ace-support-cli Command class for the load command
        #
        # Loads context from preset, file, or protocol URL
        class Load < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Load context from preset, file, or protocol URL

            INPUT can be:
            - Preset name (e.g., 'project', 'base')
            - File path (e.g., '/path/to/config.yml', './context.md')
            - Protocol URL (e.g., 'wfi://workflow', 'guide://testing')

            Configuration:
              Global config:  ~/.ace/bundle/config.yml
              Project config: .ace/bundle/config.yml
              Example:        ace-bundle/.ace-defaults/bundle/config.yml

              Presets defined in: .ace/bundle/presets/

            Output:
              By default, output saved to cache and file path printed
              Use --output stdio to print to stdout
              Exit codes: 0 (success), 1 (error)

            Protocols:
              wfi://     Workflow instructions
              guide://  Development guides
              prompt:// Prompt templates
              tmpl://   General templates
          DESC

          example [
            "project                  # Load project preset",
            "wfi://work-on-task       # Load workflow via protocol",
            "-p base -p custom        # Merge multiple presets",
            "-f config.yml            # Load from file",
            "--inspect-config         # Show resolved configuration"
          ]

          # Define positional argument
          argument :input, required: false, desc: "Preset name, file path, or protocol URL"

          # Preset options
          option :preset, type: :array, aliases: %w[-p], desc: "Load context from preset (can be used multiple times)"
          option :presets, type: :string, desc: "Load multiple presets (comma-separated list)"

          # File options
          option :file, type: :array, aliases: %w[-f], desc: "Load context from file (can be used multiple times)"

          # Config options
          option :inspect_config, type: :boolean, desc: "Show merged configuration without loading files"

          # Output options
          option :embed_source, type: :boolean, aliases: %w[-e], desc: "Embed source document in output"
          option :output, type: :string, aliases: %w[-o], desc: "Output mode: stdio, cache, or file path"
          option :format, type: :string, desc: "Output format (markdown, yaml, xml, markdown-xml, json)"

          # Compression
          option :compressor, type: :string, default: nil,
            desc: "Enable/disable compression: on, off"
          option :compressor_mode, type: :string, default: nil,
            desc: "Compressor engine: exact, agent (default: exact)"
          option :compressor_source_scope, type: :string, default: nil,
            desc: "Source handling: off, per-source, merged (default: off)"

          # Resource limits
          option :max_size, type: :integer, desc: "Maximum file size in bytes"
          option :timeout, type: :integer, desc: "Command timeout in seconds"

          # Standard options (inherited from Base but need explicit definition for ace-support-cli)
          option :version, type: :boolean, desc: "Show version information"
          option :list_presets, type: :boolean, desc: "List available context presets"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(input: nil, **options)
            # Handle --help/-h passed as input argument
            if input == "--help" || input == "-h"
              # ace-support-cli will handle this
              return
            end

            if options[:version]
              puts "ace-bundle #{Ace::Bundle::VERSION}"
              return
            end

            if options[:list_presets]
              presets = Ace::Bundle.list_presets
              Atoms::PresetListFormatter.format(presets).each { |line| puts line }
              return
            end

            # Type-convert numeric options using Base helper for proper validation
            # coerce_types uses Integer() which raises ArgumentError on invalid input
            # (unlike .to_i which silently returns 0)
            coerce_types(options, max_size: :integer, timeout: :integer)

            # Handle repeatable options (type: :array returns array, single values need wrapping)
            # --preset returns array when used multiple times, nil otherwise
            if options[:preset] && options[:presets]
              # If both --preset and --presets provided, merge them
              presets = [options[:preset]].flatten + options[:presets].split(",")
              options[:preset] = presets.map(&:strip)
            elsif options[:presets]
              options[:preset] = options[:presets].split(",").map(&:strip)
            elsif options[:preset]
              # Ensure array even for single value
              options[:preset] = [options[:preset]].flatten
            end

            # Same for file option
            options[:file] = [options[:file]].flatten if options[:file]

            # Normalize --compressor toggle
            if options.key?(:compressor) && options[:compressor]
              val = options[:compressor].to_s.downcase
              options[:compressor] = case val
              when "true", "yes", "on", "1" then "on"
              when "false", "no", "off", "0" then "off"
              else val
              end
            end

            # Normalize compressor_source_scope option
            if options.key?(:compressor_source_scope) && options[:compressor_source_scope]
              val = options[:compressor_source_scope].to_s.downcase
              options[:compressor_source_scope] = case val
              when "true", "yes", "on", "" then "per-source"
              when "false", "no", "off" then "off"
              else val
              end
            end

            execute(input, options)
          end

          private

          def execute(input, options)
            display_config_summary(options)
            # Process repeatable options and extract mutable values
            presets, files = process_options(options)

            # Determine input source and load context
            result = if options[:inspect_config]
              inspect_config_mode(presets, files, input, options)
            elsif @multi_input_mode
              load_multiple_inputs(presets, files, options)
            elsif input
              load_auto(input, options)
            else
              load_auto("default", options)
            end

            # Handle errors
            if result[:context].metadata[:error]
              msg = result[:context].metadata[:error]
              if result[:context].metadata[:errors] && options[:debug]
                msg = "#{msg}\n#{result[:context].metadata[:errors].join("\n")}"
              end
              raise Ace::Support::Cli::Error.new(msg)
            end

            # Handle output
            handle_output(result[:context], result[:input], options)
          end

          def process_options(options)
            # Extract preset options (already normalized in call method)
            presets = Array(options[:preset] || []).compact

            # Extract file options
            files = Array(options[:file] || []).compact

            # Determine if we're in multi-input mode
            @multi_input_mode = presets.any? || files.any?

            [presets, files]
          end

          def inspect_config_mode(presets, files, input, options)
            inputs = []
            inputs.concat(presets) if presets.any?
            inputs.concat(files) if files.any?
            inputs << input if input && inputs.empty?
            inputs << "default" if inputs.empty?

            context = Ace::Bundle.inspect_config(inputs, options)
            {context: context, input: inputs.join("-")}
          end

          def load_multiple_inputs(presets, files, options)
            context = Ace::Bundle.load_multiple_inputs(presets, files, options)

            # Create input string for cache filename
            all_inputs = presets + files.map { |f| File.basename(f, ".*") }
            input = all_inputs.join("-")

            {context: context, input: input}
          end

          def load_auto(input, options)
            context = Ace::Bundle.load_auto(input, options)
            {context: context, input: input}
          end

          def handle_output(context, input, options)
            # Determine output mode
            # Priority: CLI flag > preset metadata > auto-format based on line count
            explicit_output = options[:output] || context.metadata[:output]

            if explicit_output
              # Explicit output mode specified - honor it
              output_mode = explicit_output
            else
              # Auto-format: decide based on line count vs threshold
              size_key = :raw_content_for_auto_format
              size_source = context.metadata[size_key] ||
                context.metadata[size_key.to_s] ||
                context.content
              line_count = Atoms::LineCounter.count(size_source)
              threshold = Ace::Bundle.auto_format_threshold

              output_mode = (line_count >= threshold) ? "cache" : "stdio"
            end

            # Handle output based on mode
            case output_mode
            when "stdio"
              puts context.content
            when "cache"
              write_to_cache(context, input, options)
            else
              write_to_file(context, output_mode, options)
            end
          end

          def write_to_cache(context, input, options)
            project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
            configured_cache_dir = Ace::Bundle.cache_dir
            cache_dir = if configured_cache_dir.start_with?("/")
              configured_cache_dir
            else
              File.join(project_root, configured_cache_dir)
            end
            FileUtils.mkdir_p(cache_dir)

            # Generate cache filename from input (preset name, protocol, or sanitized file path)
            cache_name = input.gsub(/[^a-zA-Z0-9-]/, "_")
            cache_file = File.join(cache_dir, "#{cache_name}.md")
            result = Ace::Bundle.write_output(context, cache_file, options)

            if result[:success]
              if result[:chunked]
                chunks = result[:results].select { |r| r[:file_type] == "chunk" }
                total_lines = chunks.sum { |r| r[:lines] || 0 }
                total_size = chunks.sum { |r| r[:size] || 0 }
                puts "Bundle saved (#{total_lines} lines, #{format_size(total_size)}) in #{chunks.size} chunks:"
                chunks.each { |r| puts r[:path] }
              else
                puts "Bundle saved (#{result[:lines]} lines, #{result[:size_formatted]}), output file:"
                puts cache_file
              end
            else
              raise Ace::Support::Cli::Error.new("Error writing cache: #{result[:error]}")
            end
          end

          def write_to_file(context, file_path, options)
            output_dir = File.dirname(file_path)
            FileUtils.mkdir_p(output_dir) unless output_dir == "."

            result = Ace::Bundle.write_output(context, file_path, options)

            if result[:success]
              if result[:chunked]
                chunks = result[:results].select { |r| r[:file_type] == "chunk" }
                total_lines = chunks.sum { |r| r[:lines] || 0 }
                total_size = chunks.sum { |r| r[:size] || 0 }
                puts "Bundle saved (#{total_lines} lines, #{format_size(total_size)}) in #{chunks.size} chunks:"
                chunks.each { |r| puts r[:path] }
              else
                puts "Bundle saved (#{result[:lines]} lines, #{result[:size_formatted]}), output file:"
                puts file_path
              end
            else
              raise Ace::Support::Cli::Error.new("Error writing file: #{result[:error]}")
            end
          end

          def format_size(bytes)
            units = ["B", "KB", "MB", "GB"]
            size = bytes.to_f
            unit_index = 0
            while size >= 1024 && unit_index < units.size - 1
              size /= 1024
              unit_index += 1
            end
            "#{size.round(2)} #{units[unit_index]}"
          end

          def display_config_summary(options)
            return if options[:quiet]

            require "ace/core"
            Ace::Core::Atoms::ConfigSummary.display(
              command: "load",
              config: Ace::Bundle.config,
              defaults: load_gem_defaults,
              options: options,
              quiet: false
            )
          end

          def load_gem_defaults
            gem_root = Gem.loaded_specs["ace-bundle"]&.gem_dir ||
              File.expand_path("../../../../..", __dir__)
            defaults_path = File.join(gem_root, ".ace-defaults", "bundle", "config.yml")

            if File.exist?(defaults_path)
              require "yaml"
              data = YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
              data["bundle"] || data
            else
              {}
            end
          end
        end
      end
    end
  end
end
