# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module Git
      class LogColorFormatter
        # ANSI color codes for git log output
        COLORS = {
          reset: "\033[0m",
          # Repository names
          repo_name: "\033[33m", # Yellow for repository names
          # Commit elements
          commit_hash: "\033[33m",    # Yellow for commit hash
          author: "\033[36m",         # Cyan for author
          date: "\033[32m",           # Green for date
          commit_subject: "\033[37m", # White for commit subject/message
          commit_body: "\033[37m",    # White for commit body
          # Special formatting
          bold: "\033[1m",
          dim: "\033[2m"
        }.freeze

        def self.format_commit(commit, options = {})
          new(options).format_commit(commit)
        end

        def self.should_use_color?(options = {})
          new(options).should_use_color?
        end

        def initialize(options = {})
          @use_color = determine_color_usage(options)
        end

        def format_commit(commit)
          return commit[:display_line] unless @use_color

          case commit[:type]
          when :oneline
            format_oneline_commit(commit)
          when :multiline
            format_multiline_commit(commit)
          else
            commit[:display_line]
          end
        end

        def should_use_color?
          @use_color
        end

        private

        attr_reader :use_color

        def determine_color_usage(options)
          # Explicit --no-color flag takes precedence
          return false if options[:no_color]

          # Environment variable NO_COLOR takes precedence
          return false if ENV['NO_COLOR']

          # FORCE_COLOR environment variable or --force-color option enables color
          return true if ENV['FORCE_COLOR'] || options[:force_color]

          # Since --force-color is now default true, we'll use colors by default
          # unless explicitly disabled
          true
        end

        def format_oneline_commit(commit)
          # Extract hash and message from display line
          if commit[:display_line] =~ /^(\w+)\s+(.+)$/
            hash_part = ::Regexp.last_match(1)
            message_part = ::Regexp.last_match(2)

            "#{colorize(hash_part, :commit_hash)} #{colorize(message_part, :commit_subject)}"
          else
            colorize(commit[:display_line], :commit_subject)
          end
        end

        def format_multiline_commit(commit)
          lines = commit[:display_line].split("\n")
          formatted_lines = []

          lines.each do |line|
            case line
            when /^commit\s+(\w+)$/
              # Commit hash line
              hash = ::Regexp.last_match(1)
              formatted_lines << "#{colorize('commit', :bold)} #{colorize(hash, :commit_hash)}"
            when /^Author:\s+(.+)$/
              # Author line
              author = ::Regexp.last_match(1)
              formatted_lines << "#{colorize('Author:', :bold)} #{colorize(author, :author)}"
            when /^Date:\s+(.+)$/
              # Date line
              date = ::Regexp.last_match(1)
              formatted_lines << "#{colorize('Date:', :bold)}   #{colorize(date, :date)}"
            when /^\s{4,}/
              # Indented lines (commit message)
              formatted_lines << colorize(line, :commit_subject)
            else
              # Other lines
              formatted_lines << colorize(line, :commit_body)
            end
          end

          formatted_lines.join("\n")
        end

        def colorize(text, color)
          return text unless @use_color && COLORS[color]

          "#{COLORS[color]}#{text}#{COLORS[:reset]}"
        end
      end
    end
  end
end
