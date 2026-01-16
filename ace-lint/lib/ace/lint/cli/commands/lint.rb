# frozen_string_literal: true

require "dry/cli"
require "ace/core/cli/dry_cli/base"
require_relative '../../organisms/lint_orchestrator'
require_relative '../../organisms/result_reporter'

module Ace
  module Lint
    module CLI
      module Commands
        # dry-cli Command class for the lint command
        #
        # This command provides linting functionality for markdown, YAML, and
        # frontmatter files, maintaining complete parity with the Thor implementation.
        class Lint < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Lint markdown, YAML, Ruby, and frontmatter files

            File Type Auto-Detection:
              File types are detected from extensions by default:
                .md, .markdown → markdown (frontmatter validation)
                .yml, .yaml    → yaml (syntax checking)
                .rb, .rake, .gemspec → ruby (StandardRB linting)
                *.*            → frontmatter (YAML frontmatter in any file)

            Configuration:
              Global config:  ~/.ace/lint/config.yml
              Project config: .ace/lint/config.yml
              Example:        ace-lint/.ace-defaults/lint/config.yml

            Output:
              Exit codes: 0 (success), 1 (errors found), 2 (fatal error)
              Errors printed to stderr in format: "file:line: message"
              Use --quiet to suppress detailed output
          DESC

          # Examples shown in help output
          # Note: dry-cli automatically prefixes with "ace-lint lint"
          example [
            'README.md                    # Auto-detect type from extension',
            '--fix README.md              # Auto-fix and format',
            '--type yaml config.yml       # Explicit type specification',
            '--type ruby lib/file.rb      # Lint Ruby file',
            'docs/**/*.md --format        # Format with kramdown',
            'file1.md file2.rb --fix      # Multiple files with options',
            '**/*.rb --quiet              # Glob pattern with options'
          ]

          # Define positional arguments for file paths
          # Using a splat argument to accept multiple files
          argument :files, required: false, type: :array, desc: "Files to lint"

          # Method options (maintaining parity with Thor implementation)
          option :fix, type: :boolean, aliases: %w[-f], desc: "Auto-fix/format files"
          option :format, type: :boolean, desc: "Format files with kramdown"
          option :type, type: :string, aliases: %w[-t], desc: "File type (markdown, yaml, ruby, frontmatter)"
          option :line_width, type: :integer, desc: "Line width for formatting (default: 120)"

          # Standard options (inherited from Base but need explicit definition for dry-cli)
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress detailed output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

          def call(**options)
            # Extract files array from options (dry-cli passes it as :files key)
            files = options[:files] || []

            # Remove dry-cli specific keys (args is leftover arguments)
            clean_options = options.reject { |k, _| k == :files || k == :args }

            # Type-convert numeric options (dry-cli returns strings for integers in some cases)
            # This maintains parity with the Thor implementation
            clean_options[:line_width] = clean_options[:line_width].to_i if clean_options[:line_width]

            # Validate inputs
            if files.empty?
              puts 'Error: No files specified'
              puts 'Usage: ace-lint [FILES...] [OPTIONS]'
              return 1
            end

            # Expand globs
            expanded_paths = expand_file_paths(files)

            if expanded_paths.empty?
              puts 'Error: No files found matching the given patterns'
              return 1
            end

            # Create orchestrator
            orchestrator = Organisms::LintOrchestrator.new

            # Prepare options
            lint_options = prepare_options(clean_options)

            # Lint files
            results = orchestrator.lint_files(expanded_paths, options: lint_options)

            # Report results
            verbose = !clean_options[:quiet]
            Organisms::ResultReporter.report(results, verbose: verbose)

            # Return exit code
            Organisms::ResultReporter.exit_code(results)
          end

          private

          # Expand file paths, handling glob patterns
          # @param paths [Array<String>] File paths or glob patterns
          # @return [Array<String>] Expanded file paths
          def expand_file_paths(paths)
            expanded = []

            paths.each do |path|
              # Check if it's a glob pattern
              if path.include?('*')
                matched_files = Dir.glob(path)
                expanded.concat(matched_files)
              elsif File.exist?(path)
                expanded << path
              else
                puts "Warning: File not found: #{path}"
              end
            end

            expanded.uniq.sort
          end

          # Prepare options for the linter
          # @param options [Hash] Raw command options
          # @return [Hash] Prepared options for lint orchestrator
          def prepare_options(options)
            prepared = {}

            # Type option
            prepared[:type] = options[:type].to_sym if options[:type]

            # Fix/format options
            prepared[:fix] = options[:fix] if options[:fix]
            prepared[:format] = options[:format] if options[:format]

            # Kramdown options
            kramdown_opts = {}
            kramdown_opts[:line_width] = options[:line_width] if options[:line_width]
            prepared[:kramdown_options] = kramdown_opts unless kramdown_opts.empty?

            prepared
          end
        end
      end
    end
  end
end
