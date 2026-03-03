# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Overseer
    module Organisms
      class StatusCollector
        def initialize(worktree_manager: nil, context_collector: nil, project_root: nil)
          @worktree_manager = worktree_manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          @context_collector = context_collector || Molecules::WorktreeContextCollector.new
          @project_root = project_root
        end

        def collect
          result = @worktree_manager.list_all(show_tasks: true)
          raise Error, result[:error] || "Failed to list worktrees" unless result[:success]

          all_worktrees = Array(result[:worktrees]).reject(&:bare)
          # Exclude main worktree (handled separately via collect_main_context)
          main_root = @project_root || resolve_project_root
          non_main = all_worktrees.reject { |wt| main_root && wt.path == main_root }

          contexts = collect_contexts_parallel(non_main)

          # Keep task worktrees always; non-task worktrees only if they have assignments
          contexts.select! { |ctx| ctx.task_id != "unknown" || ctx.assignments.any? }

          main_context = collect_main_context
          contexts.unshift(main_context) if main_context && main_context.assignments.any?

          {
            contexts: contexts
          }
        end

        def collect_quick(previous_snapshot)
          previous_contexts = previous_snapshot[:contexts]
          return collect if previous_contexts.nil? || previous_contexts.empty?

          contexts = previous_contexts.map do |prev_ctx|
            @context_collector.collect_assignments_only(
              prev_ctx.worktree_path,
              cached_branch: prev_ctx.branch,
              cached_git_status: prev_ctx.git_status,
              location_type: prev_ctx.location_type
            )
          rescue StandardError
            nil
          end.compact

          { contexts: contexts }
        end

        def to_table(snapshot)
          Atoms::StatusFormatter.format_dashboard(snapshot[:contexts])
        end

        def to_h(snapshot)
          {
            worktrees: snapshot[:contexts].map { |context| context_to_h(context) }
          }
        end

        private

        def collect_main_context
          root = @project_root || resolve_project_root
          return nil unless root

          @context_collector.collect(root, location_type: :main)
        rescue StandardError
          nil
        end

        def resolve_project_root
          stdout, status = Open3.capture2(
            "git", "rev-parse", "--path-format=absolute", "--git-common-dir"
          )
          return nil unless status.success?

          common_dir = stdout.to_s.strip
          return nil if common_dir.empty?

          File.dirname(common_dir)
        rescue StandardError
          nil
        end

        # Collect worktree contexts in parallel for ~Nx speedup
        # Each worktree involves GitHub API calls (~1s each), so parallelizing
        # reduces total time from N seconds to ~1-2 seconds
        #
        # Uses subprocess isolation (fork + exec) because Dir.chdir is process-global
        # and cannot be safely used in threads. Each subprocess runs context collection
        # independently, avoiding race conditions.
        def collect_contexts_parallel(worktrees)
          return [] if worktrees.empty?

          # For single worktree, skip subprocess overhead
          return [@context_collector.collect(worktrees.first.path)] if worktrees.size == 1

          # Build the worker script that collects context for a single worktree
          worker_script = <<~'RUBY'
            # frozen_string_literal: true
            require "ace/overseer"
            require "json"

            worktree_path = ARGV[0]
            collector = Ace::Overseer::Molecules::WorktreeContextCollector.new
            context = collector.collect(worktree_path)

            # Serialize for IPC
            puts JSON.generate({
              task_id: context.task_id,
              worktree_path: context.worktree_path,
              branch: context.branch,
              assignments: context.assignments,
              git_status: context.git_status
            })
          RUBY

          # Spawn parallel subprocesses
          pipes = worktrees.map do |worktree|
            pipe_read, pipe_write = IO.pipe
            pid = fork do
              pipe_read.close
              $stdout.reopen(pipe_write)
              pipe_write.close
              exec("ruby", "-e", worker_script, worktree.path.to_s)
              exit!(1) # unreachable unless exec fails
            end
            pipe_write.close
            { pid: pid, pipe: pipe_read, worktree: worktree }
          end

          # Collect results, preserving order
          contexts = Array.new(worktrees.size)
          pipes.each_with_index do |p, idx|
            output = p[:pipe].read
            p[:pipe].close
            Process.wait(p[:pid])

            if $?.success? && !output.empty?
              data = JSON.parse(output)
              contexts[idx] = Models::WorkContext.new(
                task_id: data["task_id"],
                worktree_path: data["worktree_path"],
                branch: data["branch"],
                assignments: data["assignments"] || [],
                git_status: data["git_status"]
              )
            end
          end

          contexts.compact
        end

        def context_to_h(context)
          {
            task_id: context.task_id,
            worktree_path: context.worktree_path,
            branch: context.branch,
            assignments: context.assignments,
            git: context.git_status
          }
        end
      end
    end
  end
end
