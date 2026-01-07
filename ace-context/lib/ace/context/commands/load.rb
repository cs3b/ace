# frozen_string_literal: true

require_relative "load_command"

module Ace
  module Context
    module Commands
      # dry-cli Command class for the load command
      #
      # This wraps the existing LoadCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Load < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Load context from preset, file, or protocol URL

          INPUT can be:
          - Preset name (e.g., 'project', 'base')
          - File path (e.g., '/path/to/config.yml', './context.md')
          - Protocol URL (e.g., 'wfi://workflow', 'guide://testing')

          Configuration:
            Global config:  ~/.ace/context/config.yml
            Project config: .ace/context/config.yml
            Example:        ace-context/.ace-defaults/context/config.yml

            Presets defined in: .ace/context/presets/

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
          'project                  # Load project preset',
          'wfi://work-on-task       # Load workflow via protocol',
          '-p base -p custom        # Merge multiple presets',
          '--presets base,team      # Load multiple presets (comma-separated)',
          '-f config.yml            # Load from file',
          '--embed-source           # Embed source document in output',
          '--list                   # List available presets'
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

        # Resource limits
        option :max_size, type: :integer, desc: "Maximum file size in bytes"
        option :timeout, type: :integer, desc: "Command timeout in seconds"

        # Standard options (inherited from Base but need explicit definition for dry-cli)
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(input: nil, **options)
          # Handle --help/-h passed as input argument
          if input == "--help" || input == "-h"
            # dry-cli will handle this, but we need to return success
            return 0
          end

          # Type-convert numeric options (dry-cli returns strings, Thor converted to integers)
          numeric_options = %i[max_size timeout]
          numeric_options.each do |key|
            options[key] = options[key].to_i if options[key]
          end

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

          command = LoadCommand.new(input, options)
          command.execute
        end
      end
    end
  end
end
