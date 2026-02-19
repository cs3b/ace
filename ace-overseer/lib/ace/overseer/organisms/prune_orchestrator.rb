# frozen_string_literal: true

module Ace
  module Overseer
    module Organisms
      class PruneOrchestrator
        def initialize(worktree_manager: nil, prune_checker: nil, tmux_executor: nil, config: nil)
          @worktree_manager = worktree_manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          @prune_checker = prune_checker || Molecules::PruneSafetyChecker.new
          @tmux_executor = tmux_executor || Ace::Tmux::Molecules::TmuxExecutor.new
          @config = config || Ace::Overseer.config
        end

        def call(dry_run:, yes:, force: false, targets: [], input: $stdin, output: $stdout, on_progress: nil)
          progress = on_progress || ->(_msg) {}

          progress.call("Scanning task worktrees...")
          result = @worktree_manager.list_all(show_tasks: true, task_associated: true)
          raise Error, result[:error] || "Failed to list task worktrees" unless result[:success]

          worktrees = Array(result[:worktrees]).select(&:task_associated?)
          worktrees = filter_by_targets(worktrees, targets) if targets.any?

          progress.call("Checking #{worktrees.length} worktree(s)...")
          checked = worktrees.map do |worktree|
            @prune_checker.check(worktree_path: worktree.path, task_ref: worktree.task_id)
          end

          safe = checked.select(&:safe_to_prune?)
          unsafe = checked.reject(&:safe_to_prune?)
          forced = force ? unsafe : []

          if dry_run
            return { dry_run: true, safe: safe, unsafe: unsafe, forced: forced, pruned: [], failed: [] }
          end

          print_candidates(safe, unsafe, force, output)

          to_prune = safe + forced
          unless yes
            output.print("Continue? [y/N] ")
            answer = input.gets.to_s.strip.downcase
            unless %w[y yes].include?(answer)
              return { dry_run: false, safe: safe, unsafe: unsafe, forced: forced, pruned: [], failed: [], aborted: true }
            end
          end

          pruned = []
          failed = []

          to_prune.each do |candidate|
            remove_result = @worktree_manager.remove(
              candidate.worktree_path,
              force: force,
              ignore_untracked: true
            )
            if remove_result[:success]
              close_tmux_window(candidate.task_id)
              pruned << candidate
            else
              failed << { candidate: candidate, error: remove_result[:error] }
            end
          end

          {
            dry_run: false,
            safe: safe,
            unsafe: unsafe,
            forced: forced,
            pruned: pruned,
            failed: failed,
            aborted: false
          }
        end

        private

        def filter_by_targets(worktrees, targets)
          worktrees.select do |wt|
            targets.any? { |t| wt.task_id.to_s == t.to_s || wt.path.include?(t.to_s) }
          end
        end

        def print_candidates(safe, unsafe, force, output)
          if safe.any?
            output.puts("Safe to prune (#{safe.length}):")
            safe.each { |c| output.puts("  task.#{c.task_id} — #{c.worktree_path}") }
          else
            output.puts("No worktrees safe to prune.")
          end
          if unsafe.any?
            if force
              output.puts("Force removing (#{unsafe.length}):")
              unsafe.each { |c| output.puts("  task.#{c.task_id} — #{c.reasons.join(", ")}") }
            else
              output.puts("Skipping (#{unsafe.length}):")
              unsafe.each { |c| output.puts("  task.#{c.task_id} — #{c.reasons.join(", ")}") }
            end
          end
        end

        def close_tmux_window(task_id)
          window_name = Atoms::WindowNameFormatter.format(
            task_id,
            format: @config["window_name_format"] || "t{task_id}"
          )
          session_name = @config["tmux_session_name"] || "ace"
          tmux_bin = @config["tmux_binary"] || "tmux"
          @tmux_executor.run([tmux_bin, "kill-window", "-t", "#{session_name}:#{window_name}"])
        rescue StandardError
          false
        end
      end
    end
  end
end
