# frozen_string_literal: true

require "open3"
require "json"
require "timeout"

module Ace
  module Herdr
    module Molecules
      # Executes herdr CLI commands via argv arrays (ADR-031) and classifies
      # failures into typed executor errors from herdr's machine-readable
      # JSON error codes. The single seam between ace-herdr and the herdr
      # binary; tests substitute this class.
      class HerdrExecutor
        DEFAULT_BINARY = "herdr"
        WAKE_OUTPUT_LIMIT = 65_536
        DEFAULT_PROBE_TIMEOUT_S = 60

        def initialize(binary: DEFAULT_BINARY)
          @binary = binary
        end

        # Probe the agent living in a pane (raises AgentNotFoundError when none)
        def agent_get(pane)
          run!([@binary, "agent", "get", pane])
        end

        # Structured live pane observation for the inbox: the caller holds
        # its per-event lock across this probe, so a stalled herdr child is
        # killed at the deadline and the timeout classifies as a retryable
        # pre-submission failure.
        def pane_get_bounded(pane, timeout_s: DEFAULT_PROBE_TIMEOUT_S)
          result = BoundedProcess.call([@binary, "pane", "get", pane], stdin_data: "",
            timeout_s: timeout_s, output_limit: WAKE_OUTPUT_LIMIT)
          execution = ExecutionResult.new(
            stdout: result.stdout.strip, stderr: result.stderr.strip,
            success: result.status.success?, exit_code: result.status.exitstatus || -1
          )
          raise classify(execution, [@binary, "pane", "get", pane]) unless execution.success?

          execution
        rescue Timeout::Error
          raise AgentNotReadyError, "pane probe timed out after #{timeout_s}s"
        rescue BoundedProcess::PostLaunchError => e
          raise AgentNotReadyError, "pane probe failed after launch: #{e.message}"
        rescue SystemCallError
          raise ExecutorUnavailableError, "herdr CLI not found or not executable: #{@binary}"
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

        # A bounded, payload-free wake. The child deadline is managed by
        # BoundedProcess (process-group kill), so a stalled process cannot
        # keep the inbox event lock through Open3.capture3 cleanup.
        def agent_prompt_bounded(pane:, text:, timeout_ms:)
          cmd = [@binary, "agent", "prompt", pane, text]
          result = BoundedProcess.call(cmd, stdin_data: "",
            timeout_s: timeout_ms / 1000.0, output_limit: WAKE_OUTPUT_LIMIT)
          execution = ExecutionResult.new(
            stdout: result.stdout.strip, stderr: result.stderr.strip,
            success: result.status.success?, exit_code: result.status.exitstatus || -1
          )
          unless execution.success?
            error = classify(execution, cmd)
            if result.oversized && error.is_a?(CommandError)
              raise CommandError, "herdr wake output exceeded #{WAKE_OUTPUT_LIMIT} bytes (exit #{execution.exit_code})"
            end
            raise error
          end

          execution
        rescue Timeout::Error
          raise AgentNotReadyError, "herdr wake timed out after #{timeout_ms}ms"
        rescue BoundedProcess::PostLaunchError => e
          raise AgentNotReadyError, "herdr wake failed after launch: #{e.message}"
        rescue SystemCallError => e
          raise ExecutorUnavailableError, e.message
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

        # Structured live pane observation; callers must verify all identity
        # fields before using a native queue target.
        def pane_get(pane)
          run!([@binary, "pane", "get", pane])
        end

        # Inspect a pane's processes (positive proof of process exit for tidy)
        def pane_process_info(pane)
          run!([@binary, "pane", "process-info", "--pane", pane])
        end

        # Create a tab in a workspace with a label and optional cwd
        def tab_create(workspace_id:, label:, cwd: nil, focus: nil)
          cmd = [@binary, "tab", "create", "--workspace", workspace_id, "--label", label]
          cmd += ["--cwd", cwd] if cwd
          cmd += ["--focus"] if focus
          run!(cmd)
        end

        def tab_get(tab)
          run!([@binary, "tab", "get", tab])
        end

        def tab_focus(tab)
          run!([@binary, "tab", "focus", tab])
        end

        def api_snapshot
          run!([@binary, "api", "snapshot"])
        end

        # --- terminal-control surface (spec 8wq.t.k84) -----------------------

        # List workspaces (tmux sessions analogue)
        def workspace_list
          run!([@binary, "workspace", "list"])
        end

        # List tabs, optionally scoped to a workspace (tmux windows analogue)
        def tab_list(workspace_id: nil)
          cmd = [@binary, "tab", "list"]
          cmd += ["--workspace", workspace_id] if workspace_id
          run!(cmd)
        end

        # List panes, optionally scoped to a workspace
        def pane_list(workspace_id: nil)
          cmd = [@binary, "pane", "list"]
          cmd += ["--workspace", workspace_id] if workspace_id
          run!(cmd)
        end

        # Send literal text to a pane without submitting
        def pane_send_text(pane, text)
          run!([@binary, "pane", "send-text", pane, text])
        end

        # Send named keys to a pane, in order
        def pane_send_keys(pane, keys)
          run!([@binary, "pane", "send-keys", pane, *keys])
        end

        # Send named keys to the agent in a pane, in order
        def agent_send_keys(pane, keys)
          run!([@binary, "agent", "send-keys", pane, *keys])
        end

        # Read pane terminal output as raw text (capture). The raw runner
        # keeps stdout verbatim — no trimming of leading/trailing blank lines
        def pane_read(pane, source: "recent", lines: nil)
          cmd = [@binary, "pane", "read", pane, "--source", source]
          cmd += ["--lines", lines.to_s] if lines
          run_raw(cmd)
        end

        # Wait for pane output containing a literal pattern. herdr checks
        # existing content immediately, then polls; timeout fails closed.
        def pane_wait_output(pane, pattern:, source: "recent", lines: nil, timeout_ms: nil)
          cmd = [@binary, "pane", "wait-output", pane, "--match", pattern, "--source", source]
          cmd += ["--lines", lines.to_s] if lines
          cmd += ["--timeout", timeout_ms.to_s] if timeout_ms
          run!(cmd)
        rescue AgentNotReadyError => e
          raise WaitTimeoutError, e.message
        end

        # Create a workspace with a label and optional cwd/focus
        def workspace_create(label:, cwd: nil, focus: nil)
          cmd = [@binary, "workspace", "create", "--label", label]
          cmd += ["--cwd", cwd] if cwd
          cmd += ["--focus"] if focus
          run!(cmd)
        end

        # Close a tab (used to drop the native initial tab of a created
        # workspace once the preset's declared tabs exist)
        def tab_close(tab_id)
          run!([@binary, "tab", "close", tab_id])
        end

        # Split a pane (direction: right|down); herdr reports the new pane
        def pane_split(pane:, direction:, cwd: nil, ratio: nil, focus: nil)
          cmd = [@binary, "pane", "split", "--pane", pane, "--direction", direction]
          cmd += ["--cwd", cwd] if cwd
          cmd += ["--ratio", ratio.to_s] if ratio
          cmd += ["--focus"] if focus
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

        # Like run!, but stdout is preserved verbatim (no strip) — for
        # commands whose output is content (pane read/capture)
        def run_raw(cmd)
          result = run_raw_stdout(cmd)
          raise classify(result, cmd) unless result.success?

          result
        end

        def run(cmd)
          stdout, stderr, status = Open3.capture3(*cmd)
          ExecutionResult.new(
            stdout: stdout.strip, stderr: stderr.strip,
            success: status.success?, exit_code: status.exitstatus || -1
          )
        rescue SystemCallError
          raise ExecutorUnavailableError, "herdr CLI not found or not executable: #{@binary}"
        end

        def run_raw_stdout(cmd)
          stdout, stderr, status = Open3.capture3(*cmd)
          ExecutionResult.new(
            stdout: stdout, stderr: stderr.strip,
            success: status.success?, exit_code: status.exitstatus || -1
          )
        rescue SystemCallError
          raise ExecutorUnavailableError, "herdr CLI not found or not executable: #{@binary}"
        end

        # Map a failed result to a typed error from herdr's error codes
        # (JSON: {"error":{"code":...,"message":...}}). The native machine
        # code is kept in the message so CLI failures carry it.
        def classify(result, cmd)
          code, message = error_code(result)
          if code
            return classify_code(code, message, result: result, cmd: cmd)
          end

          # No structured code: first nonempty of stderr/stdout — herdr
          # writes some failures (socket errors) to stdout with an empty
          # stderr, and empty strings are truthy in Ruby, so `||` chaining
          # would hide the detail.
          detail = [result.stderr, result.stdout].reject { |value| value.to_s.empty? }.first
          if detail.to_s.match?(/no herdr server is running|cannot connect|connection refused|socket.*unavailable/i)
            return ExecutorUnavailableError.new(detail)
          end

          CommandError.new(
            "herdr command failed (exit #{result.exit_code}): #{cmd.join(" ")} #{detail}".strip
          )
        end

        def classify_code(code, message, result:, cmd:)
          case code
          when "agent_blocked" then AgentBlockedError.new(tag_code(code, message))
          when "agent_prompt_stalled" then AgentNotReadyError.new(tag_code(code, message))
          when "pane_not_found" then PaneNotFoundError.new(tag_code(code, message))
          when "agent_not_found" then AgentNotFoundError.new(tag_code(code, message))
          when "tab_not_found" then TabNotFoundError.new(tag_code(code, message))
          when "workspace_not_found" then WorkspaceNotFoundError.new(tag_code(code, message))
          when "timeout" then ExecutorTimeoutError.new(tag_code(code, message))
          else
            CommandError.new(
              "herdr command failed (exit #{result.exit_code}): #{cmd.join(" ")}: #{tag_code(code, message)}"
            )
          end
        end

        def tag_code(code, message)
          "#{code}: #{message}"
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
