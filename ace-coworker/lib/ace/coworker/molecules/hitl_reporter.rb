# frozen_string_literal: true

require "ace/support/cli/toolchain"

require "open3"
require "json"

module Ace
  module Coworker
    module Molecules
      # Sends the coworker's report through the ace-hitl CLI (subprocess
      # argv contract, ADR-031; injectable runner). ace-hitl owns its files;
      # this molecule never writes HITL state directly.
      class HitlReporter
        DEFAULT_RUNNER = ->(argv, cwd) { Open3.capture3(Ace::Support::Cli::Toolchain.child_environment, *argv, chdir: cwd) }

        Failure = Struct.new(:stage, :message, keyword_init: true)

        def initialize(project_root:, runner: DEFAULT_RUNNER)
          @project_root = project_root
          @runner = runner
        end

        # @param outcome [Models::Outcome]
        # @param cfg [Models::Config]
        # @return [String, Failure] created event id, or Failure when the
        #   ace-hitl create command fails
        # @raise [Error] when ace-hitl is not available at all
        def create(outcome, cfg)
          argv = [hitl_binary, "create", title(outcome, cfg)]
          argv += ["--type", "report", "--result", outcome.result]
          body_lines(outcome, cfg).each { |line| argv += ["--body", line] }
          argv += ["--task", cfg.task, "--assignment", cfg.assignment]
          argv += ["--step", outcome.step.number.to_s] if outcome.step&.number
          argv += ["--step-name", outcome.step.name.to_s] if outcome.step&.name && !outcome.step.name.to_s.empty?
          argv += ["--to", cfg.overseer] unless cfg.overseer.to_s.strip.empty?

          create_event(argv)
        end

        # Creates a report-type event (no reply expected): the planner's
        # readiness report (L4.4) uses this. A report requires a result
        # ("success"/"error") per the ace-hitl CLI contract.
        #
        # @param title [String] event title
        # @param body_lines [Array<String>] report body lines
        # @param task [String] task reference
        # @param result [String] "success" or "error"
        # @param to [String, nil] recipient address
        # @return [String, Failure] created event id, or Failure when the
        #   ace-hitl create command fails
        # @raise [Error] when ace-hitl is not available at all
        def create_report(title:, body_lines:, task:, result:, to: nil)
          argv = [hitl_binary, "create", title]
          argv += ["--type", "report", "--result", result]
          body_lines.each { |line| argv += ["--body", line] }
          argv += ["--task", task]
          argv += ["--to", to] unless to.to_s.strip.empty?

          create_event(argv)
        end

        # Creates a decision-type question event for a preparation conflict.
        #
        # @param title [String] event title
        # @param question_lines [Array<String>] question body lines
        # @param task [String] task reference
        # @param to [String, nil] escalation recipient
        # @return [String, Failure] created event id, or Failure when the
        #   ace-hitl create command fails
        # @raise [Error] when ace-hitl is not available at all
        def create_conflict(title:, question_lines:, task:, to: nil)
          argv = [hitl_binary, "create", title]
          argv += ["--type", "question", "--kind", "decision"]
          question_lines.each { |line| argv += ["--question", line] }
          argv += ["--task", task]
          argv += ["--to", to] unless to.to_s.strip.empty?

          create_event(argv)
        end

        # @return [true, Failure]
        def send_report(event_id)
          out, err, status = run([hitl_binary, "send", event_id])
          return true if status.success?

          message = err.to_s.strip.empty? ? out.to_s.strip : err.to_s.strip
          Failure.new(stage: "send", message: message)
        end

        # @return [Boolean] whether ace-hitl knows the event. Delegates to
        # the ace-hitl CLI so its own configured root_dir (possibly not
        # .ace-local/hitl) decides; this molecule never reconstructs HITL
        # storage paths.
        def event_exists?(event_id)
          _out, _err, status = run([hitl_binary, "show", event_id, "--path"])
          status.success?
        end

        # Verify durable publication through HITL's own recipient resolution and
        # inventory. Archived reports still satisfy publication; this does not
        # claim that the coordinator consumed or accepted the result.
        def publication_matches?(event_id, cfg, result:)
          event_published?(event_id, to: cfg.overseer, task: cfg.task,
            assignment: cfg.assignment, type: "report", result: result)
        end

        def event_published?(event_id, to:, task:, assignment: nil, type:, result: nil)
          raise Error, "publication verification requires a configured recipient" if to.to_s.strip.empty?

          out, _err, status = run([hitl_binary, "observe", "--scope", "current",
            "--owner", to, "--in", "all", "--limit", "2000"])
          raise Error, "HITL publication verification is unavailable; existing report preserved" unless status.success?

          document = JSON.parse(out)
          unless document.is_a?(Hash) && document["schema"] == "ace.hitl.observation/v1" && document["events"].is_a?(Array)
            raise Error, "invalid HITL publication projection; existing report preserved"
          end
          events = document["events"]
          valid = events.all? do |event|
            event.is_a?(Hash) && %w[id type task assignment result].all? { |key| event.key?(key) } &&
              event["id"].is_a?(String) && !event["id"].empty? && %w[report question].include?(event["type"]) &&
              %w[task assignment].all? { |key| event[key].nil? || event[key].is_a?(String) } &&
              [nil, "success", "error"].include?(event["result"])
          end
          raise Error, "invalid HITL publication events; existing report preserved" unless valid

          matches = events.select { |event| event["id"] == event_id }
          raise Error, "ambiguous HITL publication; existing report preserved" if matches.length > 1
          matches.length == 1 && matches.first.values_at("type", "task", "assignment", "result") ==
            [type, task, assignment, result]
        rescue JSON::ParserError
          raise Error, "invalid HITL publication JSON; existing report preserved"
        end

        private

        def create_event(argv)
          out, err, status = run(argv)
          unless status.success?
            message = err.to_s.strip.empty? ? out.to_s.strip : err.to_s.strip
            return Failure.new(stage: "create", message: message)
          end

          out.to_s.match(/HITL event created: ([0-9a-z]{6})/) do |match|
            return match[1]
          end
          Failure.new(stage: "create", message: "could not parse event id from ace-hitl output: #{out.to_s.strip}")
        end

        def run(argv)
          @runner.call(argv, @project_root)
        rescue Errno::ENOENT
          raise Error, "required CLI '#{hitl_binary}' not found; install the ace-hitl gem"
        end

        # Prefer the repo binstub when present (agent shells do not activate
        # mise, so bare ace-* may resolve to stale installed gems).
        def hitl_binary
          return Ace::Support::Cli::Toolchain.executable("ace-hitl") if Ace::Support::Cli::Toolchain.installed?

          binstub = File.join(@project_root, "bin", "ace-hitl")
          File.executable?(binstub) ? binstub : "ace-hitl"
        end

        def title(outcome, cfg)
          outcome.success? ? "Work done - #{cfg.task}/#{cfg.assignment}" : "Assignment failed - #{cfg.task}/#{cfg.assignment}"
        end

        def body_lines(outcome, cfg)
          lines = []
          if outcome.success?
            lines << "Assignment #{cfg.assignment} completed (#{outcome.evidence["progress"]})."
          else
            step = outcome.step
            lines << "failed at step #{step&.number} #{step&.name}: #{outcome.cause}"
            outcome.unfinished_steps.each { |unfinished| lines << "unfinished: #{unfinished}" }
          end
          lines << "record: .ace-tasks/<task>/coworker/#{cfg.assignment}.md"
          lines << "evidence: .ace-local/assign/#{cfg.assignment}/reports/"
          lines
        end
      end
    end
  end
end
