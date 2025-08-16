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

        argument :input, type: :string, required: false,
          desc: "Input file path or inline YAML (auto-detects format: .yml/.yaml/.ag.md/.md or inline YAML)"

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
          "templates/project-essentials.yaml",
          ".claude/agents/task-manager.ag.md",
          "'files: [docs/*.md]'",
          "templates/project.yaml --format xml",
          ".claude/agents/git-commit.ag.md --format yaml",
          "docs/context/project.md",
          "--preset project",
          "--preset project --output custom/output.md",
          "--list-presets"
        ]

        def call(input: nil, **options)
          begin
            # Handle list presets request
            if options[:list_presets]
              return handle_list_presets(options)
            end

            # Handle preset-based loading
            if options[:preset]
              return handle_preset_loading(options)
            end

            # Require input or preset
            unless input || options[:preset]
              raise ArgumentError, "Must specify input file/string or use --preset"
            end

            # Handle input with auto-detection
            if input
              return handle_auto_detection_loading(input, options)
            end

            # Should not reach here as preset is handled above
            raise ArgumentError, "No valid input provided"
          rescue => e
            handle_error(e, options[:debug])
            1
          end
        end

        private


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
          
          # Load context from template using auto-detection
          context_loader = CodingAgentTools::Organisms::ContextLoader.new(options)
          context_result = context_loader.load_with_auto_detection(preset[:template], options)

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

        def handle_auto_detection_loading(input, options)
          # Initialize the context loader organism
          context_loader = CodingAgentTools::Organisms::ContextLoader.new(options)

          # Load context with auto-detection and optional embedding
          context_result = context_loader.load_with_auto_detection(input, options)

          unless context_result[:success]
            warn "Error loading context: #{context_result[:error]}"
            return 1
          end

          # Handle output based on embedding result
          if context_result[:embedding_applied]
            # Output the embedded document
            puts context_result[:embedded_content]
            
            if options[:debug]
              warn "Context embedded using strategy: #{context_result[:embedding_strategy]}"
            end
          else
            # Format and output the standard result
            formatter = CodingAgentTools::Molecules::Context::OutputFormatter.new(options[:format])
            formatted_output = formatter.format(context_result)
            puts formatted_output
            
            if context_result[:embedding_error] && options[:debug]
              warn "Embedding failed: #{context_result[:embedding_error]}"
            end
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