# frozen_string_literal: true

require "open3"

module Ace
  module Coworker
    module Molecules
      # Sends the coworker's report through the ace-hitl CLI (subprocess
      # argv contract, ADR-031; injectable runner). ace-hitl owns its files;
      # this molecule never writes HITL state directly.
      class HitlReporter
        DEFAULT_RUNNER = ->(argv, cwd) { Open3.capture3(*argv, chdir: cwd) }

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
