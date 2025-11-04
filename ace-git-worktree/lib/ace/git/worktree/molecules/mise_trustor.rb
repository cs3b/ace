# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Molecules
        # Mise trustor molecule
        #
        # Handles automatic detection and trusting of mise.toml files in worktrees.
        # Provides safe execution of mise trust commands with proper error handling.
        #
        # @example Trust mise configuration in a worktree
        #   trustor = MiseTrustor.new
        #   success = trustor.trust_worktree("/path/to/worktree")
        #
        # @example Check if mise is available
        #   available = trustor.mise_available?
        class MiseTrustor
          # Default timeout for mise commands (shorter than git commands)
          DEFAULT_TIMEOUT = 5

          # Mise configuration file name
          MISE_CONFIG_FILE = "mise.toml"

          # Initialize a new MiseTrustor
          #
          # @param timeout [Integer] Command timeout in seconds
          def initialize(timeout: DEFAULT_TIMEOUT)
            @timeout = timeout
          end

          # Trust mise configuration in a worktree directory
          #
          # @param worktree_path [String] Path to the worktree directory
          # @return [Hash] Result with :success, :message, :error
          #
          # @example
          #   trustor = MiseTrustor.new
          #   result = trustor.trust_worktree("/project/.ace-wt/task.081")
          #   # => { success: true, message: "mise.toml trusted successfully", error: nil }
          def trust_worktree(worktree_path)
            return error_result("Worktree path is required") if worktree_path.nil? || worktree_path.empty?

            begin
              expanded_path = File.expand_path(worktree_path)

              # Check if worktree directory exists
              unless File.directory?(expanded_path)
                return error_result("Worktree directory does not exist: #{expanded_path}")
              end

              # Check if mise is available
              unless mise_available?
                return { success: true, message: "mise not available, skipping trust", error: nil }
              end

              # Look for mise.toml files in the worktree
              mise_files = find_mise_config_files(expanded_path)
              if mise_files.empty?
                return { success: true, message: "No mise.toml files found", error: nil }
              end

              # Trust each mise.toml file
              trusted_files = []
              errors = []

              mise_files.each do |mise_file|
                result = trust_mise_file(mise_file)
                if result[:success]
                  trusted_files << mise_file
                else
                  errors << "#{mise_file}: #{result[:error]}"
                end
              end

              # Build result
              if errors.empty?
                {
                  success: true,
                  message: "Trusted #{trusted_files.length} mise.toml file(s)",
                  trusted_files: trusted_files,
                  error: nil
                }
              else
                {
                  success: false,
                  message: "Failed to trust some mise.toml files",
                  trusted_files: trusted_files,
                  errors: errors,
                  error: errors.join("; ")
                }
              end
            rescue StandardError => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Trust a specific mise.toml file
          #
          # @param mise_file_path [String] Path to the mise.toml file
          # @return [Hash] Result with :success, :message, :error
          #
          # @example
          #   result = trustor.trust_mise_file("/project/.ace-wt/task.081/mise.toml")
          def trust_mise_file(mise_file_path)
            return error_result("Mise file path is required") if mise_file_path.nil? || mise_file_path.empty?

            begin
              expanded_path = File.expand_path(mise_file_path)

              # Check if file exists and is a mise.toml
              unless File.exist?(expanded_path)
                return error_result("Mise file does not exist: #{expanded_path}")
              end

              unless File.basename(expanded_path) == MISE_CONFIG_FILE
                return error_result("Not a mise.toml file: #{expanded_path}")
              end

              # Check if mise is available
              unless mise_available?
                return { success: true, message: "mise not available, skipping trust", error: nil }
              end

              # Execute mise trust command
              result = execute_mise_trust(expanded_path)

              if result[:success]
                {
                  success: true,
                  message: "mise.toml trusted successfully",
                  file: expanded_path,
                  error: nil
                }
              else
                error_result("Failed to trust mise.toml: #{result[:error]}")
              end
            rescue StandardError => e
              error_result("Unexpected error: #{e.message}")
            end
          end

          # Check if mise is available in the system
          #
          # @return [Boolean] true if mise command is available
          #
          # @example
          #   trustor = MiseTrustor.new
          #   if trustor.mise_available?
          #     trustor.trust_worktree("/path/to/worktree")
          #   end
          def mise_available?
            return @mise_available if defined?(@mise_available)

            result = execute_command("mise", "--version", timeout: 5)
            @mise_available = result[:success]
          end

          # Get mise version if available
          #
          # @return [String, nil] Mise version or nil if not available
          #
          # @example
          #   version = trustor.mise_version
          #   puts "Using mise version #{version}"
          def mise_version
            return nil unless mise_available?

            result = execute_command("mise", "--version", timeout: 5)
            return nil unless result[:success]

            # Extract version from output
            match = result[:output].match(/mise\s+([\d.]+)/)
            match ? match[1] : nil
          end

          # Find mise.toml files in a directory and its subdirectories
          #
          # @param directory [String] Directory to search
          # @param recursive [Boolean] Whether to search recursively
          # @return [Array<String>] Array of mise.toml file paths
          #
          # @example
          #   files = trustor.find_mise_config_files("/project/.ace-wt/task.081")
          #   # => ["/project/.ace-wt/task.081/mise.toml"]
          def find_mise_config_files(directory, recursive: false)
            return [] unless File.directory?(directory)

            pattern = recursive ? "**/#{MISE_CONFIG_FILE}" : MISE_CONFIG_FILE
            Dir.glob(File.join(directory, pattern)).select { |file| File.file?(file) }
          end

          # Check if a mise.toml file is already trusted
          #
          # @param mise_file_path [String] Path to the mise.toml file
          # @return [Boolean] true if the file is already trusted
          #
          # @example
          #   trusted = trustor.mise_file_trusted?("/project/.ace-wt/task.081/mise.toml")
          def mise_file_trusted?(mise_file_path)
            return false unless mise_available?
            return false unless File.exist?(mise_file_path)

            # Try to determine if file is trusted
            # This is a heuristic approach since mise doesn't provide a direct command
            # to check trust status

            # Method 1: Check if file is in mise's trusted directory list
            result = execute_command("mise", "trust", "list", timeout: 5)
            if result[:success]
              trusted_paths = result[:output].split("\n").map(&:strip)
              file_dir = File.dirname(File.expand_path(mise_file_path))
              return trusted_paths.any? { |path| File.expand_path(path) == file_dir }
            end

            # Method 2: Try to run a mise command in the directory and see if it works
            # This is less reliable but can work as a fallback
            begin
              file_dir = File.dirname(mise_file_path)
              result = execute_command("mise", "ls", timeout: 5, chdir: file_dir)
              result[:success]
            rescue StandardError
              false
            end
          end

          # Trust mise configuration in multiple worktrees
          #
          # @param worktree_paths [Array<String>] Array of worktree paths
          # @return [Hash] Result with :success, :trusted, :failed, :errors
          #
          # @example
          #   result = trustor.trust_multiple_worktrees(["/path1", "/path2"])
          #   # => { success: true, trusted: ["/path1"], failed: [], errors: {} }
          def trust_multiple_worktrees(worktree_paths)
            return error_result("Worktree paths array is required") if worktree_paths.nil? || worktree_paths.empty?

            results = {
              success: true,
              trusted: [],
              failed: [],
              errors: {}
            }

            Array(worktree_paths).each do |path|
              result = trust_worktree(path)
              if result[:success]
                results[:trusted] << path
              else
                results[:success] = false
                results[:failed] << path
                results[:errors][path] = result[:error]
              end
            end

            results
          end

          private

          # Execute mise trust command
          #
          # @param mise_file_path [String] Path to the mise.toml file
          # @return [Hash] Command result
          def execute_mise_trust(mise_file_path)
            # Get the directory containing the mise.toml file
            file_dir = File.dirname(mise_file_path)

            # Execute mise trust in that directory
            execute_command("mise", "trust", timeout: @timeout, chdir: file_dir)
          end

          # Execute a command safely
          #
          # @param command [String] Command to execute
          # @param args [Array<String>] Command arguments
          # @param timeout [Integer] Command timeout
          # @param chdir [String, nil] Directory to change to before execution
          # @return [Hash] Result with :success, :output, :error, :exit_code
          def execute_command(command, *args, timeout: DEFAULT_TIMEOUT, chdir: nil)
            require "open3"

            full_command = [command] + args

            stdout, stderr, status = if chdir
                                     Dir.chdir(chdir) do
                                       Open3.capture3(*full_command, timeout: timeout)
                                     end
                                   else
                                     Open3.capture3(*full_command, timeout: timeout)
                                   end

            {
              success: status.success?,
              output: stdout.to_s,
              error: stderr.to_s,
              exit_code: status.exitstatus
            }
          rescue Open3::CommandTimeout
            {
              success: false,
              output: "",
              error: "Command timed out after #{timeout} seconds",
              exit_code: 124
            }
          rescue StandardError => e
            {
              success: false,
              output: "",
              error: "Command execution failed: #{e.message}",
              exit_code: 1
            }
          end

          # Create an error result hash
          #
          # @param message [String] Error message
          # @return [Hash] Error result hash
          def error_result(message)
            {
              success: false,
              message: nil,
              error: message
            }
          end
        end
      end
    end
  end
end