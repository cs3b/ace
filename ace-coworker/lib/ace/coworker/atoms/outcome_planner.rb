# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure derivation of the reporting Outcome from an AssignmentSnapshot.
      # ace-assign is the only truth: a success report requires a complete
      # verdict; an error report requires a cause and never claims work done.
      class OutcomePlanner
        # @param snapshot [Models::AssignmentSnapshot]
        # @param explicit_result [String, nil] --result flag
        # @param message [String, nil] explicit cause
        # @param step_evidence [String, nil] failed-step report content
        # @param step_override [String, nil] explicit --step flag
        # @return [Models::Outcome]
        # @raise [Coworker::Error] on refused inputs (false success, missing cause)
        def self.plan(snapshot, explicit_result: nil, message: nil, step_evidence: nil, step_override: nil)
          if explicit_result && !%w[success error].include?(explicit_result)
            raise Error, "invalid --result '#{explicit_result}': expected success or error"
          end

          complete = snapshot.completion_verdict == :complete
          result = explicit_result || (complete ? "success" : "error")

          if result == "success" && !complete
            raise Error,
              "assignment '#{snapshot.id}' is not complete: #{snapshot.incomplete_reasons.join('; ')}; refusing to record work done"
          end

          if result == "error"
            return error_outcome(snapshot, message, step_evidence, step_override)
          end

          success_outcome(snapshot, step_override)
        end

        def self.success_outcome(snapshot, step_override)
          step = if step_override
            Models::Outcome::StepRef.new(number: step_override, name: step_name(snapshot, step_override))
          else
            last = snapshot.steps.last
            Models::Outcome::StepRef.new(number: last&.number, name: last&.name)
          end

          Models::Outcome.new(result: "success", verdict: :complete, step: step,
            unfinished_steps: [],
            evidence: {"progress" => snapshot.progress})
        end

        def self.error_outcome(snapshot, message, step_evidence, step_override)
          failed = snapshot.steps.reverse.find { |s| s.status == "failed" } ||
            snapshot.steps.find { |s| s.status == "active" } ||
            snapshot.steps.find { |s| s.status == "pending" } ||
            snapshot.steps.last
          step = if step_override
            Models::Outcome::StepRef.new(number: step_override, name: step_name(snapshot, step_override))
          else
            Models::Outcome::StepRef.new(number: failed&.number, name: failed&.name)
          end

          cause = message.to_s.strip
          cause = step_evidence.to_s.strip if cause.empty?
          if cause.empty?
            raise Error,
              "error outcome for assignment '#{snapshot.id}' needs a cause: pass --message or provide a failed-step report"
          end

          unfinished = snapshot.steps.reject(&:done?).map { |s| "#{s.number} #{s.name} (#{s.status})" }
          Models::Outcome.new(result: "error", verdict: :incomplete, cause: cause, step: step,
            unfinished_steps: unfinished)
        end

        def self.step_name(snapshot, number)
          snapshot.steps.find { |s| s.number.to_s == number.to_s }&.name
        end
      end
    end
  end
end
