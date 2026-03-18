# frozen_string_literal: true

require "json"
require "set"
require_relative "../../../search/models/search_options"
require_relative "../../../search/models/search_preset"
require_relative "../../../search/models/search_result"
require_relative "../../../search/molecules/search_option_builder"

module Ace
  module Search
    module CLI
      module Commands
        # ace-support-cli Command class for the search command
        #
        # This command handles all search functionality including file and content
        # search across the codebase with intelligent pattern matching.
        #
        # Note: CLI orchestration methods (execute_search_command, resolve_search_path)
        # are intentionally in this class as they handle CLI-specific concerns
        # (config display, error messages, interactive selection). Business logic
        # is properly delegated to ATOM layers (UnifiedSearcher, SearchPathResolver).
        class Search < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

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

          # Examples shown in help output for single-command usage
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
          option :count, type: :boolean, desc: "Show match counts"
          option :files_with_matches, type: :boolean, aliases: %w[-l], desc: "Only print filenames"
          option :max_results, type: :integer, desc: "Limit number of results"

          # Interactive options
          option :fzf, type: :boolean, desc: "Use fzf for interactive selection"

          # Preset options
          option :preset, type: :string, aliases: %w[-p], desc: "Use search preset"

          # Standard options (inherited from Base but need explicit definition for ace-support-cli)
          option :version, type: :boolean, desc: "Show version information"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            # Extract pattern and search path
            @pattern = options[:pattern]
            @search_path = options[:search_path]

            # Remove ace-support-cli specific keys (args is leftover arguments)
            clean_options = options.reject { |k, _| k == :args }
            if clean_options[:version]
              puts "ace-search #{Ace::Search::VERSION}"
              return 0
            end

            # Type-convert numeric options using Base helper for proper validation
            # coerce_types uses Integer() which raises ArgumentError on invalid input
            # (unlike .to_i which silently returns 0)
            coerce_types(clean_options,
                          max_results: :integer,
                          context: :integer,
                          after_context: :integer,
                          before_context: :integer)

            # Build search options from CLI options using dedicated molecule
            @options = Ace::Search::Molecules::SearchOptionBuilder.new(clean_options).build

            # Execute search
            execute_search_command
          end

          private

          def execute_search_command
            display_config_summary

            # Validate pattern
            if @pattern.nil? || @pattern.empty?
              raise Ace::Support::Cli::Error.new("No search pattern provided")
            end

            # Resolve search path
            resolve_search_path(@search_path)

            # Apply preset if specified
            apply_preset if @options[:preset]

            # Execute search
            result = execute_search
            unless result[:success]
              raise Ace::Support::Cli::Error.new("Search failed")
            end

            # Store result for interactive selection
            @result = result

            # Apply interactive selection if requested
            apply_interactive_selection if @options[:interactive]

            # Format and output results
            output_results(@result)
          rescue => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          def resolve_search_path(search_path)
            resolver = Ace::Search::Atoms::SearchPathResolver.new
            resolved_path = resolver.resolve(search_path)
            @options[:search_path] = resolved_path

            # Validate explicit paths (warn if non-existent)
            if search_path && search_path.strip != "" && resolved_path != "."
              expanded_path = File.expand_path(resolved_path)
              unless Dir.exist?(expanded_path)
                $stderr.puts "Warning: Search path '#{resolved_path}' not found (resolved to: #{expanded_path})."
                $stderr.puts "         The underlying search tool may return errors or no results."
              end
            end

            # Debug output
            Ace::Search::Atoms::DebugLogger.section("CLI Search Path Resolution") do
              Ace::Search::Atoms::DebugLogger.log("Resolved search path: #{resolved_path.inspect}")
              Ace::Search::Atoms::DebugLogger.log("Current directory: #{Dir.pwd}")
            end
          end

          def apply_preset
            preset_manager = Ace::Search::Molecules::PresetManager.new
            @options = preset_manager.merge_with_options(@options[:preset], @options)
          end

          def execute_search
            searcher = Ace::Search::Organisms::UnifiedSearcher.new
            searcher.search(@pattern, @options)
          end

          def apply_interactive_selection
            return unless Ace::Search::Atoms::ToolChecker.fzf_available?

            @result[:results] = Ace::Search::Organisms::FzfIntegrator.select(@result[:results], @options)
          end

          def output_results(result)
            # Print summary for text format
            if @options[:format] == :text
              puts Ace::Search::Organisms::ResultFormatter.format_summary(
                result[:results],
                mode: result[:mode],
                pattern: @pattern,
                glob: @options[:glob],
                scope: @options[:scope],
                search_path: @options[:search_path]
              )
              puts ""
            end

            # Print results
            output = Ace::Search::Organisms::ResultFormatter.format(
              result[:results],
              format: @options[:format],
              options: @options
            )
            puts output
          end

          def display_config_summary
            return if @options[:format] != :text # Only show for text output

            require "ace/core"
            Ace::Core::Atoms::ConfigSummary.display(
              command: "search",
              config: Ace::Search.config,
              defaults: Ace::Search.load_gem_defaults,
              options: @options,
              quiet: @options[:quiet]
            )
          end
        end
      end
    end
  end
end
