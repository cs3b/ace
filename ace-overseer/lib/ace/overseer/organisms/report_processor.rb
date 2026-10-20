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
            resume_duplicate_continuation(verdict, event, dry_run: dry_run, progress: progress)
          when :needs_answer
            progress.call("Event #{event['id']}: question on #{verdict[:step_ref]} - answer via ace-hitl update #{event['id']} --answer")
            outcome(verdict, event, nil,
              "question for step #{verdict[:step_ref]}; answer it with `ace-hitl update #{event['id']} --answer ...`; " \
              "not treated as success")
          else
            apply_report(verdict, event, dry_run: dry_run, progress: progress)
          end
        end

        # A duplicate whose recorded result is success does NOT prove the
        # queue actually continued: the report result was persisted BEFORE
        # dispatch, so a handoff failure (or a process death between the
        # write and the dispatch) leaves a recorded report whose
        # continuation never ran — and a later run must not let the
        # recorded duplicate suppress that continuation forever. Recovery
        # re-checks continuation from the CURRENT task/assignment reality
        # through the same gates; duplicate starts stay impossible because
        # the gates read real allocation state (work-on reuses an active
        # assignment, handoff refuses a busy worktree). A duplicate
        # without a recorded success (or a dry run) changes nothing.
        def resume_duplicate_continuation(verdict, event, dry_run:, progress:)
          unless verdict[:recorded_result] == Atoms::ReportInterpretation::SUCCESS_RESULT && !dry_run
            return outcome(verdict, event, nil,
              "report #{event['id']} already recorded on #{verdict[:step_ref]} (result: #{verdict[:recorded_result]}); " \
              "nothing re-run")
          end

          continuation = continue_queue(verdict[:manager_ref], progress: progress)
          outcome(verdict, event, continuation,
            "report #{event['id']} already recorded on #{verdict[:step_ref]} (result: #{verdict[:recorded_result]}); " \
            "continuation re-checked - #{continuation_description(continuation)}")
        end

        # A report (success or error): record through the existing
        # ace-task update surface FIRST, then continue only on success.
        def apply_report(verdict, event, dry_run:, progress:)
          if dry_run
            message = "dry-run: would record #{verdict[:status]} on #{verdict[:step_ref]} (report #{event['id']})"
            progress.call("Event #{event['id']}: #{message}")
            return outcome(verdict, event, nil, message)
          end

          unless @task_manager.update(verdict[:step_ref], set: verdict[:set])
            reason = "task #{verdict[:step_ref]} no longer resolves - moved or archived since the event matched"
            message = "report #{event['id']} not recorded: #{reason}; kept in ace-hitl for clarification"
            progress.call("Event #{event['id']}: #{message}")
            return outcome(verdict, event, {action: "blocked", reason: reason}, message)
          end
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
               next: result[:next], status: result[:status], worktree_path: result[:worktree_path],
               start_command: start_command_of(result[:next])}
            else
              result = @work_on.call(task_ref: next_step.id.to_s)
              {action: "work-on", step_ref: next_step.id.to_s,
               assignment_id: result[:assignment_id], worktree_path: result[:worktree_path],
               assignment_created: result.fetch(:assignment_created, true)}
            end
          rescue Ace::Overseer::Error => e
            progress.call("Continuation blocked: #{e.message}")
            {action: "blocked", step_ref: next_step.id.to_s, reason: e.message}
          end
        end

        # The actionable start command for the next handoff leg — exactly
        # what the Handoff CLI prints, never a rebuilt guess. nil when the
        # leg carries no probed start config (the handoff gate refuses to
        # guess, and so does this description).
        def start_command_of(next_leg)
          config = next_leg.is_a?(Hash) ? next_leg["start_config"].to_s : ""
          config.empty? ? nil : Ace::Support::Cli::Toolchain.shell_command("ace-coworker", "start", "--config", config)
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

        # Per queue.wf.md section 4 the handoff gate only ENSURES the next
        # role's window in the worktree; the overseer AGENT runs the
        # printed start command. The description therefore carries the
        # command instead of asserting the role already started.
        def continuation_description(continuation)
          case continuation[:action]
          when "handoff"
            if continuation[:status] == "sequence_complete"
              "sequence complete - the worktree has no next role; close the managing task per the queue workflow"
            elsif continuation[:start_command]
              "window ensured in #{continuation[:worktree_path]} for the next role " \
                "(#{continuation.dig(:next, 'role')}); run there: #{continuation[:start_command]}"
            else
              "window ensured in #{continuation[:worktree_path]} for the next role " \
                "(#{continuation.dig(:next, 'role')}); no probed start config - run ace-overseer handoff to see it"
            end
          when "work-on"
            if continuation[:assignment_created] == false
              "next step #{continuation[:step_ref]} already has an active assignment in #{continuation[:worktree_path]}"
            else
              "next step #{continuation[:step_ref]} started via work-on"
            end
          when "blocked" then "continuation blocked: #{continuation[:reason]}"
          when "none" then continuation[:reason]
          end
        end
      end
    end
  end
end
