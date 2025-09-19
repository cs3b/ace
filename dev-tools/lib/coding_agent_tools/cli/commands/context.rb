# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/context_loader"
require_relative "../../molecules/context/output_formatter"
require_relative "../../molecules/context/context_preset_manager"
require_relative "../../molecules/context/context_file_writer"
require_relative "../../molecules/context/context_chunker"
require_relative "../../molecules/context/merger"

module CodingAgentTools
  module Cli
    module Commands
      # Context command for loading and formatting project context
      class Context < Dry::CLI::Command
        desc "Load project context from templates with multi-format output"

        argument :inputs, type: :array, required: false, default: [],
          desc: "Input file paths or inline YAML (multiple allowed, auto-detects format)"

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

        def call(inputs: [], **options)
          # Handle list presets request
          if options[:list_presets]
            return handle_list_presets(options)
          end

          # Parse preset names if provided
          preset_names = parse_preset_names(options[:preset])

          # Validation
          if inputs.empty? && preset_names.empty?
            raise ArgumentError, "Must specify input files or use --preset"
          end

          # Route to appropriate handler
          if preset_names.any?
            if preset_names.size == 1
              # Single preset - existing behavior
              handle_preset_loading(options)
            else
              # Multiple presets - new behavior
              handle_multiple_presets(preset_names, options)
            end
          elsif inputs.any?
            if inputs.size == 1
              # Single input - existing behavior
              handle_auto_detection_loading(inputs.first, options)
            else
              # Multiple inputs - new behavior
              handle_multiple_inputs(inputs, options)
            end
          end
        rescue => e
          handle_error(e, options[:debug])
          1
        end

        private

        # Parse preset names from command option
        #
        # @param preset_option [String, nil] Preset option from command line
        # @return [Array<String>] Array of preset names
        def parse_preset_names(preset_option)
          return [] unless preset_option
          preset_option.split(",").map(&:strip)
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

          # Check if output should go to stdout
          output_to_stdout = output_path && (output_path == "-" || output_path.downcase == "stdout")

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
          if output_to_stdout || !output_path
            # Output to stdout
            puts formatted_output
          else
            # Write to file with chunking if needed
            file_writer = CodingAgentTools::Molecules::Context::ContextFileWriter.new
            chunker = CodingAgentTools::Molecules::Context::ContextChunker.new(preset[:chunk_limit])

            # Create progress callback
            progress_callback = ->(message) { puts message } if options[:debug]

            # Determine base path (remove extension)
            base_path = output_path.sub(/\.[^.]+$/, "")

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

          # Prepare the output content
          if context_result[:embedding_applied]
            # Use the embedded document content
            output_content = context_result[:embedded_content]

            if options[:debug]
              warn "Context embedded using strategy: #{context_result[:embedding_strategy]}"
            end
          else
            # Format the standard result
            formatter = CodingAgentTools::Molecules::Context::OutputFormatter.new(options[:format])
            output_content = formatter.format(context_result)

            if context_result[:embedding_error] && options[:debug]
              warn "Embedding failed: #{context_result[:embedding_error]}"
            end
          end

          # Determine output destination
          output_path = options[:output]
          output_to_stdout = !output_path || is_stdout_indicator?(output_path)

          if output_to_stdout
            # Output to stdout
            puts output_content
          else
            # Write to file
            write_to_file(output_path, output_content, options)
          end

          0
        rescue => e
          handle_error(e, options[:debug])
          1
        end

        def handle_multiple_presets(preset_names, options)
          preset_manager = CodingAgentTools::Molecules::Context::ContextPresetManager.new
          context_loader = CodingAgentTools::Organisms::ContextLoader.new(options)
          merger = CodingAgentTools::Molecules::Context::Merger.new

          # Load all presets
          presets = []
          contexts = []

          preset_names.each do |preset_name|
            preset = preset_manager.resolve_preset(preset_name)
            unless preset
              warn "Preset '#{preset_name}' not found, skipping"
              next
            end

            presets << preset
            result = context_loader.load_with_auto_detection(preset[:template], options)

            unless result[:success]
              warn "Error loading preset '#{preset_name}': #{result[:error]}"
              next
            end

            result[:preset_name] = preset_name
            result[:preset_info] = preset
            contexts << result
          end

          # Check if we have any valid contexts
          if contexts.empty?
            warn "No valid contexts loaded from presets"
            return 1
          end

          # Merge contexts
          merged_context = merger.merge_contexts(contexts)

          # Format output
          formatter = CodingAgentTools::Molecules::Context::OutputFormatter.new(options[:format])
          formatted_output = formatter.format(merged_context)

          # Determine output destination
          output_path = determine_output_path(options, presets, merger)
          output_to_stdout = !output_path || is_stdout_indicator?(output_path)

          if output_to_stdout
            puts formatted_output
          else
            # Use maximum chunk limit from all presets
            max_chunk_limit = presets.map { |p| p[:chunk_limit] }.compact.max || 150000
            write_with_chunking(output_path, formatted_output, max_chunk_limit, options)
          end

          0
        rescue => e
          handle_error(e, options[:debug])
          1
        end

        def handle_multiple_inputs(inputs, options)
          context_loader = CodingAgentTools::Organisms::ContextLoader.new(options)
          merger = CodingAgentTools::Molecules::Context::Merger.new

          # Load contexts from all inputs
          contexts = inputs.map do |input|
            result = context_loader.load_with_auto_detection(input, options)
            unless result[:success]
              warn "Error loading #{input}: #{result[:error]}"
              next nil
            end
            result[:source_input] = input
            result
          end.compact

          # Check if we have any valid contexts
          if contexts.empty?
            warn "No valid contexts loaded from inputs"
            return 1
          end

          # Merge contexts
          merged_context = merger.merge_contexts(contexts)

          # Format output
          formatter = CodingAgentTools::Molecules::Context::OutputFormatter.new(options[:format])
          formatted_output = formatter.format(merged_context)

          # Determine output destination (default to stdout for multiple inputs)
          output_path = options[:output]
          output_to_stdout = !output_path || is_stdout_indicator?(output_path)

          if output_to_stdout
            puts formatted_output
          else
            # No chunking for direct input files
            write_to_file(output_path, formatted_output, options)
          end

          0
        rescue => e
          handle_error(e, options[:debug])
          1
        end

        def determine_output_path(options, presets, merger)
          # Command-line flag has highest priority
          return options[:output] if options[:output]

          # Use merger to resolve output path from presets
          merger.resolve_output_path(presets, nil)
        end

        def write_with_chunking(output_path, formatted_output, chunk_limit, options)
          file_writer = CodingAgentTools::Molecules::Context::ContextFileWriter.new
          chunker = CodingAgentTools::Molecules::Context::ContextChunker.new(chunk_limit)

          # Create progress callback
          progress_callback = ->(message) { puts message } if options[:debug]

          # Determine base path (remove extension)
          base_path = output_path.sub(/\.[^.]+$/, "")

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

          0
        end

        def write_to_file(output_path, content, options)
          File.write(output_path, content)
          lines = content.lines.count
          size = content.bytesize
          size_formatted = format_size(size)

          puts "Context saved (#{lines} lines, #{size_formatted})"
          puts "Output file: #{output_path}"
        rescue => e
          warn "Error writing file: #{e.message}"
          1
        end

        def format_size(bytes)
          if bytes < 1024
            "#{bytes} bytes"
          elsif bytes < 1024 * 1024
            "#{(bytes / 1024.0).round(1)} KB"
          else
            "#{(bytes / (1024.0 * 1024)).round(1)} MB"
          end
        end

        # Check if a path indicates stdout output
        #
        # @param path [String] Path to check
        # @return [Boolean] true if path indicates stdout
        def is_stdout_indicator?(path)
          path && (path == "-" || path.downcase == "stdout")
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
