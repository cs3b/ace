# frozen_string_literal: true

require_relative '../taskflow_management/shell_command_executor'
require 'shellwords'

module CodingAgentTools
  module Atoms
    module Search
      # RipgrepExecutor provides a safe wrapper around ripgrep (rg) command
      # This is an atom - it uses existing ShellCommandExecutor for safe command execution
      class RipgrepExecutor
        def initialize
          @executor = CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor
        end

        # Execute ripgrep with given options and pattern
        # @param pattern [String] Search pattern (regex)
        # @param options [Hash] Search options
        # @return [Hash] Command result with success status and output
        def execute(pattern, options = {})
          return { success: false, error: 'Pattern cannot be nil or empty' } if pattern.nil? || pattern.empty?

          command = build_ripgrep_command(pattern, options)
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

        # Check if ripgrep is available
        # @return [Boolean] True if ripgrep is installed
        def available?
          result = @executor.execute("which rg", timeout: 5)
          result[:success]
        end

        # Search for pattern in files
        # @param pattern [String] Search pattern
        # @param options [Hash] Search options
        # @return [Hash] Search results
        def search(pattern, options = {})
          return { success: false, error: "ripgrep not available" } unless available?
          
          result = execute(pattern, options)
          
          if result[:success]
            lines = result[:stdout].split("\n").map(&:strip).reject(&:empty?)
            results = parse_ripgrep_output(lines)
            {
              success: true,
              results: results,
              count: results.size
            }
          else
            {
              success: false,
              error: result[:stderr] || "Search failed",
              exit_code: result[:exit_code]
            }
          end
        end

        # Parse ripgrep output into structured results
        # @param lines [Array<String>] Output lines from ripgrep
        # @return [Array<Hash>] Parsed results
        def parse_ripgrep_output(lines)
          lines.map do |line|
            if match = line.match(/^([^:]+):(\d+):(.*)$/)
              {
                file: match[1],
                line: match[2].to_i,
                text: match[3].strip
              }
            elsif match = line.match(/^([^:]+):(\d+):(\d+):(.*)$/)
              {
                file: match[1],
                line: match[2].to_i,
                column: match[3].to_i,
                text: match[4].strip
              }
            else
              { text: line }
            end
          end
        end

        # Build ripgrep command with proper escaping
        # @param pattern [String] Search pattern
        # @param options [Hash] Search options
        # @return [String] Complete ripgrep command
        def build_ripgrep_command(pattern, options = {})
          args = ['rg']

          # Basic options
          args << '--color=never' unless options[:color]
          args << '--json' if options[:json_output]
          args << '--line-number' unless options[:no_line_numbers] # Default to showing line numbers
          args << '--no-heading' unless options[:heading]
          args << '--with-filename' unless options[:no_filename]
          args << '--count' if options[:count]
          args << '--files-with-matches' if options[:files_with_matches]
          args << '--invert-match' if options[:invert_match]

          # Context options
          if options[:context]
            args << "--context=#{options[:context]}"
          elsif options[:before_context] || options[:after_context]
            args << "--before-context=#{options[:before_context]}" if options[:before_context]
            args << "--after-context=#{options[:after_context]}" if options[:after_context]
          end

          # File type filtering (only for valid ripgrep file types)
          if options[:file_type]
            Array(options[:file_type]).each { |t| args << "--type=#{t}" }
          end

          # Glob patterns for file inclusion/exclusion
          if options[:glob]
            Array(options[:glob]).each { |g| args << "--glob=#{g}" }
          end

          # Case sensitivity
          args << '--ignore-case' if options[:ignore_case]
          args << '--case-sensitive' if options[:case_sensitive]

          # Max results
          args << "--max-count=#{options[:max_count]}" if options[:max_count]

          # Multiline mode
          args << '--multiline' if options[:multiline]
          args << '--multiline-dotall' if options[:multiline_dotall]

          # Search paths (default to current directory if not specified)
          paths = options[:paths] || ['.']
          
          # Build the complete command
          command_parts = args + [Shellwords.escape(pattern)] + paths.map { |p| Shellwords.escape(p) }
          command_parts.join(' ')
        end

        # Check if ripgrep is available
        # @return [Boolean] True if ripgrep is available
        def available?
          result = @executor.execute('which rg', timeout: 5)
          result.success?
        end

        # Get ripgrep version
        # @return [String, nil] Version string or nil if not available
        def version
          return nil unless available?

          result = @executor.execute('rg --version', timeout: 10)
          if result.success?
            # Extract version from output like "ripgrep 13.0.0"
            version_match = result.stdout.match(/ripgrep ([\d.]+)/)
            version_match ? version_match[1] : nil
          end
        end

        # Get supported file types from ripgrep
        # @return [Array<String>] List of supported file types
        def supported_types
          return [] unless available?

          result = @executor.execute('rg --type-list', timeout: 10)
          if result.success?
            result.stdout.lines.map do |line|
              # Parse lines like "cpp: *.C, *.H, *.cc, *.cpp, *.cxx, *.h, *.hh, *.hpp, *.hxx"
              type_match = line.match(/^(\w+):/)
              type_match ? type_match[1] : nil
            end.compact.sort
          else
            []
          end
        end
      end
    end
  end
end