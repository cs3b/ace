# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/context_loader"
require_relative "../../molecules/context/output_formatter"

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
          "--yaml templates/project-essentials.yaml",
          "--from-agent .claude/agents/task-manager.md",
          "--yaml-string 'files: [docs/*.md]'",
          "--yaml templates/project.yaml --format xml",
          "--from-agent .claude/agents/git-commit.md --format yaml"
        ]

        def call(**options)
          begin
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
          input_count = [options[:yaml], options[:from_agent], options[:yaml_string]].compact.size

          if input_count == 0
            raise ArgumentError, "Must specify one input method: --yaml, --from-agent, or --yaml-string"
          elsif input_count > 1
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