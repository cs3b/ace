# frozen_string_literal: true

require "thor"

module Ace
  module GitDiff
    # Thor CLI for ace-git-diff
    class CLI < Thor
      def self.exit_on_failure?
        true
      end

      # Override help to show better formatting
      def self.banner(command, _namespace = nil, _subcommand = false)
        return "#{basename} [RANGE] [OPTIONS]" if command.name == "diff"
        "#{basename} #{command.usage}"
      end

      desc "[RANGE]", "Generate git diff with filtering (default command)"
      long_desc <<~DESC
        Generate git diff with configurable filtering and formatting.

        RANGE:
          Optional git range (e.g., HEAD~5..HEAD, origin/main...HEAD)

        EXAMPLES:

          # Smart defaults (unstaged changes OR branch diff)
          $ ace-git-diff
          $ ace-git-diff --since "7d"

          # Specific range
          $ ace-git-diff HEAD~10..HEAD
          $ ace-git-diff origin/main...HEAD

          # Time-based filtering
          $ ace-git-diff --since "1 week ago"
          $ ace-git-diff --since "2025-01-01"

          # Path filtering (glob patterns)
          $ ace-git-diff --paths "lib/**/*.rb" "src/**/*.js"
          $ ace-git-diff --exclude "test/**/*" "vendor/**/*"

          # Save to file
          $ ace-git-diff --output changes.diff
          $ ace-git-diff HEAD~5..HEAD --output /tmp/my-changes.diff

          # Summary format (human-readable)
          $ ace-git-diff --format summary

          # Raw unfiltered diff
          $ ace-git-diff --raw

        CONFIGURATION:

          Global config:  ~/.ace/diff/config.yml
          Project config: .ace/diff/config.yml
          Example:        ace-git-diff/.ace.example/diff/config.yml

        OUTPUT:

          By default, diff is printed to stdout. Use --output to save to file.
          Exit code: 0 (success), 1 (error)
      DESC
      option :format, type: :string, aliases: "-f", default: "diff",
                      desc: "Output format: diff, summary"
      option :since, type: :string, aliases: "-s",
                     desc: "Changes since date/duration (e.g., '7d', '1 week ago')"
      option :paths, type: :array, aliases: "-p",
                     desc: "Include only these glob patterns"
      option :exclude, type: :array, aliases: "-e",
                       desc: "Exclude these glob patterns"
      option :output, type: :string, aliases: "-o",
                      desc: "Write diff to file instead of stdout"
      option :config, type: :string, aliases: "-c",
                      desc: "Load config from specific file"
      option :raw, type: :boolean, default: false,
                   desc: "Raw unfiltered output (no exclusions)"
      def diff(range = nil)
        require_relative "commands/diff_command"
        Commands::DiffCommand.new.execute(range, options)
      rescue Ace::GitDiff::Error => e
        warn "Error: #{e.message}"
        exit 1
      end

      default_task :diff

      desc "version", "Show version"
      def version
        puts Ace::GitDiff::VERSION
        0
      end

      map %w[-v --version] => :version

      # Catch "unknown commands" that might be git ranges (e.g., HEAD~1..HEAD)
      # and treat them as the range argument for the default diff command
      def method_missing(method_name, *args, &block)
        # If it looks like it might be a git range, treat it as the range for diff
        if method_name.to_s.match?(/[~^.]|HEAD|origin|main/)
          # The options are already set by Thor, just call diff with the range
          invoke :diff, [method_name.to_s]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.match?(/[~^.]|HEAD|origin|main/) || super
      end
    end
  end
end
