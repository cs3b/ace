# frozen_string_literal: true

require "open3"
require "shellwords"
require "timeout"

module Ace
  module Search
    module Atoms
      # RipgrepExecutor provides a safe wrapper around ripgrep (rg) command
      # This is an atom - pure function for executing ripgrep commands
      module RipgrepExecutor
        module_function

        # Execute ripgrep with given options and pattern
        # @param pattern [String] Search pattern (regex)
        # @param options [Hash] Search options
        # @return [Hash] Command result with success status and output
        def execute(pattern, options = {})
          return {success: false, error: "Pattern cannot be nil or empty"} if pattern.nil? || pattern.empty?

          command = build_command(pattern, options)
          timeout_seconds = options.fetch(:timeout, 120)

          begin
            stdout, stderr, status = Timeout.timeout(timeout_seconds) do
              Open3.capture3(command)
            end

            {
              success: status.success?,
              stdout: stdout,
              stderr: stderr,
              exit_code: status.exitstatus,
              command: command
            }
          rescue Timeout::Error
            {
              success: false,
              error: "Command timed out after #{timeout_seconds} seconds",
              exit_code: -1
            }
          rescue => e
            {
              success: false,
              error: e.message,
              exit_code: -1
            }
          end
        end

        # Check if ripgrep is available
        # @return [Boolean] True if ripgrep is installed
        def available?
          stdout, _stderr, status = Open3.capture3("which rg")
          status.success? && !stdout.strip.empty?
        rescue
          false
        end

        # Build ripgrep command with proper escaping
        # @param pattern [String] Search pattern
        # @param options [Hash] Search options
        # @return [String] Complete ripgrep command
        def build_command(pattern, options = {})
          args = ["rg"]

          # Basic options
          args << "--color=never" unless options[:color]
          args << "--json" if options[:json_output]
          args << "--line-number" unless options[:no_line_numbers]
          args << "--no-heading" unless options[:heading]
          args << "--with-filename" unless options[:no_filename]
          args << "--count" if options[:count]
          args << "--files-with-matches" if options[:files_with_matches]
          args << "--invert-match" if options[:invert_match]
          args << "--hidden" if options[:hidden]

          # Context options
          if options[:context]
            args << "--context=#{options[:context]}"
          elsif options[:before_context] || options[:after_context]
            args << "--before-context=#{options[:before_context]}" if options[:before_context]
            args << "--after-context=#{options[:after_context]}" if options[:after_context]
          end

          # File type filtering
          if options[:file_type]
            Array(options[:file_type]).each { |t| args << "--type=#{t}" }
          end

          # Glob patterns
          if options[:glob]
            Array(options[:glob]).each { |g| args << "--glob=#{Shellwords.escape(g)}" }
          end

          # Case sensitivity
          args << "--ignore-case" if options[:ignore_case]
          args << "--case-sensitive" if options[:case_sensitive]

          # Max results
          args << "--max-count=#{options[:max_count]}" if options[:max_count]

          # Multiline mode
          args << "--multiline" if options[:multiline]
          args << "--multiline-dotall" if options[:multiline_dotall]

          # Whole word matching
          args << "--word-regexp" if options[:word_regexp]

          # Search paths
          paths = if options[:search_path]
            [options[:search_path]]
          elsif options[:paths]
            options[:paths]
          else
            ["."]
          end

          # Build the complete command
          command_parts = args + [Shellwords.escape(pattern)] + paths.map { |p| Shellwords.escape(p) }
          command_parts.join(" ")
        end

        # Get ripgrep version
        # @return [String, nil] Version string or nil if not available
        def version
          return nil unless available?

          stdout, _stderr, status = Open3.capture3("rg --version")
          if status.success?
            version_match = stdout.match(/ripgrep ([\d.]+)/)
            version_match ? version_match[1] : nil
          end
        rescue
          nil
        end
      end
    end
  end
end
