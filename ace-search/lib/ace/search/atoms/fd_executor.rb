# frozen_string_literal: true

require "open3"
require "shellwords"
require "timeout"

module Ace
  module Search
    module Atoms
      # FdExecutor provides a safe wrapper around fd command
      # This is an atom - pure function for executing fd commands
      module FdExecutor
        module_function

        # Execute fd with given pattern and options
        # @param pattern [String] Search pattern (can be glob or regex)
        # @param options [Hash] Search options
        # @return [Hash] Command result with success status and output
        def execute(pattern = nil, options = {})
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

        # Check if fd is available
        # @return [Boolean] True if fd is installed
        def available?
          stdout, _stderr, status = Open3.capture3("which fd")
          status.success? && !stdout.strip.empty?
        rescue
          false
        end

        # Build fd command with proper escaping
        # @param pattern [String, nil] Search pattern (nil for all files)
        # @param options [Hash] Search options
        # @return [String] Complete fd command
        def build_command(pattern = nil, options = {})
          args = ["fd"]

          # Basic options
          args << "--color=never" unless options[:color]
          args << "--absolute-path" if options[:absolute_path]
          args << "--follow" if options[:follow_symlinks]
          args << "--hidden" if options[:include_hidden] || options[:hidden]
          args << "--no-ignore" if options[:no_ignore]
          args << "--no-ignore-vcs" if options[:no_ignore_vcs]

          # Type filtering
          case options[:fd_type]
          when "f", "file"
            args << "--type=file"
          when "d", "directory"
            args << "--type=directory"
          when "l", "symlink"
            args << "--type=symlink"
          when "s", "socket"
            args << "--type=socket"
          when "p", "pipe"
            args << "--type=pipe"
          end

          # Extension filtering
          if options[:extension]
            Array(options[:extension]).each { |ext| args << "--extension=#{ext}" }
          end

          # Size filtering
          args << "--size=#{options[:size]}" if options[:size]

          # Depth limiting
          args << "--max-depth=#{options[:max_depth]}" if options[:max_depth]
          args << "--min-depth=#{options[:min_depth]}" if options[:min_depth]

          # Case sensitivity
          args << "--ignore-case" if options[:ignore_case]
          args << "--case-sensitive" if options[:case_sensitive]

          # Max results
          args << "--max-results=#{options[:max_results]}" if options[:max_results]

          # Exclude patterns
          if options[:exclude]
            Array(options[:exclude]).each { |pattern| args << "--exclude=#{pattern}" }
          end

          # Search paths
          paths = if options[:search_path]
            [options[:search_path]]
          elsif options[:paths]
            options[:paths]
          else
            ["."]
          end

          # Build the complete command
          command_parts = args

          # Add pattern with appropriate flag
          if pattern
            # Check if pattern looks like a glob
            if pattern.include?("*") || pattern.include?("?") || pattern.include?("[")
              command_parts << "--glob"
            end
            command_parts << Shellwords.escape(pattern)
          end

          command_parts.concat(paths.map { |p| Shellwords.escape(p) })

          command_parts.join(" ")
        end

        # Get fd version
        # @return [String, nil] Version string or nil if not available
        def version
          return nil unless available?

          stdout, _stderr, status = Open3.capture3("fd --version")
          if status.success?
            version_match = stdout.match(/fd ([\d.]+)/)
            version_match ? version_match[1] : nil
          end
        rescue
          nil
        end
      end
    end
  end
end
