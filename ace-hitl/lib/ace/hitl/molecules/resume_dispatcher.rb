# frozen_string_literal: true

require "open3"
require "shellwords"

module Ace
  module Hitl
    module Molecules
      # Dispatches resume signals to waiting agents.
      # Primary path is provider/session resume; fallback path executes resume instructions.
      class ResumeDispatcher
        Result = Struct.new(:success?, :mode, :details, :error, keyword_init: true)

        def dispatch(event:, answer:, now: Time.now.utc)
          session_id = event.metadata["requester_session_id"].to_s.strip
          provider = event.metadata["requester_provider"].to_s.strip
          instructions = event.metadata["resume_instructions"].to_s.strip

          payload = build_payload(event: event, answer: answer, now: now)

          if !session_id.empty? && !provider.empty?
            resumed = dispatch_to_session(provider: provider, session_id: session_id, payload: payload)
            return resumed if resumed.success?
          end

          return failed("No resume instructions available") if instructions.empty?

          shell = run_shell(instructions)
          return ok(mode: "command", details: "resume_instructions") if shell[:status].success?

          failed("Resume command failed: #{stderr_or_stdout(shell)}")
        rescue StandardError => e
          failed("Resume dispatch exception: #{e.class}: #{e.message}")
        end

        private

        def build_payload(event:, answer:, now:)
          lines = []
          lines << "HITL event answer received."
          lines << "id: #{event.id}"
          assignment = event.metadata["assignment"]
          step = event.metadata["step"]
          lines << "assignment: #{assignment}" if assignment
          lines << "step: #{step}" if step
          lines << "answered_at: #{now.iso8601}"
          lines << ""
          lines << "answer:"
          lines << answer.to_s
          lines << ""
          resume = event.metadata["resume_instructions"].to_s
          lines << "resume_instructions: #{resume}" unless resume.strip.empty?
          lines.join("\n")
        end

        def dispatch_to_session(provider:, session_id:, payload:)
          case provider
          when /\Acodex\z/i
            cmd = ["codex", "exec", "resume", session_id]
            io = run_command(cmd, stdin_data: payload)
            return ok(mode: "session", details: "codex:#{session_id}") if io[:status].success?
            failed("Codex session resume failed: #{stderr_or_stdout(io)}")
          when /\Aclaude\z/i
            cmd = ["claude", "-p", "--resume", session_id]
            io = run_command(cmd, stdin_data: payload)
            return ok(mode: "session", details: "claude:#{session_id}") if io[:status].success?
            failed("Claude session resume failed: #{stderr_or_stdout(io)}")
          else
            failed("Unsupported resume provider '#{provider}'")
          end
        end

        def run_shell(command)
          stdout, stderr, status = Open3.capture3("bash", "-lc", command.to_s)
          {stdout: stdout, stderr: stderr, status: status}
        end

        def run_command(cmd, stdin_data: nil)
          stdout, stderr, status = Open3.capture3(*cmd, stdin_data: stdin_data.to_s)
          {stdout: stdout, stderr: stderr, status: status}
        end

        def stderr_or_stdout(io)
          out = io[:stderr].to_s.strip
          out = io[:stdout].to_s.strip if out.empty?
          out.empty? ? "(no output)" : out
        end

        def ok(mode:, details:)
          Result.new(success?: true, mode: mode, details: details, error: nil)
        end

        def failed(error)
          Result.new(success?: false, mode: nil, details: nil, error: error)
        end
      end
    end
  end
end
