# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Lint
    module Atoms
      # Base class for Ruby linter runners
      # Provides shared parsing logic for RuboCop-style JSON output
      class BaseRunner
        # Thread-safe availability cache (shared across all subclasses)
        @availability_mutex = Mutex.new
        @availability_cache = {}

        class << self
          # Check if the linter is available (cached per process, thread-safe)
          # @return [Boolean] True if linter command is available
          def available?
            BaseRunner.instance_variable_get(:@availability_mutex).synchronize do
              cache = BaseRunner.instance_variable_get(:@availability_cache)
              cmd = command_name
              cache[cmd] ||= system_has_command?(cmd)
            end
          end

          # Reset availability cache for this linter (for testing purposes)
          # @internal
          def reset_availability_cache!
            BaseRunner.instance_variable_get(:@availability_mutex).synchronize do
              cache = BaseRunner.instance_variable_get(:@availability_cache)
              cache.delete(command_name)
            end
          end

          # Command name to check for availability (subclass override)
          # @return [String] Command name
          def command_name
            raise NotImplementedError, "Subclass must implement command_name"
          end

          # Execute the linter command
          # Subclasses must implement: tool_name, build_command, unavailable_result
          # @param file_paths [String, Array<String>] Path(s) to lint
          # @param fix [Boolean] Apply autofix
          # @param config_path [String, nil] Explicit config path
          # @return [Hash] Result with :success, :errors, :warnings
          def run(file_paths, fix: false, config_path: nil)
            paths = Array(file_paths)
            return unavailable_result unless available?

            cmd = build_command(paths, fix: fix, config_path: config_path)
            stdout, stderr, status = Open3.capture3(*cmd)

            if status.success?
              parse_success_output(stdout)
            else
              parse_error_output(stdout, stderr, exit_status: status.exitstatus)
            end
          rescue => e
            {
              success: false,
              errors: [{message: "#{tool_name} execution failed for #{Array(file_paths).join(", ")}: #{e.message}"}],
              warnings: []
            }
          end

          # Parse successful output (no issues)
          # @param stdout [String] Linter output
          # @return [Hash] Parsed result
          def parse_success_output(stdout)
            if stdout.strip.empty? || stdout.include?("no offenses")
              return {success: true, errors: [], warnings: []}
            end

            parse_json_output(stdout)
          rescue JSON::ParserError
            {success: true, errors: [], warnings: []}
          end

          # Parse error output (issues found)
          # @param stdout [String] Linter stdout
          # @param stderr [String] Linter stderr
          # @param exit_status [Integer] Process exit status
          # @return [Hash] Parsed result
          def parse_error_output(stdout, stderr, exit_status:)
            unless stdout.strip.empty?
              begin
                return parse_json_output(stdout, exit_status: exit_status)
              rescue JSON::ParserError
                return parse_text_output(stderr, exit_status: exit_status)
              end
            end

            parse_text_output(stderr, exit_status: exit_status)
          end

          # Parse JSON output from linter (RuboCop-style format)
          # @param output [String] JSON string
          # @param exit_status [Integer, nil] Process exit status
          # @return [Hash] Parsed result
          # @raise [JSON::ParserError] if output is not valid JSON
          def parse_json_output(output, exit_status: nil)
            data = JSON.parse(output)
            errors = []
            warnings = []

            # RuboCop JSON format: {files: [{path, offenses: [...]}]}
            if data.is_a?(Hash) && data.key?("files")
              data["files"].each do |file_data|
                file_path = file_data["path"] || "unknown"
                offenses = file_data["offenses"] || []

                offenses.each do |offense|
                  item = build_offense_item(offense, file_path)
                  if offense["severity"] == "error" || offense["severity"] == "fatal"
                    errors << item
                  else
                    warnings << item
                  end
                end
              end
            # Fallback: direct array format
            elsif data.is_a?(Array)
              data.each do |offense|
                item = build_offense_item(offense)
                if offense["severity"] == "error" || offense["severity"] == "fatal"
                  errors << item
                else
                  warnings << item
                end
              end
            end

            success = exit_status ? exit_status.zero? : errors.empty?

            {
              success: success,
              errors: errors,
              warnings: warnings
            }
          end

          # Parse text output (fallback for non-JSON output)
          # @param output [String] Text output
          # @param exit_status [Integer, nil] Process exit status
          # @return [Hash] Parsed result
          def parse_text_output(output, exit_status: nil)
            errors = []
            warnings = []

            output.each_line do |line|
              # Format: file:line:column: severity: message
              next unless line.match?(/^.+:\d+:\d+:/)

              parts = line.split(":", 5)
              next if parts.size < 5

              item = {
                file: parts[0],
                line: parts[1].to_i,
                column: parts[2].to_i,
                message: parts[4].strip
              }

              if error_severity?(parts[3], line)
                errors << item
              else
                warnings << item
              end
            end

            success = exit_status ? exit_status.zero? : errors.empty?

            # Add fallback error if non-zero exit but no offenses parsed
            if !success && errors.empty? && warnings.empty? && !output.strip.empty?
              errors << {message: "#{tool_name} failed: #{output.strip.lines.first&.strip || output.strip}"}
            end

            {
              success: success,
              errors: errors,
              warnings: warnings
            }
          end

          # Build offense item from linter offense
          # @param offense [Hash] Offense data
          # @param file_path [String] File path
          # @return [Hash] Offense item
          def build_offense_item(offense, file_path = nil)
            path = file_path || offense.dig("location", "path") || "unknown"
            location = offense["location"] || {}

            {
              file: path,
              line: location["line"] || 0,
              column: location["column"] || 0,
              message: "#{offense["cop_name"]}: #{offense["message"]}"
            }
          end

          protected

          # Check if a command is available on the system
          # @param cmd [String] Command name
          # @return [Boolean] True if command exists
          def system_has_command?(cmd)
            # Cross-platform: use system with redirect to null
            system("#{cmd} --version > /dev/null 2>&1")
          end

          # Check if severity indicates an error
          # @param severity_field [String] The severity field from text output
          # @param line [String] Full line for context
          # @return [Boolean] True if error severity
          def error_severity?(severity_field, line)
            severity = severity_field.strip.upcase
            # RuboCop: E/F = error, C/W = warning
            severity == "E" || severity == "F" || line.include?("error") || line.include?("Error")
          end

          # Subclass interface methods - must be implemented
          def tool_name
            raise NotImplementedError, "Subclass must implement tool_name"
          end

          def build_command(_paths, fix:, config_path:)
            raise NotImplementedError, "Subclass must implement build_command"
          end

          def unavailable_result
            raise NotImplementedError, "Subclass must implement unavailable_result"
          end
        end
      end
    end
  end
end
