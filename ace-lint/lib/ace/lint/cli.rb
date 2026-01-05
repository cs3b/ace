# frozen_string_literal: true

require 'ace/core/cli/base'
require_relative 'commands/lint_command'
require_relative 'version'

module Ace
  module Lint
    # CLI interface using Thor
    class CLI < Ace::Core::CLI::Base
      # class_options :quiet, :verbose, :debug inherited from Base

      # Override to allow `ace-lint file.md` without explicit `lint` command
      def self.start(given_args = ARGV, config = {})
        # If first arg looks like a file/path (not a known command), prepend 'lint'
        if given_args.any? && !%w[lint version help].include?(given_args.first) && !given_args.first.start_with?('-')
          given_args.unshift('lint')
        end
        super(given_args, config)
      end

      # Override help to add examples section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "File Type Auto-Detection:"
        shell.say "  File types are detected from extensions by default:"
        shell.say "    .md  → markdown (frontmatter validation)"
        shell.say "    .yml, .yaml → yaml (syntax checking)"
        shell.say "    *.*  → frontmatter (YAML frontmatter in any file)"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-lint README.md                    # Auto-detect type from extension"
        shell.say "  ace-lint --fix README.md              # Auto-fix and format"
        shell.say "  ace-lint --type yaml config.yml       # Explicit type specification"
        shell.say "  ace-lint docs/**/*.md --format        # Format with kramdown"
      end

      desc 'lint [FILES...]', 'Lint markdown, YAML, and frontmatter files'
      long_desc <<~DESC
        Lint markdown, YAML, and frontmatter files for common issues.
        Auto-detects file type from extension by default.

        SYNTAX:
          ace-lint [FILES...] [OPTIONS]
          ace-lint lint [FILES...] [OPTIONS]

        EXAMPLES:

          # Basic linting (auto-detect file type)
          $ ace-lint README.md
          $ ace-lint docs/**/*.md

          # Auto-fix and format
          $ ace-lint --fix README.md
          $ ace-lint --format --line-width 80 docs/*.md

          # Specific file type (override auto-detection)
          $ ace-lint --type yaml config.yml
          $ ace-lint --type frontmatter _posts/*.md

          # Multiple files with options
          $ ace-lint file1.md file2.yml --fix
          $ ace-lint **/*.md --quiet --format

        SUPPORTED FILE TYPES:

          markdown     .md files with frontmatter validation
          yaml         .yml, .yaml files with syntax checking
          frontmatter  Files with YAML frontmatter (any extension)

        CONFIGURATION:

          Global config:  ~/.ace/lint/config.yml
          Project config: .ace/lint/config.yml
          Example:        ace-lint/.ace-defaults/lint/config.yml

        OUTPUT:

          Exit codes: 0 (success), 1 (errors found), 2 (fatal error)
          Errors printed to stderr in format: "file:line: message"
          Use --quiet to suppress detailed output
      DESC
      method_option :fix, type: :boolean, aliases: '-f', desc: 'Auto-fix/format files'
      method_option :format, type: :boolean, desc: 'Format files with kramdown'
      method_option :type, type: :string, aliases: '-t', desc: 'File type (markdown, yaml, frontmatter)'
      # :quiet option inherited from Base class (-q alias)
      method_option :line_width, type: :numeric, desc: 'Line width for formatting (default: 120)'
      def lint(*files)
        # Handle --help/-h passed as first argument
        if files.first == "--help" || files.first == "-h"
          invoke :help, ["lint"]
          return 0
        end
        Commands::LintCommand.execute(files, options)
      end

      # Define version command using Base class helper (maps --version, not -v)
      version_command 'ace-lint', Ace::Lint::VERSION

      # Default command is lint
      default_task :lint
    end
  end
end
