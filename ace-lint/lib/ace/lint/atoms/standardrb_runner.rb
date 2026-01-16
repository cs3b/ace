# frozen_string_literal: true

require 'json'
require 'open3'

module Ace
  module Lint
    module Atoms
      # Executes StandardRB linter and parses results
      class StandardrbRunner
        # Thread-safe availability check using ||= pattern
        @available_mutex = Mutex.new

        class << self
          private

          # Check availability with caching (thread-safe)
          def check_availability
            @available_mutex.synchronize do
              @available ||= Open3.capture3('which', 'standardrb')[2].success?
            end
          end
        end

        # Check if StandardRB is available (cached per process, thread-safe)
        # @return [Boolean] True if standardrb command is available
        def self.available?
          check_availability
        end

        # Reset availability cache (for testing purposes)
        # @internal
        def self.reset_availability_cache!
          @available_mutex.synchronize do
            @available = nil
          end
        end

        # Run StandardRB on file(s)
        # @param file_paths [String, Array<String>] Path(s) to lint
        # @param fix [Boolean] Apply autofix
        # @return [Hash] Result with :success, :errors, :warnings
        def self.run(file_paths, fix: false)
          paths = Array(file_paths)
          return unavailable_result unless available?

          cmd = build_command(paths, fix: fix)

          stdout, stderr, status = Open3.capture3(*cmd)

          if status.success?
            parse_success_output(stdout)
          else
            parse_error_output(stdout, stderr, exit_status: status.exitstatus)
          end
        rescue StandardError => e
          {
            success: false,
            errors: [{ message: "StandardRB execution failed for #{Array(file_paths).join(', ')}: #{e.message}" }],
            warnings: []
          }
        end

        # Build StandardRB command
        # @param paths [Array<String>] File paths
        # @param fix [Boolean] Apply fixes
        # @return [Array<String>] Command and arguments
        def self.build_command(paths, fix:)
          ['standardrb', *(fix ? ['--fix'] : []), '--format', 'json', *paths].compact
        end

        # Parse successful StandardRB output (no issues)
        # @param stdout [String] StandardRB output
        # @return [Hash] Parsed result
        def self.parse_success_output(stdout)
          # StandardRB with JSON format outputs empty or specific structure
          # If stdout is empty or contains "no offenses", no issues found
          if stdout.strip.empty? || stdout.include?('no offenses')
            return { success: true, errors: [], warnings: [] }
          end

          parse_json_output(stdout)
        rescue JSON::ParserError
          { success: true, errors: [], warnings: [] }
        end

        # Parse StandardRB error output (issues found)
        # @param stdout [String] StandardRB stdout
        # @param stderr [String] StandardRB stderr
        # @param exit_status [Integer] Process exit status
        # @return [Hash] Parsed result
        def self.parse_error_output(stdout, stderr, exit_status:)
          # StandardRB with JSON format outputs to stdout even on failure
          unless stdout.strip.empty?
            # Try to parse JSON output
            # If parsing fails, fall back to text parsing
            begin
              return parse_json_output(stdout, exit_status: exit_status)
            rescue JSON::ParserError
              return parse_text_output(stderr, exit_status: exit_status)
            end
          end

          # Fallback: parse stderr if stdout is empty
          parse_text_output(stderr, exit_status: exit_status)
        end

        # Parse JSON output from StandardRB
        # @param output [String] JSON string
        # @param exit_status [Integer, nil] Process exit status (nil for success case)
        # @return [Hash] Parsed result
        # @raise [JSON::ParserError] if output is not valid JSON
        def self.parse_json_output(output, exit_status: nil)
          data = JSON.parse(output)

          errors = []
          warnings = []

          # StandardRB (RuboCop) JSON format: {files: [{path, offenses: [...]}]}
          if data.is_a?(Hash) && data.key?('files')
            data['files'].each do |file_data|
              file_path = file_data['path'] || 'unknown'
              offenses = file_data['offenses'] || []

              offenses.each do |offense|
                item = build_offense_item(offense, file_path)
                if offense['severity'] == 'error' || offense['severity'] == 'fatal'
                  errors << item
                else
                  warnings << item
                end
              end
            end
          # Fallback: direct array format (some tools may use this)
          elsif data.is_a?(Array)
            data.each do |offense|
              item = build_offense_item(offense)
              if offense['severity'] == 'error' || offense['severity'] == 'fatal'
                errors << item
              else
                warnings << item
              end
            end
          end

          # Determine success based on exit status when available
          # If process exited non-zero, consider it a failure even for warnings
          success = if exit_status
                      exit_status.zero?
                    else
                      errors.empty?
                    end

          {
            success: success,
            errors: errors,
            warnings: warnings
          }
        end

        # Parse text output from StandardRB (fallback)
        # @param output [String] Text output
        # @param exit_status [Integer, nil] Process exit status (nil for success case)
        # @return [Hash] Parsed result
        def self.parse_text_output(output, exit_status: nil)
          errors = []
          warnings = []

          output.each_line do |line|
            # StandardRB format: file:line:column: severity: message
            next unless line.match?(/^.+:\d+:\d+:/)

            parts = line.split(':', 5)
            next if parts.size < 5

            item = {
              file: parts[0],
              line: parts[1].to_i,
              column: parts[2].to_i,
              message: parts[4].strip
            }

            if line.include?('error') || line.include?('Error')
              errors << item
            else
              warnings << item
            end
          end

          # Determine success based on exit status when available
          success = if exit_status
                      exit_status.zero?
                    else
                      errors.empty?
                    end

          {
            success: success,
            errors: errors,
            warnings: warnings
          }
        end

        # Build offense item from StandardRB offense
        # @param offense [Hash] Offense data
        # @param file_path [String] File path (for RuboCop format where path is at file level)
        # @return [Hash] Offense item
        def self.build_offense_item(offense, file_path = nil)
          # Use provided file_path or try to extract from location (legacy format)
          path = file_path || offense.dig('location', 'path') || 'unknown'
          location = offense['location'] || {}

          {
            file: path,
            line: location['line'] || 0,
            column: location['column'] || 0,
            message: "#{offense['cop_name']}: #{offense['message']}"
          }
        end

        # Result when StandardRB is not available
        # @return [Hash] Error result
        def self.unavailable_result
          {
            success: false,
            errors: [{
              message: 'StandardRB is not installed. Install it with: gem install standardrb'
            }],
            warnings: []
          }
        end
      end
    end
  end
end
