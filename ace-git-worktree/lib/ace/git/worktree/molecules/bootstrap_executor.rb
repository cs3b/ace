# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Git
    module Worktree
      module Molecules
        # Molecule for executing worktree preparation bootstrap phase
        class BootstrapExecutor
          # Initialize BootstrapExecutor
          #
          # @param project_root [String] Project root path
          # @param worktree_path [String] Target worktree path
          # @param bootstrap_config [Hash] Resolved bootstrap policy configuration
          # @param no_bootstrap [Boolean] Whether bootstrap was explicitly skipped
          def initialize(project_root: Dir.pwd, worktree_path: nil, bootstrap_config: nil, no_bootstrap: false)
            @project_root = project_root
            @worktree_path = worktree_path || project_root
            @config = bootstrap_config || {}
            @no_bootstrap = no_bootstrap
          end

          # Execute or skip bootstrap phase
          #
          # @return [Hash] Phase ledger item
          def run
            policy = @config["policy"] || "required"

            if @no_bootstrap
              return {
                phase: "bootstrap",
                policy: policy,
                status: "skipped",
                command: nil,
                duration: 0.0
              }
            end

            command = @config["command"]
            if command.nil? || command.to_s.strip.empty?
              return {
                phase: "bootstrap",
                policy: policy,
                status: "not_configured",
                command: nil,
                duration: 0.0
              }
            end

            working_dir = @config["working_dir"] || "."
            target_dir = File.expand_path(working_dir, @worktree_path)
            timeout_sec = (@config["timeout"] || 60).to_i
            env_vars = (@config["env"] || {}).transform_keys(&:to_s).transform_values(&:to_s)

            start_time = Time.now
            output = ""
            exit_code = 1

            begin
              Timeout.timeout(timeout_sec) do
                stdout, stderr, proc_status = Open3.capture3(env_vars, command, chdir: target_dir)
                output = "#{stdout}\n#{stderr}".strip
                exit_code = proc_status.exitstatus || (proc_status.success? ? 0 : 1)
              end
              if exit_code == 0
                status = "succeeded"
              else
                status = (policy == "advisory") ? "advisory_failed" : "required_failed"
              end
            rescue Timeout::Error
              output = "Execution timed out after #{timeout_sec}s"
              exit_code = 124
              status = (policy == "advisory") ? "advisory_failed" : "required_failed"
            rescue => e
              output = "Execution error: #{e.message}"
              exit_code = 1
              status = (policy == "advisory") ? "advisory_failed" : "required_failed"
            end

            duration = (Time.now - start_time).round(3)

            {
              phase: "bootstrap",
              policy: policy,
              status: status,
              command: command,
              working_dir: working_dir,
              exit_code: exit_code,
              output: output,
              duration: duration
            }
          end
        end
      end
    end
  end
end
