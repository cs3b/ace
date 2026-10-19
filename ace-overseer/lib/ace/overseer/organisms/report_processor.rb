# frozen_string_literal: true

module Ace
  module Overseer
    module Organisms
      # Orchestrates `ace-overseer process-reports` (L6.5): interpret each
      # incoming ace-hitl event against the private overseer tree, record
      # the outcome through the existing ace-task update surface, and
      # continue the queue by reusing the existing start gates —
      # WorkOnOrchestrator for a step without a worktree,
      # HandoffOrchestrator for the next role in the SAME worktree. No new
      # state: the processed report ID lives on the step's frontmatter, so
      # a repeated delivery is detected from the recorded result instead
      # of re-running anything, and a question or failed report never
      # advances a step.
      class ReportProcessor
        OUTCOME_STATUSES = %i[success error needs_answer duplicate unmatched].freeze

        def initialize(inbox: nil, task_manager: nil, handoff: nil, work_on: nil)
          @inbox = inbox || Molecules::HitlInbox.new
          @task_manager = task_manager || Ace::Task::Organisms::TaskManager.new
          @handoff = handoff || Organisms::HandoffOrchestrator.new(task_loader: @task_manager)
          @work_on = work_on || Organisms::WorkOnOrchestrator.new(task_loader: @task_manager)
        end

        # @param dry_run [Boolean] interpret only — no task writes, no
        #   continuation
        # @param on_progress [#call] progress sink
        # @return [Hash] {dry_run:, outcomes: [...], counts: {...}}
        def call(dry_run: false, on_progress: nil)
          progress = on_progress || ->(_msg) {}
          events = @inbox.incoming_events
          progress.call("Incoming ace-hitl events: #{events.size}")

          outcomes = events.map do |event|
            process_event(event, dry_run: dry_run, progress: progress)
          end

          counts = OUTCOME_STATUSES.to_h { |status| [status, outcomes.count { |o| o[:status] == status }] }
          {dry_run: dry_run, outcomes: outcomes, counts: counts}
        end

        private

        def process_event(event, dry_run:, progress:)
          verdict = Atoms::ReportInterpretation.evaluate(event: event, managers: private_managers)

          case verdict[:status]
          when :unmatched
            progress.call("Event #{event['id']}: #{verdict[:reason]}")
            outcome(verdict, event, nil, "kept for clarification - not treated as success")
          when :duplicate
            progress.call("Event #{event['id']}: already processed (result: #{verdict[:recorded_result]}) - re-delivery is not re-execution")
            outcome(verdict, event, nil,
              "report #{event['id']} already recorded on #{verdict[:step_ref]} (result: #{verdict[:recorded_result]}); " \
              "nothing re-run")
          when :needs_answer
            progress.call("Event #{event['id']}: question on #{verdict[:step_ref]} - answer via ace-hitl update #{event['id']} --answer")
            outcome(verdict, event, nil,
              "question for step #{verdict[:step_ref]}; answer it with `ace-hitl update #{event['id']} --answer ...`; " \
              "not treated as success")
          else
            apply_report(verdict, event, dry_run: dry_run, progress: progress)
          end
        end

        # A report (success or error): record through the existing
        # ace-task update surface FIRST, then continue only on success.
        def apply_report(verdict, event, dry_run:, progress:)
          if dry_run
            message = "dry-run: would record #{verdict[:status]} on #{verdict[:step_ref]} (report #{event['id']})"
            progress.call("Event #{event['id']}: #{message}")
            return outcome(verdict, event, nil, message)
          end

          @task_manager.update(verdict[:step_ref], set: verdict[:set])
          progress.call("Event #{event['id']}: recorded #{verdict[:status]} on #{verdict[:step_ref]}")

          if verdict[:status] == :error
            message = "step #{verdict[:step_ref]} kept open; report #{event['id']} (result #{verdict.dig(:set, Atoms::ReportInterpretation::REPORT_RESULT_KEY)}) " \
              "stays in ace-hitl for clarification - not treated as success"
            progress.call("Event #{event['id']}: #{message}")
            return outcome(verdict, event, nil, message)
          end

          continuation = continue_queue(verdict[:manager_ref], progress: progress)
          outcome(verdict, event, continuation,
            "step #{verdict[:step_ref]} done (report #{event['id']}); #{continuation_description(continuation)}")
        end

        # Continue with the next unblocked step of the same managing
        # task: the next role in the SAME worktree via the handoff gate,
        # or a step without a worktree via the work-on gate. Refusals
        # surface as a blocked continuation with reasons — never as
        # success and never launching a second executor.
        def continue_queue(manager_ref, progress:)
          manager = @task_manager.show(manager_ref)
          return {action: "none", reason: "managing task #{manager_ref} not found"} unless manager

          next_step = next_unblocked_step(manager)
          if next_step.nil?
            active = active_steps(manager)
            reason = if active.empty?
              "every step of #{manager_ref} is terminal; close the managing task per the queue workflow"
            else
              "no unblocked step in #{manager_ref}: #{active.map { |s| blocking_summary(s) }.join(' | ')}"
            end
            return {action: "none", reason: reason}
          end

          begin
            if family_worktree(manager)
              result = @handoff.call(task_ref: manager.metadata["project_task"].to_s)
              {action: "handoff", step_ref: next_step.id.to_s,
               next: result[:next], status: result[:status], worktree_path: result[:worktree_path]}
            else
              result = @work_on.call(task_ref: next_step.id.to_s)
              {action: "work-on", step_ref: next_step.id.to_s,
               assignment_id: result[:assignment_id], worktree_path: result[:worktree_path]}
            end
          rescue Ace::Overseer::Error => e
            progress.call("Continuation blocked: #{e.message}")
            {action: "blocked", step_ref: next_step.id.to_s, reason: e.message}
          end
        end

        # First non-terminal step (id order) whose recorded dependencies
        # are satisfied — the same readiness atom the work-on gate uses.
        def next_unblocked_step(manager)
          lookup = ->(ref) { @task_manager.show(ref) }

          active_steps(manager).find do |step|
            Atoms::DependencyReadiness.check(step, lookup: lookup)[:status] == :ready
          end
        end

        def active_steps(manager)
          steps = manager.respond_to?(:subtasks) ? Array(manager.subtasks) : []
          steps.reject { |step| Ace::Task::Atoms::TaskValidationRules.terminal_status?(step.status.to_s) }
        end

        def blocking_summary(step)
          lookup = ->(ref) { @task_manager.show(ref) }
          result = Atoms::DependencyReadiness.check(step, lookup: lookup)
          result[:status] == :ready ? "#{step.id}: ready" : "#{step.id}: #{result[:reasons].join('; ')}"
        end

        # A worktree recorded anywhere in the manager's family means the
        # sequence continues in THAT worktree (one active executor per
        # worktree) — the handoff gate owns the next role there.
        def family_worktree(manager)
          ([manager] + Array(manager.subtasks)).each do |task|
            worktree = task.metadata["worktree"] if task.respond_to?(:metadata)
            return worktree if worktree.to_s != ""
          end
          nil
        end

        def private_managers
          @task_manager.list(in_folder: "_overseer")
        end

        def outcome(verdict, event, continuation, message)
          {
            event_id: event["id"],
            status: verdict[:status],
            manager_ref: verdict[:manager_ref],
            step_ref: verdict[:step_ref],
            continuation: continuation,
            message: message
          }
        end

        def continuation_description(continuation)
          case continuation[:action]
          when "handoff" then "worktree handed to the next role (#{continuation.dig(:next, 'role')})"
          when "work-on" then "next step #{continuation[:step_ref]} started via work-on"
          when "blocked" then "continuation blocked: #{continuation[:reason]}"
          when "none" then continuation[:reason]
          end
        end
      end
    end
  end
end
