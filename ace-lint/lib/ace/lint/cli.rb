# frozen_string_literal: true

require 'thor'
require_relative 'commands/lint_command'
require_relative 'version'

module Ace
  module Lint
    # CLI interface using Thor
    class CLI < Thor
      def self.exit_on_failure?
        true
      end

      # Override to allow `ace-lint file.md` without explicit `lint` command
      def self.start(given_args = ARGV, config = {})
        # If first arg looks like a file/path (not a known command), prepend 'lint'
        if given_args.any? && !%w[lint version help].include?(given_args.first) && !given_args.first.start_with?('-')
          given_args.unshift('lint')
        end
        super(given_args, config)
      end

      desc 'lint [FILES...]', 'Lint markdown, YAML, and frontmatter files'
      method_option :fix, type: :boolean, aliases: '-f', desc: 'Auto-fix/format files'
      method_option :format, type: :boolean, desc: 'Format files with kramdown'
      method_option :type, type: :string, aliases: '-t', desc: 'File type (markdown, yaml, frontmatter)'
      method_option :quiet, type: :boolean, aliases: '-q', desc: 'Suppress detailed output'
      method_option :line_width, type: :numeric, desc: 'Line width for formatting (default: 120)'
      def lint(*files)
        exit_code = Commands::LintCommand.execute(files, options)
        exit(exit_code)
      end

      desc 'version', 'Show version'
      def version
        puts "ace-lint version #{Ace::Lint::VERSION}"
      end

      # Default command is lint
      default_task :lint
    end
  end
end
