# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Git
    module Worktree
      module Molecules
        # Hook executor molecule
        #
        # Executes after-create hooks defined in YAML configuration.
        # Supports sequential command execution with timeout, error handling,
        # and environment variable interpolation.
        #
        # @example Execute hooks from configuration
        #   executor = HookExecutor.new
        #   hooks = [
        #     { "command" => "mise trust mise.toml", "timeout" => 10 },
        #     { "command" => "echo 'Setup complete'" }
        #   ]
        #   result = executor.execute_hooks(hooks, worktree_path: "/path/to/worktree")
        #
        # @example Hook configuration format
        #   hooks:
        #     after_create:
        #       - command: "mise trust mise*.toml"
        #         working_dir: "."
        #         timeout: 30
        #         continue_on_error: true
        #         env:
        #           CUSTOM_VAR: "value"
        class HookExecutor
          # Fallback timeout for hook execution (seconds)
          # Used only when config is unavailable
          FALLBACK_DEFAULT_TIMEOUT = 30

          # Fallback maximum timeout allowed (seconds)
          # Used only when config is unavailable
          FALLBACK_MAX_TIMEOUT = 300

          # Initialize a new HookExecutor
          def initialize
            @results = []
          end

          # Get default timeout from config or fallback
          # @return [Integer] Default timeout in seconds
          def default_timeout
            Ace::Git::Worktree.hook_timeout
          rescue
            FALLBACK_DEFAULT_TIMEOUT
          end

          # Get maximum timeout from config or fallback
          # @return [Integer] Maximum timeout in seconds
          def max_timeout
            Ace::Git::Worktree.max_timeout
          rescue
            FALLBACK_MAX_TIMEOUT
          end

          # Execute a list of hooks
          #
          # @param hooks [Array<Hash>] Array of hook definitions
          # @param worktree_path [String] Path to the worktree
          # @param task_data [Hash, nil] Optional task data for variable interpolation
          # @param project_root [String] Project root directory (default working dir)
          # @return [Hash] Execution result with :success, :results, :errors
          #
          # @example
          #   result = executor.execute_hooks(
          #     [{ "command" => "mise trust" }],
          #     worktree_path: "/path/to/worktree",
          #     project_root: "/path/to/project",
          #     task_data: { task_id: "081", title: "Fix bug" }
          #   )
          #   # => { success: true, results: [...], errors: [] }
          def execute_hooks(hooks, worktree_path:, project_root: Dir.pwd, task_data: nil)
            return success_result if hooks.nil? || hooks.empty?

            @worktree_path = worktree_path
            @project_root = project_root
            @task_data = task_data || {}
            @results = []
            errors = []

            hooks.each_with_index do |hook_config, index|
              result = execute_hook(hook_config, index)
              @results << result

              unless result[:success]
                errors << "Hook #{index + 1}: #{result[:error]}"
                # Stop execution unless continue_on_error is true
                break unless hook_config["continue_on_error"]
              end
            end

            {
              success: errors.empty?,
              results: @results,
              errors: errors
            }
          rescue => e
            {
              success: false,
              results: @results,
              errors: ["Unexpected error: #{e.message}"]
            }
          end

          private

          # Execute a single hook
          #
          # @param hook_config [Hash] Hook configuration
          # @param index [Integer] Hook index for error messages
          # @return [Hash] Execution result
          def execute_hook(hook_config, index)
            command = hook_config["command"]

            # Validate command
            unless command.is_a?(String) && !command.strip.empty?
              return error_result(
                command: command || "(empty)",
                error: "Command must be a non-empty string"
              )
            end

            # Interpolate variables
            interpolated_command = interpolate_variables(command)

            # Determine working directory
            working_dir = resolve_working_dir(hook_config["working_dir"])

            # Get timeout
            timeout = get_timeout(hook_config["timeout"])

            # Prepare environment
            env = prepare_environment(hook_config["env"])

            # Execute command
            execute_command(
              command: interpolated_command,
              working_dir: working_dir,
              timeout: timeout,
              env: env
            )
          rescue => e
            error_result(
              command: command,
              error: e.message
            )
          end

          # Execute a shell command
          #
          # @param command [String] Command to execute
          # @param working_dir [String] Working directory
          # @param timeout [Integer] Timeout in seconds
          # @param env [Hash] Environment variables
          # @return [Hash] Execution result
          def execute_command(command:, working_dir:, timeout:, env:)
            start_time = Time.now

            # Use Timeout module to enforce timeout
            stdout, stderr, status = Timeout.timeout(timeout) do
              Open3.capture3(
                env,
                command,
                chdir: working_dir
              )
            end

            duration = Time.now - start_time

            if status.success?
              success_result(
                command: command,
                stdout: stdout,
                stderr: stderr,
                duration: duration,
                working_dir: working_dir
              )
            else
              error_result(
                command: command,
                error: "Command failed with exit code #{status.exitstatus}",
                stdout: stdout,
                stderr: stderr,
                duration: duration,
                exit_code: status.exitstatus
              )
            end
          rescue Timeout::Error
            error_result(
              command: command,
              error: "Command timed out after #{timeout} seconds",
              timeout: timeout
            )
          rescue => e
            error_result(
              command: command,
              error: "Execution error: #{e.message}"
            )
          end

          # Interpolate variables in command string
          #
          # @param command [String] Command with {variable} placeholders
          # @return [String] Command with variables replaced
          def interpolate_variables(command)
            result = command.dup

            # Worktree variables
            result.gsub!("{worktree_path}", @worktree_path.to_s)
            result.gsub!("{worktree_dir}", File.basename(@worktree_path.to_s))

            # Task variables (if available)
            if @task_data && !@task_data.empty?
              result.gsub!("{task_id}", extract_task_id(@task_data))
              result.gsub!("{task_title}", @task_data[:title].to_s)
              result.gsub!("{slug}", extract_slug(@task_data))
            end

            result
          end

          # Resolve working directory
          #
          # @param working_dir [String, nil] Configured working directory
          # @return [String] Absolute working directory path
          def resolve_working_dir(working_dir)
            # Default to project root if not specified
            return @project_root if working_dir.nil? || working_dir.empty?

            case working_dir
            when "."
              # "." means current project root
              @project_root
            when "worktree"
              # Special keyword for worktree directory
              @worktree_path
            when /^\//
              # Absolute path
              working_dir
            else
              # Relative path from project root
              File.join(@project_root, working_dir)
            end
          end

          # Get validated timeout value
          #
          # @param timeout [Integer, nil] Configured timeout
          # @return [Integer] Validated timeout in seconds
          def get_timeout(timeout)
            return default_timeout if timeout.nil?

            timeout_int = timeout.to_i
            return default_timeout if timeout_int <= 0

            [timeout_int, max_timeout].min
          end

          # Prepare environment variables
          #
          # @param env_config [Hash, nil] Environment configuration
          # @return [Hash] Environment hash for Open3
          def prepare_environment(env_config)
            env = {}

            # Add project environment variables
            env["ACE_PROJECT_ROOT"] = @project_root

            # Add worktree environment variables
            env["ACE_WORKTREE_PATH"] = @worktree_path
            env["ACE_WORKTREE_DIR"] = File.basename(@worktree_path)

            # Add task environment variables (if available)
            if @task_data && !@task_data.empty?
              env["ACE_TASK_ID"] = extract_task_id(@task_data)
              env["ACE_TASK_TITLE"] = @task_data[:title].to_s
            end

            # Add custom environment variables
            if env_config.is_a?(Hash)
              env_config.each do |key, value|
                env[key.to_s] = value.to_s
              end
            end

            env
          end

          # Extract task ID from task data
          #
          # @param task_data [Hash] Task data
          # @return [String] Task ID
          def extract_task_id(task_data)
            return task_data[:task_number].to_s if task_data[:task_number]

            if task_data[:id]
              match = task_data[:id].match(/task\.(\d+)$/)
              return match[1] if match
            end

            "unknown"
          end

          # Extract slug from task data
          #
          # @param task_data [Hash] Task data
          # @return [String] URL-safe slug
          def extract_slug(task_data)
            return task_data[:slug].to_s if task_data[:slug]

            title = task_data[:title].to_s
            return "" if title.empty?

            # Generate slug from title
            require_relative "../atoms/slug_generator"
            Atoms::SlugGenerator.from_title(title)
          end

          # Create success result
          #
          # @param details [Hash] Additional details
          # @return [Hash] Success result
          def success_result(**details)
            {
              success: true,
              command: details[:command] || "",
              stdout: details[:stdout] || "",
              stderr: details[:stderr] || "",
              duration: details[:duration] || 0,
              working_dir: details[:working_dir]
            }.compact
          end

          # Create error result
          #
          # @param details [Hash] Error details
          # @return [Hash] Error result
          def error_result(**details)
            {
              success: false,
              command: details[:command] || "",
              error: details[:error] || "Unknown error",
              stdout: details[:stdout] || "",
              stderr: details[:stderr] || "",
              duration: details[:duration],
              exit_code: details[:exit_code],
              timeout: details[:timeout]
            }.compact
          end
        end
      end
    end
  end
end
