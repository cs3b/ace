# frozen_string_literal: true

require "ace/core/cli/base"
require_relative "../search"
# Atoms
require_relative "atoms/search_path_resolver"
require_relative "atoms/debug_logger"
require_relative "atoms/tool_checker"
require_relative "atoms/ripgrep_executor"
require_relative "atoms/fd_executor"
require_relative "atoms/result_parser"
require_relative "atoms/pattern_analyzer"
# Molecules
require_relative "molecules/fzf_integrator"
require_relative "molecules/preset_manager"
require_relative "molecules/time_filter"
require_relative "molecules/dwim_analyzer"
# Organisms
require_relative "organisms/unified_searcher"
require_relative "organisms/result_formatter"

module Ace
  module Search
    class CLI < Ace::Core::CLI::Base
      # class_options :quiet, :verbose, :debug inherited from Base

      default_task :search

      # Override help to add search type detection section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Search Type Detection:"
        shell.say "  Patterns are auto-detected as file or content searches:"
        shell.say "    *.rb, **/*.js       -> file search (glob patterns)"
        shell.say "    TODO, class.*       -> content search (regex)"
        shell.say "  Use --files or --content to override auto-detection"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-search TODO                      # Content search"
        shell.say "  ace-search '*.rb'                    # File search"
        shell.say "  ace-search pattern --staged          # Git-scoped"
      end

      desc "search PATTERN [SEARCH_PATH]", "Search across the codebase"
      long_desc <<~DESC
        Search across the codebase with intelligent pattern matching.

        SYNTAX:
          ace-search [PATTERN] [SEARCH_PATH] [OPTIONS]
          ace-search search [PATTERN] [SEARCH_PATH] [OPTIONS]

        Positional arguments:
          PATTERN     Search pattern (regex for content, glob for files)
          SEARCH_PATH Optional path to search in (defaults to current directory)

        EXAMPLES:

          # Auto-detect search type (default)
          $ ace-search "TODO"                    # Auto-detect: search content
          $ ace-search "*.rb"                    # Auto-detect: search files

          # Explicit search type
          $ ace-search "*.rb" --file             # Search for Ruby files
          $ ace-search "class.*Manager" --content # Search in file content

          # Case insensitive
          $ ace-search "todo" -i

          # With context
          $ ace-search "TODO" -C 3

          # File filtering
          $ ace-search "pattern" --glob "**/*.rb"

          # Git scope
          $ ace-search "pattern" --staged        # Search staged files only
          $ ace-search "pattern" --tracked       # Search tracked files only

          # Output format
          $ ace-search "pattern" --files-with-matches

          # Use preset
          $ ace-search "TODO" --preset daily-scan

        CONFIGURATION:

          Global config:  ~/.ace/search/config.yml
          Project config: .ace/search/config.yml
          Example:        ace-search/.ace-defaults/search/config.yml

          Search presets configured via search.presets

        OUTPUT:

          By default, results printed to stdout
          Use --json or --yaml for structured output
          Exit codes: 0 (success), 1 (error)

        SEARCH TYPES:

          auto     Auto-detect based on pattern (default)
          file     File name search only
          content  File content search only
          hybrid   Both file names and content

        SEARCH TYPE DETECTION:

          Patterns with wildcards (*, ?) → file search
          Regex patterns → content search
          Plain text → content search
      DESC
      # Search type options
      option :type, type: :string, aliases: "-t", desc: "Search type (file, content, hybrid, auto)"
      option :files, type: :boolean, aliases: "-f", desc: "Search for files only"
      option :content, type: :boolean, aliases: "-c", desc: "Search in file content only"
      # Pattern matching options
      option :case_insensitive, type: :boolean, aliases: "-i", desc: "Case insensitive search"
      option :whole_word, type: :boolean, aliases: "-w", desc: "Match whole words only"
      option :multiline, type: :boolean, aliases: "-U", desc: "Enable multiline matching"
      option :hidden, type: :boolean, desc: "Include hidden files and directories"
      # Context options
      option :after_context, type: :numeric, aliases: "-A", desc: "Show NUM lines after match"
      option :before_context, type: :numeric, aliases: "-B", desc: "Show NUM lines before match"
      option :context, type: :numeric, aliases: "-C", desc: "Show NUM lines of context"
      # File filtering options
      option :glob, type: :string, aliases: "-g", desc: "File glob pattern to include"
      option :include, type: :string, desc: "Include only these paths/globs (comma-separated)"
      option :exclude, type: :string, aliases: "-e", desc: "Exclude paths/globs (comma-separated)"
      option :since, type: :string, desc: "Files modified since TIME"
      option :before, type: :string, desc: "Files modified before TIME"
      # Git scope options
      option :staged, type: :boolean, desc: "Search staged files only"
      option :tracked, type: :boolean, desc: "Search tracked files only"
      option :changed, type: :boolean, desc: "Search changed files only"
      # Output options
      option :json, type: :boolean, desc: "Output in JSON format"
      option :yaml, type: :boolean, desc: "Output in YAML format"
      option :files_with_matches, type: :boolean, aliases: "-l", desc: "Only print filenames"
      option :max_results, type: :numeric, desc: "Limit number of results"
      # Interactive options
      option :fzf, type: :boolean, desc: "Use fzf for interactive selection"
      # Preset options
      option :preset, type: :string, aliases: "-p", desc: "Use search preset"
      def search(pattern = nil, search_path = nil)
        # Handle --help/-h passed as first argument
        if pattern == "--help" || pattern == "-h"
          invoke :help, ["search"]
          return 0
        end
        require_relative "commands/search_command"
        Commands::SearchCommand.new(pattern, search_path, options).execute
      end

      desc "version", "Show version"
      long_desc <<~DESC
        Display the current version of ace-search.

        EXAMPLES:

          $ ace-search version
          $ ace-search --version
      DESC
      def version
        puts "ace-search #{Ace::Search::VERSION}"
        0
      end
      map "--version" => :version

      # Handle unknown commands as arguments to the default 'search' command
      def method_missing(command, *args)
        invoke :search, [command.to_s] + args
      end
      # respond_to_missing? inherited from Ace::Core::CLI::Base

      # Intercept Thor's "command not found" error and treat unknown commands
      # as search patterns. This allows patterns like "test", "help", etc.
      # to work correctly instead of raising UndefinedCommandError.
      def self.handle_no_command_error(command, _has_namespace = nil)
        # Treat the unknown command as a search pattern
        # Re-invoke the CLI with the search command
        new().search(command)
      end
    end
  end
end
