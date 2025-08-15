# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/context_loader"
require_relative "../../molecules/context/output_formatter"
require_relative "../../molecules/context/context_preset_manager"
require_relative "../../molecules/context/context_file_writer"
require_relative "../../molecules/context/context_chunker"

module CodingAgentTools
  module Cli
    module Commands
      # Context command for loading and formatting project context
      class Context < Dry::CLI::Command
        desc "Load project context from templates with multi-format output"

        option :yaml, type: :string, aliases: ["y"],
          desc: "YAML template file path"

        option :from_agent, type: :string, aliases: ["a"],
          desc: "Agent markdown file to extract context from"

        option :yaml_string, type: :string, aliases: ["s"],
          desc: "Inline YAML template string"

        option :preset, type: :string, aliases: ["p"],
          desc: "Load configuration from preset name"

        option :list_presets, type: :boolean, default: false, aliases: ["l"],
          desc: "List available presets and exit"

        option :output, type: :string, aliases: ["o"],
          desc: "Output file path (overrides preset output)"

        option :format, type: :string, values: ["xml", "yaml", "markdown-xml"],
          default: "markdown-xml", aliases: ["f"],
          desc: "Output format: xml, yaml, or markdown-xml (default)"

        option :max_size, type: :integer, default: 1048576,
          desc: "Maximum file size in bytes (default: 1MB)"

        option :timeout, type: :integer, default: 30,
          desc: "Command timeout in seconds (default: 30)"

        option :debug, type: :boolean, default: false, aliases: ["d"],
          desc: "Enable debug output"

        example [
          "--preset project",
          "--preset project --output custom/output.md",
          "--list-presets",
          "--yaml templates/project-essentials.yaml",
          "--from-agent .claude/agents/task-manager.md",
          "--yaml-string 'files: [docs/*.md]'",
          "--yaml templates/project.yaml --format xml",
          "--from-agent .claude/agents/git-commit.md --format yaml"
        ]

        def call(**options)
          begin
            # Handle list presets request
            if options[:list_presets]
              return handle_list_presets(options)
            end

            # Handle preset-based loading
            if options[:preset]
              return handle_preset_loading(options)
            end

            # Handle traditional template loading
            # Validate input options
            validate_input_options(options)

            # Initialize the context loader organism
            context_loader = CodingAgentTools::Organisms::ContextLoader.new(options)

            # Load context based on input type
            template_data = parse_input(options)
            context_result = context_loader.load_from_template(template_data, options)

            # Format and output the result
            formatter = CodingAgentTools::Molecules::Context::OutputFormatter.new(options[:format])
            formatted_output = formatter.format(context_result)

            puts formatted_output
            0
          rescue => e
            handle_error(e, options[:debug])
            1
          end
        end

        private

        def validate_input_options(options)
          input_methods = [options[:yaml], options[:from_agent], options[:yaml_string], options[:preset]].compact
          
          if input_methods.empty?
            raise ArgumentError, "Must specify one input method: --yaml, --from-agent, --yaml-string, or --preset"
          elsif input_methods.size > 1
            raise ArgumentError, "Can only specify one input method at a time"
          end

          # Validate file existence for file-based inputs
          if options[:yaml] && !File.exist?(options[:yaml])
            raise ArgumentError, "YAML template file not found: #{options[:yaml]}"
          end

          if options[:from_agent] && !File.exist?(options[:from_agent])
            raise ArgumentError, "Agent file not found: #{options[:from_agent]}"
          end
        end

        def parse_input(options)
          if options[:yaml]
            {type: :yaml_file, source: options[:yaml]}
          elsif options[:from_agent]
            {type: :agent_file, source: options[:from_agent]}
          elsif options[:yaml_string]
            {type: :yaml_string, source: options[:yaml_string]}
          else
            raise ArgumentError, "No valid input source provided"
          end
        end

        def handle_list_presets(options)
          preset_manager = CodingAgentTools::Molecules::Context::ContextPresetManager.new
          presets = preset_manager.list_presets

          puts "Available presets:"
          puts
          
          if presets.empty?
            puts "  No presets configured in .coding-agent/context.yml"
            puts "  See documentation for preset configuration examples."
          else
            presets.each do |preset|
              puts "  #{preset[:name]}"
              puts "    Description: #{preset[:description]}"
              puts "    Template:    #{preset[:template]}"
              puts "    Output:      #{preset[:output]}"
              puts "    Chunk limit: #{preset[:chunk_limit]} lines"
              puts
            end
          end

          0
        rescue => e
          handle_error(e, options[:debug])
          1
        end

        def handle_preset_loading(options)
          preset_manager = CodingAgentTools::Molecules::Context::ContextPresetManager.new
          
          # Resolve preset configuration
          preset = preset_manager.resolve_preset(options[:preset])
          unless preset
            warn "Error: Preset '#{options[:preset]}' not found"
            warn "Use --list-presets to see available presets"
            return 1
          end

          # Override output path if specified
          output_path = options[:output] || preset[:output]
          
          # Load context from template
          context_loader = CodingAgentTools::Organisms::ContextLoader.new(options)
          template_data = { type: :yaml_file, source: preset[:template] }
          context_result = context_loader.load_from_template(template_data, options)

          unless context_result[:success]
            warn "Error loading context: #{context_result[:error]}"
            return 1
          end

          # Format content
          formatter = CodingAgentTools::Molecules::Context::OutputFormatter.new(options[:format])
          formatted_output = formatter.format(context_result)

          # Handle output
          if output_path
            # Write to file with chunking if needed
            file_writer = CodingAgentTools::Molecules::Context::ContextFileWriter.new
            chunker = CodingAgentTools::Molecules::Context::ContextChunker.new(preset[:chunk_limit])
            
            # Create progress callback
            progress_callback = ->(message) { puts message } if options[:debug]
            
            # Determine base path (remove extension)
            base_path = output_path.sub(/\.[^.]+$/, '')
            
            # Chunk and write
            write_result = chunker.chunk_and_write(
              formatted_output,
              base_path,
              file_writer,
              progress_callback: progress_callback
            )

            if write_result[:chunked]
              puts "Context saved (#{write_result[:total_chunks]} chunks, #{write_result[:files_written]} files)"
              puts "Index file: #{base_path}.md"
            else
              result = write_result[:results].first
              if result[:success]
                puts "Context saved (#{result[:lines]} lines, #{result[:size_formatted]})"
                puts "Output file: #{result[:path]}"
              else
                warn "Error writing file: #{result[:error]}"
                return 1
              end
            end
          else
            # Output to stdout
            puts formatted_output
          end

          0
        rescue => e
          handle_error(e, options[:debug])
          1
        end

        def handle_error(error, debug_enabled)
          if debug_enabled
            warn "Error: #{error.class.name}: #{error.message}"
            warn "\nBacktrace:"
            error.backtrace.each { |line| warn "  #{line}" }
          else
            warn "Error: #{error.message}"
            warn "Use --debug flag for more information"
          end
        end
      end
    end
  end
end