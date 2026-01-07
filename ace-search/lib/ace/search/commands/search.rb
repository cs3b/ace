# frozen_string_literal: true

require_relative "search_command"

module Ace
  module Search
    module Commands
      # dry-cli Command class for the search command
      #
      # This wraps the existing SearchCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Search < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Search across the codebase with intelligent pattern matching

          Search Type Detection:
            Patterns are auto-detected as file or content searches:
              *.rb, **/*.js       -> file search (glob patterns)
              TODO, class.*       -> content search (regex)
            Use --files or --content to override auto-detection

          Configuration:
            Global config:  ~/.ace/search/config.yml
            Project config: .ace/search/config.yml
            Search presets configured via search.presets
        DESC

        # Examples shown in help output
        # Note: dry-cli automatically prefixes with "ace-search search"
        example [
          'TODO                      # Content search (auto-detect)',
          '"*.rb"                    # File search (glob pattern)',
          'pattern --staged          # Search staged files only',
          '"class.*Manager" -c       # Explicit content search',
          '"todo" -i -C 3            # Case insensitive with context',
          'pattern --glob "**/*.rb"  # Filter by file pattern',
          'TODO --preset daily-scan  # Use search preset'
        ]

        # Define positional arguments
        argument :pattern, required: false, desc: "Search pattern"
        argument :search_path, required: false, desc: "Optional search path"

        # Search type options
        option :type, type: :string, aliases: %w[-t], desc: "Search type (file, content, hybrid, auto)"
        option :files, type: :boolean, aliases: %w[-f], desc: "Search for files only"
        option :content, type: :boolean, aliases: %w[-c], desc: "Search in file content only"

        # Pattern matching options
        option :case_insensitive, type: :boolean, aliases: %w[-i], desc: "Case insensitive search"
        option :whole_word, type: :boolean, aliases: %w[-w], desc: "Match whole words only"
        option :multiline, type: :boolean, aliases: %w[-U], desc: "Enable multiline matching"
        option :hidden, type: :boolean, desc: "Include hidden files and directories"

        # Context options
        option :after_context, type: :integer, aliases: %w[-A], desc: "Show NUM lines after match"
        option :before_context, type: :integer, aliases: %w[-B], desc: "Show NUM lines before match"
        option :context, type: :integer, aliases: %w[-C], desc: "Show NUM lines of context"

        # File filtering options
        option :glob, type: :string, aliases: %w[-g], desc: "File glob pattern to include"
        option :include, type: :string, desc: "Include only these paths/globs (comma-separated)"
        option :exclude, type: :string, aliases: %w[-e], desc: "Exclude paths/globs (comma-separated)"
        option :since, type: :string, desc: "Files modified since TIME"
        option :before, type: :string, desc: "Files modified before TIME"

        # Git scope options
        option :staged, type: :boolean, desc: "Search staged files only"
        option :tracked, type: :boolean, desc: "Search tracked files only"
        option :changed, type: :boolean, desc: "Search changed files only"

        # Output options
        option :json, type: :boolean, desc: "Output in JSON format"
        option :yaml, type: :boolean, desc: "Output in YAML format"
        option :files_with_matches, type: :boolean, aliases: %w[-l], desc: "Only print filenames"
        option :max_results, type: :integer, desc: "Limit number of results"

        # Interactive options
        option :fzf, type: :boolean, desc: "Use fzf for interactive selection"

        # Preset options
        option :preset, type: :string, aliases: %w[-p], desc: "Use search preset"

        # Standard options (inherited from Base but need explicit definition for dry-cli)
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(**options)
          # Use the existing SearchCommand logic
          pattern = options[:pattern]
          search_path = options[:search_path]

          # Remove dry-cli specific keys (args is leftover arguments)
          clean_options = options.reject { |k, _| k == :args }

          # Type-convert numeric options (dry-cli returns strings, Thor converted to integers)
          # This maintains parity with the Thor implementation
          numeric_options = %i[max_results context after_context before_context]
          numeric_options.each do |key|
            clean_options[key] = clean_options[key].to_i if clean_options[key]
          end

          command = SearchCommand.new(pattern, search_path, clean_options)
          command.execute
        end
      end
    end
  end
end
