# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module Git
      class StatusColorFormatter
        # ANSI color codes for git status
        COLORS = {
          reset: "\033[0m",
          # Repository status colors
          red: "\033[31m",           # For repos with changes
          green: "\033[32m",         # For clean repos
          yellow: "\033[33m",        # For repos with untracked files
          blue: "\033[34m",          # For unknown status
          bold: "\033[1m",           # For emphasis
          # File status colors (following git's color scheme)
          staged_new: "\033[32m", # Green for new files (staged)
          staged_modified: "\033[32m", # Green for modified files (staged)
          staged_deleted: "\033[32m",  # Green for deleted files (staged)
          modified: "\033[31m",      # Red for modified files (not staged)
          deleted: "\033[31m",       # Red for deleted files (not staged)
          untracked: "\033[31m",     # Red for untracked files
          branch: "\033[32m",        # Green for branch names
          header: "\033[1m",         # Bold for headers
          meta: "\033[2m"            # Dim for meta text (hints)
        }.freeze

        def self.format_repository_status(repo_name, status_output, options = {})
          new(options).format_repository_status(repo_name, status_output)
        end

        def self.should_use_color?(options = {})
          new(options).should_use_color?
        end

        def initialize(options = {})
          @use_color = determine_color_usage(options)
          @force_color = options[:force_color] || false
          @no_color = options[:no_color] || false
        end

        def format_repository_status(repo_name, status_output)
          status_type = determine_status_type(status_output)
          color = color_for_status(status_type)

          if status_output.strip.empty?
            format_clean_repository(repo_name, color)
          else
            format_repository_with_changes(repo_name, status_output, color)
          end
        end

        def should_use_color?
          @use_color
        end

        private

        attr_reader :use_color, :force_color, :no_color

        def determine_color_usage(options)
          # Explicit --no-color flag takes precedence
          return false if options[:no_color]

          # Environment variable NO_COLOR takes precedence
          return false if ENV["NO_COLOR"]

          # FORCE_COLOR environment variable or --force-color option enables color
          return true if ENV["FORCE_COLOR"] || options[:force_color]

          # Since --force-color is now default true, we'll use colors by default
          # unless explicitly disabled
          true
        end

        def determine_status_type(status_output)
          return :clean if status_output.strip.empty?

          # For verbose git status output, look for key indicators
          output_text = status_output.downcase

          # Check for conflict markers
          return :conflict if output_text.include?("both modified") || output_text.include?("merge conflict")

          # Check for any changes (modified, added, deleted, renamed, etc.)
          if output_text.include?("modified:") ||
              output_text.include?("deleted:") ||
              output_text.include?("new file:") ||
              output_text.include?("renamed:") ||
              output_text.include?("changes not staged") ||
              output_text.include?("changes to be committed")
            return :changes
          end

          # Check for untracked files
          return :untracked if output_text.include?("untracked files:")

          # If it has content but doesn't match patterns, treat as changes
          :changes
        end

        def color_for_status(status_type)
          case status_type
          when :clean
            :green
          when :changes, :conflict
            :red
          when :untracked
            :yellow
          when :unknown
            :blue
          else
            :reset
          end
        end

        def format_clean_repository(repo_name, color)
          if use_color
            "#{colorize("[#{repo_name}]",
              color)} Clean working directory"
          else
            "[#{repo_name}] Clean working directory"
          end
        end

        def format_repository_with_changes(repo_name, status_output, color)
          lines = []

          lines << if use_color
            "#{colorize("[#{repo_name}]", color)} Status:"
          else
            "[#{repo_name}] Status:"
          end

          # Process each line with appropriate coloring
          status_output.lines.each do |line|
            colored_line = use_color ? colorize_status_line(line.rstrip) : line.rstrip
            lines << "  #{colored_line}"
          end

          lines.join("\n")
        end

        def colorize_status_line(line)
          case line
          # Branch information
          when /^On branch (.+)$/
            branch_name = ::Regexp.last_match(1)
            "On branch #{colorize(branch_name, :branch)}"
          when /^Your branch is (.+)$/
            # Keep branch status messages in default color but highlight key parts
            line.gsub(/'([^']+)'/) { |match| colorize(match, :branch) }

          # Section headers
          when /^Changes to be committed:/
            colorize(line, :header)
          when /^Changes not staged for commit:/
            colorize(line, :header)
          when /^Untracked files:/
            colorize(line, :header)

          # File status lines
          when /^\s*(new file|added):\s+(.+)$/
            prefix = ::Regexp.last_match(1)
            filename = ::Regexp.last_match(2)
            "\t#{colorize(prefix + ":", :staged_new)} #{colorize(filename, :staged_new)}"
          when /^\s*modified:\s+(.+)$/
            filename = ::Regexp.last_match(1)
            # Determine if this is in "Changes to be committed" or "Changes not staged"
            # We'll use context from previous lines, but for now, default to modified (red)
            "\t#{colorize("modified:", :modified)} #{colorize(filename, :modified)}"
          when /^\s*deleted:\s+(.+)$/
            filename = ::Regexp.last_match(1)
            "\t#{colorize("deleted:", :deleted)} #{colorize(filename, :deleted)}"
          when /^\s*renamed:\s+(.+)$/
            filename = ::Regexp.last_match(1)
            "\t#{colorize("renamed:", :staged_modified)} #{colorize(filename, :staged_modified)}"
          when /^\s*copied:\s+(.+)$/
            filename = ::Regexp.last_match(1)
            "\t#{colorize("copied:", :staged_new)} #{colorize(filename, :staged_new)}"

          # Meta information and hints (must come before untracked files)
          when /^\s*\(use ".+" to .+\)$/
            colorize(line, :meta)
          when /^nothing to commit/
            colorize(line, :meta)
          when /^no changes added to commit/
            colorize(line, :meta)

          # Untracked files (filenames without status prefix, after filtering out meta text)
          when /^\s+([^:()].+)$/
            # This matches indented lines that don't have status prefixes and aren't meta text
            filename = line.strip
            "\t#{colorize(filename, :untracked)}"

          # Default: return line as-is
          else
            line
          end
        end

        def colorize(text, color)
          return text unless use_color && COLORS[color]

          "#{COLORS[color]}#{text}#{COLORS[:reset]}"
        end
      end
    end
  end
end
