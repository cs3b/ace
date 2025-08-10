# frozen_string_literal: true

require_relative '../taskflow_management/shell_command_executor'
require 'shellwords'

module CodingAgentTools
  module Atoms
    module Search
      # FdExecutor provides a safe wrapper around fd command
      # This is an atom - it uses existing ShellCommandExecutor for safe command execution
      class FdExecutor
        def initialize
          @executor = CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor
        end

        # Execute fd with given pattern and options
        # @param pattern [String] Search pattern (can be glob or regex)
        # @param options [Hash] Search options
        # @return [Hash] Command result with success status and output
        def execute(pattern = nil, options = {})
          command = build_fd_command(pattern, options)
          result = @executor.execute(command, timeout: options.fetch(:timeout, 120))

          {
            success: result[:success],
            stdout: result[:stdout],
            stderr: result[:stderr],
            exit_code: result[:exit_code],
            duration: result[:duration],
            command: command
          }
        end

        # Check if fd is available
        # @return [Boolean] True if fd is installed
        def available?
          result = @executor.execute("which fd", timeout: 5)
          result[:success]
        end

        # Find files matching pattern
        # @param pattern [String] File pattern
        # @param options [Hash] Search options
        # @return [Hash] Search results
        def find_files(pattern, options = {})
          return { success: false, error: "fd not available" } unless available?
          
          result = execute(pattern, options)
          
          if result[:success]
            files = result[:stdout].split("\n").map(&:strip).reject(&:empty?)
            {
              success: true,
              files: files,
              count: files.size
            }
          else
            {
              success: false,
              error: result[:stderr] || "Search failed",
              exit_code: result[:exit_code]
            }
          end
        end

        # Build fd command with proper escaping
        # @param pattern [String, nil] Search pattern (nil for all files)
        # @param options [Hash] Search options
        # @return [String] Complete fd command
        def build_fd_command(pattern = nil, options = {})
          args = ['fd']

          # Basic options
          args << '--color=never' unless options[:color]
          args << '--absolute-path' if options[:absolute_path]
          args << '--follow' if options[:follow_symlinks]
          args << '--hidden' if options[:include_hidden]
          args << '--no-ignore' if options[:no_ignore]
          args << '--no-ignore-vcs' if options[:no_ignore_vcs]

          # Type filtering (for fd file types, not search modes)
          case options[:fd_type]
          when 'f', 'file'
            args << '--type=file'
          when 'd', 'directory'
            args << '--type=directory'
          when 'l', 'symlink'
            args << '--type=symlink'
          when 's', 'socket'
            args << '--type=socket'
          when 'p', 'pipe'
            args << '--type=pipe'
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
          args << '--ignore-case' if options[:ignore_case]
          args << '--case-sensitive' if options[:case_sensitive]

          # Max results
          args << "--max-results=#{options[:max_results]}" if options[:max_results]

          # Exclude patterns
          if options[:exclude]
            Array(options[:exclude]).each { |pattern| args << "--exclude=#{pattern}" }
          end

          # Search paths (default to current directory if not specified)
          paths = options[:paths] || ['.']

          # Build the complete command
          command_parts = args
          command_parts << Shellwords.escape(pattern) if pattern
          command_parts.concat(paths.map { |p| Shellwords.escape(p) })
          
          command_parts.join(' ')
        end

        # Check if fd is available
        # @return [Boolean] True if fd is available
        def available?
          result = @executor.execute('which fd', timeout: 5)
          result.success?
        end

        # Get fd version
        # @return [String, nil] Version string or nil if not available
        def version
          return nil unless available?

          result = @executor.execute('fd --version', timeout: 10)
          if result.success?
            # Extract version from output like "fd 8.4.0"
            version_match = result.stdout.match(/fd ([\d.]+)/)
            version_match ? version_match[1] : nil
          end
        end

        # List files without any filtering (equivalent to 'fd' with no args)
        # @param options [Hash] Search options
        # @return [Hash] Command result
        def list_all_files(options = {})
          execute(nil, options)
        end

        # Search for files by extension
        # @param extension [String] File extension without dot (e.g., 'rb', 'js')
        # @param options [Hash] Additional search options
        # @return [Hash] Command result
        def find_by_extension(extension, options = {})
          execute(nil, options.merge(extension: extension, type: 'file'))
        end

        # Search for directories matching pattern
        # @param pattern [String] Directory name pattern
        # @param options [Hash] Additional search options
        # @return [Hash] Command result
        def find_directories(pattern, options = {})
          execute(pattern, options.merge(type: 'directory'))
        end
      end
    end
  end
end