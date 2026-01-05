# frozen_string_literal: true

require "ace/core/cli/base"

module Ace
  module Context
    class CLI < Ace::Core::CLI::Base
      # class_options :quiet, :verbose, :debug inherited from Base

      default_task :load

      # Override help to add protocol routing section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Protocol URL Routing:"
        shell.say "  Protocol URLs are auto-routed to 'load' command - no need to type 'load':"
        shell.say "    ace-context wfi://workflow     → ace-context load wfi://workflow"
        shell.say "    ace-context guide://testing    → ace-context load guide://testing"
        shell.say "  Supported protocols: wfi://, guide://, prompt://, tmpl://"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-context project                  # Load project preset"
        shell.say "  ace-context wfi://work-on-task       # Load workflow via protocol"
        shell.say "  ace-context -p base -p custom        # Merge multiple presets"
      end

      desc "load [INPUT]", "Load context from preset, file, or protocol URL"
      long_desc <<~DESC
        Load project context from various sources.

        SYNTAX:
          ace-context [INPUT] [OPTIONS]
          ace-context load [INPUT] [OPTIONS]

        INPUT can be:
        - Preset name (e.g., 'project', 'base')
        - File path (e.g., '/path/to/config.yml', './context.md')
        - Protocol URL (e.g., 'wfi://workflow', 'guide://testing')

        EXAMPLES:

          # Load default preset
          $ ace-context

          # Load project preset
          $ ace-context project

          # Load configuration file
          $ ace-context /path/to/config.yml

          # Load markdown with frontmatter
          $ ace-context ./context.md

          # Load via protocol URL
          $ ace-context wfi://create-task

          # Load and merge multiple presets
          $ ace-context -p base -p custom

          # Load multiple presets (comma-separated)
          $ ace-context --presets base,team

          # Explicitly load from file
          $ ace-context -f config.yml

          # Embed source document in output
          $ ace-context wfi://workflow --embed-source

          # List available presets
          $ ace-context --list

        CONFIGURATION:

          Global config:  ~/.ace/context/config.yml
          Project config: .ace/context/config.yml
          Example:        ace-context/.ace-defaults/context/config.yml

          Presets defined in: .ace/context/presets/

        OUTPUT:

          By default, output saved to cache and file path printed
          Use --output stdio to print to stdout
          Exit codes: 0 (success), 1 (error)

        PROTOCOLS:

          wfi://     Workflow instructions
          guide://  Development guides
          prompt:// Prompt templates
          tmpl://   General templates
      DESC
      option :preset, type: :string, aliases: "-p", repeatable: true, desc: "Load context from preset (can be used multiple times)"
      option :presets, type: :string, desc: "Load multiple presets (comma-separated list)"
      option :file, type: :string, aliases: "-f", repeatable: true, desc: "Load context from file (can be used multiple times)"
      option :inspect_config, type: :boolean, desc: "Show merged configuration without loading files"
      option :embed_source, type: :boolean, aliases: "-e", desc: "Embed source document in output"
      option :output, type: :string, aliases: "-o", desc: "Output mode: stdio, cache, or file path"
      option :format, type: :string, desc: "Output format (markdown, yaml, xml, markdown-xml, json)"
      option :max_size, type: :numeric, desc: "Maximum file size in bytes"
      option :timeout, type: :numeric, desc: "Command timeout in seconds"
      def load(input = nil)
        # Handle --help/-h passed as input argument
        if input == "--help" || input == "-h"
          invoke :help, ["load"]
          return 0
        end
        require_relative "commands/load_command"
        Commands::LoadCommand.new(input, options).execute
      end

      desc "list", "List available context presets"
      long_desc <<~DESC
        List all available context presets found in .ace/context/presets/.

        EXAMPLES:

          # List all presets
          $ ace-context list
          $ ace-context --list

        OUTPUT:

          Table format with columns: name, description, output mode, source file
          Exit codes: 0 (success), 1 (error)
      DESC
      map %w[--list --list-presets] => :list
      def list
        require_relative "commands/list_command"
        Commands::ListCommand.new.execute
      end

      desc "version", "Show version"
      long_desc <<~DESC
        Display the current version of ace-context.

        EXAMPLES:

          $ ace-context version
          $ ace-context --version
      DESC
      def version
        puts "ace-context #{Ace::Context::VERSION}"
        0
      end
      map "--version" => :version

      # Intercept start to add 'load' command for unknown commands
      # This preserves backward compatibility for:
      #   ace-context <preset-name>  ->  ace-context load <preset-name>
      def self.start(given_args = ARGV, config = {})
        # If first arg is not a known command and not an option, insert 'load'
        if given_args.first && !given_args.first.start_with?("-")
          known_commands = %w[load list version help]
          unless known_commands.include?(given_args.first)
            given_args = ["load"] + given_args
          end
        end

        super(given_args, config)
      end

      # Handle unknown commands as arguments to the default 'load' command
      def method_missing(command, *args)
        invoke :load, [command.to_s] + args
      end
      # respond_to_missing? inherited from Ace::Core::CLI::Base
    end
  end
end
