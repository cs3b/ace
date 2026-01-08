# frozen_string_literal: true

require "dry/cli"
require "ace/core/cli/dry_cli/base"
require_relative "lint_command"

module Ace
  module Lint
    module Commands
      # dry-cli Command class for the lint command
      #
      # This wraps the existing LintCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Lint < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Lint markdown, YAML, and frontmatter files

          File Type Auto-Detection:
            File types are detected from extensions by default:
              .md  → markdown (frontmatter validation)
              .yml, .yaml → yaml (syntax checking)
              *.*  → frontmatter (YAML frontmatter in any file)

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
          'docs/**/*.md --format        # Format with kramdown',
          'file1.md file2.yml --fix     # Multiple files with options',
          '**/*.md --quiet --format     # Glob pattern with options'
        ]

        # Define positional arguments for file paths
        # Using a splat argument to accept multiple files
        argument :files, required: false, type: :array, desc: "Files to lint"

        # Method options (maintaining parity with Thor implementation)
        option :fix, type: :boolean, aliases: %w[-f], desc: "Auto-fix/format files"
        option :format, type: :boolean, desc: "Format files with kramdown"
        option :type, type: :string, aliases: %w[-t], desc: "File type (markdown, yaml, frontmatter)"
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

          # Use the existing LintCommand logic
          LintCommand.execute(files, clean_options)
        end
      end
    end
  end
end
