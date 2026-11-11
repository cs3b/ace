# frozen_string_literal: true

module Ace
  module Overseer
    module Organisms
      # Orchestrates `ace-overseer process-reports` (L6.5): interpret each
      # incoming ace-hitl event against the private overseer tree, record
      # the outcome through the existing ace-task update surface, and
      # continue the queue by reusing the existing start gates —
      # WorkOnOrchestrator for a step without a worktree,
      # HandoffOrchestrator for the next role in the SAME worktree.
      # No new state: the processed report ID lives on the step's frontmatter, so
      # a repeated delivery is detected from the recorded result instead
      # of re-running anything, and a question or failed report never
      # advances a step.
      class ReportProcessor
        OUTCOME_STATUSES = %i[success error needs_answer duplicate unmatched].freeze

        def initialize(inbox: nil, task_manager: nil, handoff: nil, work_on: nil, completion_check: nil, owner: "overseer", scope: nil, retire: nil)
          @completion_check = completion_check || Molecules::ReportCompletionCheck.new
          @inbox = inbox || Molecules::HitlInbox.new(owner: owner, scope: scope)
          @task_manager = task_manager || Ace::Task::Organisms::TaskManager.new
          @handoff = handoff
          @work_on = work_on || Organisms::WorkOnOrchestrator.new(task_loader: @task_manager)
          @retire = retire || Molecules::CoworkerLauncher.new.method(:retire)
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

          if verdict[:status] == :success || (verdict[:status] == :duplicate && verdict[:recorded_result] == "success")
            refusal = @completion_check.call(event: event,
              manager: @task_manager.show(verdict[:manager_ref]), step: @task_manager.show(verdict[:step_ref]))
            verdict = {status: :unmatched, reason: refusal} if refusal
          end

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
        # without a recorded success never continues work, but retries any
        # incomplete executor cleanup. A dry run changes nothing.
        def resume_duplicate_continuation(verdict, event, dry_run:, progress:)
          unless dry_run
            retirement = retire_executor(verdict, event)
            return outcome(verdict, event, retirement, retirement[:reason]) if retirement
          end
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
          retirement = retire_executor(verdict, event)
          return outcome(verdict, event, retirement, retirement[:reason]) if retirement

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

          if next_step.metadata["role"] == "confirm-start"
            return {action: "coordinator", step_ref: next_step.id.to_s,
                    reason: "confirm project first turn and active eyes through the standard start operation; keep this step and manager open until proven"}
          end

          begin
            if family_worktree(manager)
              project_root = manager.metadata["project_root"].to_s
              result = if @handoff
                @handoff.call(task_ref: manager.metadata["project_task"].to_s)
              else
                Dir.chdir(project_root.empty? ? Dir.pwd : project_root) do
                  Organisms::HandoffOrchestrator.new.call(task_ref: manager.metadata["project_task"].to_s,
                    runtime: Ace::Support::Cli::Toolchain.installed? ? "herdr" : nil)
                end
              end
              record_allocation(next_step, result) if result[:execution]
              {action: "handoff", step_ref: next_step.id.to_s,
               next: result[:next], status: result[:status], worktree_path: result[:worktree_path],
               execution: result[:execution], start_command: start_command_of(result[:next])}
            else
              result = @work_on.call(task_ref: next_step.id.to_s)
              record_allocation(next_step, result) if result[:execution]
              {action: "work-on", step_ref: next_step.id.to_s,
               assignment_id: result[:assignment_id], worktree_path: result[:worktree_path],
               assignment_created: result.fetch(:assignment_created, true)}
            end
          rescue Ace::Overseer::Error => e
            progress.call("Continuation blocked: #{e.message}")
            {action: "blocked", step_ref: next_step.id.to_s, reason: e.message}
          end
        end

        def retire_executor(verdict, event)
          assignment = event["assignment"].to_s
          return if assignment.empty?
          step = @task_manager.show(verdict[:step_ref])
          manager = @task_manager.show(verdict[:manager_ref])
          root = step&.metadata&.fetch("worktree", nil) || (manager && family_worktree(manager))
          return if root.to_s.empty?
          @retire.call(worktree_path: File.expand_path(root), assignment: assignment)
          nil
        rescue Ace::Overseer::Error, Ace::Herdr::ExecutorError, Ace::Coworker::Error => e
          {action: "blocked", reason: "report recorded; executor retirement failed: #{e.message}"}
        end

        def record_allocation(step, result)
          execution = result.fetch(:execution)
          unless @task_manager.update(step.id, set: {"assignment" => execution.fetch("assignment"),
              "worktree" => result.fetch(:worktree_path), "terminal" => execution.fetch("terminal_id"),
              "role" => execution.fetch("role")})
            raise Ace::Overseer::Error, "executor started but allocation could not be recorded; reconcile before another start"
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

        # Report an actual launch only when the handoff returned its binding.
        # A prepared leg alone is not execution evidence.
        def continuation_description(continuation)
          case continuation[:action]
          when "handoff"
            if continuation[:status] == "sequence_complete"
              "sequence complete - the worktree has no next role; pending coordination steps still require acceptance before closing the managing task"
            elsif continuation[:execution]
              "executor #{continuation[:execution]['agent']} started; end the turn and await its report"
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
          when "coordinator" then "coordinator action for #{continuation[:step_ref]}: #{continuation[:reason]}"
          when "blocked" then "continuation blocked: #{continuation[:reason]}"
          when "none" then continuation[:reason]
          end
        end
      end
    end
  end
end
