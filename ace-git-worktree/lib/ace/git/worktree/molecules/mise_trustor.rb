# frozen_string_literal: true

require 'timeout'

module Ace
  module Git
    module Worktree
      module Molecules
        # Handles mise environment trust
        class MiseTrustor
          DEFAULT_TIMEOUT = 5 # seconds

          # Trust mise.toml in a directory
          # @param directory [String] Directory containing mise.toml
          # @param options [Hash] Options
          # @return [Hash] Result with :success, :output, :error
          def self.trust(directory, options = {})
            return error_result("Directory cannot be empty") if directory.nil? || directory.empty?

            # Check if mise.toml exists in the directory
            mise_file = File.join(directory, "mise.toml")
            unless File.exist?(mise_file)
              # Not an error - just skip if no mise.toml
              return {
                success: true,
                skipped: true,
                output: "No mise.toml found in #{directory}"
              }
            end

            # Check if mise command is available
            unless mise_available?
              return {
                success: true,
                skipped: true,
                output: "mise command not found - skipping trust"
              }
            end

            # Execute mise trust
            timeout = options[:timeout] || DEFAULT_TIMEOUT
            result = execute_mise_trust(directory, timeout)

            if result[:success]
              {
                success: true,
                output: result[:output]
              }
            else
              # Mise trust failure is non-fatal
              {
                success: true,
                warning: true,
                output: "Warning: mise trust failed: #{result[:error]}"
              }
            end
          end

          # Check if mise is available
          # @return [Boolean] true if mise command exists
          def self.mise_available?
            result = execute_command(["mise", "--version"])
            result[:success]
          end

          # List trusted directories
          # @return [Array<String>] List of trusted directory paths
          def self.list_trusted
            return [] unless mise_available?

            result = execute_command(["mise", "trust", "--list"])
            return [] unless result[:success]

            result[:output].lines.map(&:strip).reject(&:empty?)
          end

          private

          def self.error_result(message)
            {
              success: false,
              error: message
            }
          end

          def self.execute_mise_trust(directory, timeout_seconds)
            # Change to the directory and run mise trust
            Dir.chdir(directory) do
              execute_command(["mise", "trust"], timeout: timeout_seconds)
            end
          rescue => e
            error_result("Failed to change directory or execute mise: #{e.message}")
          end

          def self.execute_command(cmd_array, timeout: DEFAULT_TIMEOUT)
            require 'open3'

            stdout, stderr, status = nil

            begin
              Timeout.timeout(timeout) do
                stdout, stderr, status = Open3.capture3(*cmd_array)
              end
            rescue Timeout::Error
              return error_result("Command timed out after #{timeout} seconds")
            rescue Errno::ENOENT
              return error_result("Command not found: #{cmd_array.first}")
            rescue => e
              return error_result("Command failed: #{e.message}")
            end

            {
              success: status.success?,
              output: stdout,
              error: stderr,
              exit_code: status.exitstatus
            }
          end
        end
      end
    end
  end
end