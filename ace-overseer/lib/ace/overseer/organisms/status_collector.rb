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
          result = @worktree_manager.list_all(show_tasks: true, task_associated: true)
          raise Error, result[:error] || "Failed to list task worktrees" unless result[:success]

          worktrees = Array(result[:worktrees]).select(&:task_associated?)
          contexts = collect_contexts_parallel(worktrees)

          main_context = collect_main_context
          contexts.unshift(main_context) if main_context&.assignment_status

          {
            contexts: contexts
          }
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
              assignment_status: context.assignment_status,
              git_status: context.git_status,
              assignment_count: context.assignment_count
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
                assignment_status: data["assignment_status"],
                git_status: data["git_status"],
                assignment_count: data["assignment_count"] || 0
              )
            end
          end

          contexts.compact
        end

        def context_to_h(context)
          assignment = context.assignment_status && context.assignment_status["assignment"]
          current = context.assignment_status && context.assignment_status["current_phase"]
          phase_summary = context.assignment_status && context.assignment_status["phase_summary"]

          {
            task_id: context.task_id,
            worktree_path: context.worktree_path,
            branch: context.branch,
            assignment: assignment,
            current_phase: current,
            phase_summary: phase_summary,
            git: context.git_status
          }
        end
      end
    end
  end
end
