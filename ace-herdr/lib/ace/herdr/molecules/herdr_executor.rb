# frozen_string_literal: true

require "open3"
require "json"

module Ace
  module Herdr
    module Molecules
      # Executes herdr CLI commands via argv arrays (ADR-031) and classifies
      # failures into typed executor errors from herdr's machine-readable
      # JSON error codes. The single seam between ace-herdr and the herdr
      # binary; tests substitute this class.
      class HerdrExecutor
        DEFAULT_BINARY = "herdr"

        def initialize(binary: DEFAULT_BINARY)
          @binary = binary
        end

        # Probe the agent living in a pane (raises AgentNotFoundError when none)
        def agent_get(pane)
          run!([@binary, "agent", "get", pane])
        end

        # Start an agent in a pane at an interactive shell prompt.
        # Success means the agent was detected and is ready for input.
        def agent_start(name:, kind:, pane:, timeout_ms:)
          run!([@binary, "agent", "start", name, "--kind", kind,
            "--pane", pane, "--timeout", timeout_ms.to_s])
        end

        # Submit a prompt to the agent in a pane (push delivery). herdr
        # rejects blocked agents pre-send with agent_blocked.
        def agent_prompt(pane:, text:)
          run!([@binary, "agent", "prompt", pane, text])
        end

        # Wait until the agent reaches one of the requested states
        def agent_wait(pane:, until_states:, timeout_ms:)
          cmd = [@binary, "agent", "wait", pane]
          until_states.each { |state| cmd += ["--until", state] }
          cmd += ["--timeout", timeout_ms.to_s]
          run!(cmd)
        end

        # Run a shell command line in a pane (text + Enter in one call)
        def pane_run(pane, command)
          run!([@binary, "pane", "run", pane, command])
        end

        def pane_rename(pane, label)
          run!([@binary, "pane", "rename", pane, label])
        end

        def pane_close(pane)
          run!([@binary, "pane", "close", pane])
        end

        def pane_current
          run!([@binary, "pane", "current", "--current"])
        end

        # Create a tab in a workspace with a label and optional cwd
        def tab_create(workspace_id:, label:, cwd: nil)
          cmd = [@binary, "tab", "create", "--workspace", workspace_id, "--label", label]
          cmd += ["--cwd", cwd] if cwd
          run!(cmd)
        end

        def available?
          run([@binary, "--version"]).success?
        rescue ExecutorUnavailableError
          false
        end

        private

        def run!(cmd)
          result = run(cmd)
          raise classify(result, cmd) unless result.success?

          result
        end

        def run(cmd)
          stdout, stderr, status = Open3.capture3(*cmd)
          ExecutionResult.new(
            stdout: stdout.strip, stderr: stderr.strip,
            success: status.success?, exit_code: status.exitstatus || -1
          )
        rescue Errno::ENOENT
          raise ExecutorUnavailableError, "herdr CLI not found on PATH: #{@binary}"
        end

        # Map a failed result to a typed error from herdr's error codes
        # (JSON: {"error":{"code":...,"message":...}})
        def classify(result, cmd)
          code, message = error_code(result)
          case code
          when "agent_blocked" then AgentBlockedError.new(message)
          when "agent_prompt_stalled" then AgentNotReadyError.new(message)
          when "pane_not_found" then PaneNotFoundError.new(message)
          when "agent_not_found" then AgentNotFoundError.new(message)
          when "timeout" then AgentNotReadyError.new(message)
          else
            CommandError.new(
              "herdr command failed (exit #{result.exit_code}): #{cmd.join(" ")} " \
              "#{message || result.stderr}".strip
            )
          end
        end

        def error_code(result)
          [result.parsed_json, parse_json(result.stderr)].each do |json|
            next unless json.is_a?(Hash)

            error = json["error"]
            return [error["code"], error["message"]] if error.is_a?(Hash) && error["code"]
          end
          [nil, nil]
        end

        def parse_json(text)
          JSON.parse(text)
        rescue JSON::ParserError
          nil
        end
      end

      # Immutable result of a herdr command execution
      class ExecutionResult
        attr_reader :stdout, :stderr, :exit_code

        def initialize(stdout:, stderr:, success:, exit_code:)
          @stdout = stdout
          @stderr = stderr
          @success = success
          @exit_code = exit_code
        end

        def success?
          @success
        end

        # Parsed stdout JSON or nil
        def parsed_json
          JSON.parse(@stdout)
        rescue JSON::ParserError
          nil
        end
      end
    end
  end
end
