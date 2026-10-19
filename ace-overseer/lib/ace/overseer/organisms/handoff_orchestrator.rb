# frozen_string_literal: true

module Ace
  module Overseer
    module Organisms
      # Orchestrates `ace-overseer handoff` (L6.4): the overseer hands
      # the SAME task worktree to the next role in the prepared role
      # sequence when the previous leg finished. The gate reads only
      # real state — the worktree's role-sequence assignments (ace-assign
      # files), their current states, the per-leg start configs
      # (ace-coworker prepare) and the worktree's executor truth via the
      # coworker ActiveExecutorRule — so there can never be two active
      # executors: a busy, in-flight, failed, or unreadable predecessor
      # refuses the handoff (unknown state is not a free resource), and
      # nothing is re-prepared: the next role starts from the existing
      # start config. On success the next leg's start command is
      # reported and a terminal window opens in the worktree (same
      # window surface as work-on); dry-run performs the whole check
      # with zero effects. Two different tasks use two different
      # worktrees and hand off independently.
      class HandoffOrchestrator
        def initialize(task_loader: nil, worktree_finder: nil, probe: nil,
          window_opener: nil, config: nil, lifecycle_exclusion: nil)
          @task_manager = task_loader || Ace::Task::Organisms::TaskManager.new
          @worktree_finder = worktree_finder
          @probe = probe
          @window_opener = window_opener || Molecules::WindowOpener.new
          @config = config || Ace::Overseer.config
          @lifecycle_exclusion = lifecycle_exclusion
        end

        # @param task_ref [String] task reference (the task whose
        #   worktree receives the next role)
        # @param dry_run [Boolean] full gate, zero effects
        # @param on_progress [#call] progress sink
        # @param runtime [String, nil] terminal backend override
        # @return [Hash] {task_ref, worktree_path, branch, status
        #   ("ready"|"sequence_complete"), next: {"role","assignment",
        #   "start_config"}|nil, legs: [...], dry_run}
        # @raise [Error] when the task or its worktree cannot be
        #   resolved, or the handoff is refused (with every reason)
        def call(task_ref:, dry_run: false, on_progress: nil, runtime: nil)
          progress = on_progress || ->(_msg) {}

          task = @task_manager.show(task_ref.to_s)
          raise Error, "Task not found: #{task_ref}" unless task

          progress.call("Locating worktree for task #{task.id}...")
          found = worktree_finder.switch(task.id.to_s)
          unless found[:success]
            raise Error, "No usable worktree for task #{task.id}: #{found[:error] || found[:message]}. " \
              "Handoff works in an existing worktree; start one with ace-overseer work-on " \
              "or ace-coworker prepare."
          end
          worktree_path = found[:worktree_path]

          outcome = nil
          lifecycle_exclusion.with_shared(lifecycle_exclusion.task_key(task.id.to_s)) do
            progress.call("Reading role-sequence state in #{worktree_path}...")
            state = probe.probe(worktree_path, task_id: task.id.to_s)

            active = Ace::Coworker::Atoms::ActiveExecutorRule.evaluate(
              config: state[:executor][:config], assignments: state[:executor][:assignments])
            verdict = Atoms::HandoffReadiness.evaluate(legs: state[:legs], active_executor: active)

            if verdict[:status] == :refused
              raise Error, "Handoff refused: #{verdict[:reasons].join("; ")}"
            end

            outcome = ready_outcome(task: task, worktree_path: worktree_path, branch: found[:branch],
              verdict: verdict, dry_run: dry_run, runtime: runtime, progress: progress)
          end

          outcome
        end

        private

        def ready_outcome(task:, worktree_path:, branch:, verdict:, dry_run:, runtime:, progress:)
          next_leg = verdict[:next]
          start_config = next_leg ? start_config_path(next_leg["role"]) : nil

          if next_leg
            progress.call("Next leg: role #{next_leg['role']} (assignment #{next_leg['assignment']})")
            unless dry_run
              window_options = {worktree_path: worktree_path, preset: @config.dig("window_presets", "handoff")}
              window_options[:runtime] = runtime if runtime
              @window_opener.open(**window_options)
            end
          else
            progress.call("Every role in the sequence finished; nothing to hand off")
          end

          {
            task_ref: task.id.to_s,
            worktree_path: worktree_path,
            branch: branch,
            status: verdict[:status] == :sequence_complete ? "sequence_complete" : "ready",
            next: next_leg && {
              "role" => next_leg["role"],
              "assignment" => next_leg["assignment"],
              "start_config" => start_config
            },
            dry_run: dry_run
          }
        end

        def start_config_path(role)
          File.join(Molecules::HandoffProbe::PREPARE_DIR, "#{role}.yml")
        end

        def worktree_finder
          @worktree_finder || Ace::Git::Worktree::Organisms::WorktreeManager.new
        end

        def probe
          @probe || Molecules::HandoffProbe.new
        end

        def lifecycle_exclusion
          @lifecycle_exclusion ||= Ace::Assign::Molecules::LifecycleExclusion.new
        end
      end
    end
  end
end
