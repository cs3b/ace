# frozen_string_literal: true

require "digest"
require "json"

module Ace
  module Overseer
    module Molecules
      # Standing local-state observation (task 8xs.t.pu0.3): projects the
      # six local source classes the started overseer watches — project
      # tasks, private _overseer tasks, worktrees, coworker availability,
      # assignment progress and HITL events — each read from its STATE
      # OWNER (ace-task, ace-git-worktree, ace-coworker probe, ace-assign
      # inventory, ace-hitl). This molecule owns no second state: every
      # row is a {key, revision, type} projection whose revision changes
      # only when the owner's data changes, so a consumer (eyes) wakes on
      # real revisions and stays silent on identical state.
      #
      # A failing source degrades ONLY itself: it contributes a
      # `source-health` marker whose revision is stable per error class
      # (an identical repeated failure never re-wakes; a new failure mode
      # wakes once), while the healthy sources keep projecting.
      class LocalSources
        def initialize(task_manager: nil, worktree_manager: nil, probe_factory: nil)
          @tasks = task_manager || Ace::Task::Organisms::TaskManager.new
          @worktrees = worktree_manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          @probe_factory = probe_factory || ->(path) {
            Ace::Coworker::Molecules::WorktreeExecutorProbe.new(project_root: path)
          }
        end

        # @return [Hash] {"events" => Array<{key, revision, type, ...}>,
        #   "sources" => {name => {"status" => "ok"|"degraded", "error"?}}}
        def call
          sources = {}
          events = []

          collect(sources, events, "project_tasks") { project_task_events }
          collect(sources, events, "overseer_tasks") { overseer_task_events }
          collect(sources, events, "worktrees") { worktree_events }
          collect(sources, events, "coworkers") { coworker_events }

          {"events" => events, "sources" => sources}
        end

        private

        def collect(sources, events, name)
          rows = yield
          sources[name] = {"status" => "ok"}
          events.concat(rows)
        rescue StandardError => e
          sources[name] = {"status" => "degraded", "error" => "#{e.class}: #{e.message}"}
          events.concat([health_marker(name, e)])
        end

        # A degraded source surfaces as missing data — visibly, never as
        # an empty healthy list. The revision is keyed by error CLASS so
        # an identical repeated failure keeps the same revision (no
        # wake spam) while a new failure mode revises once.
        def health_marker(name, error)
          {"key" => "source:#{name}",
           "revision" => Digest::SHA256.hexdigest("degraded:#{error.class}"),
           "type" => "source-health", "status" => "degraded",
           "error" => "#{error.class}: #{error.message}"}
        end

        def revision(payload)
          Digest::SHA256.hexdigest(JSON.generate(payload))
        end

        def project_task_events
          task_events(@tasks.list(in_folder: "next"), "task")
        end

        def overseer_task_events
          task_events(@tasks.list(in_folder: "_overseer"), "overseer-task")
        end

        # Task rows revision on real lifecycle facts (status, dependency
        # set, subtask statuses) — not on cosmetic frontmatter churn.
        def task_events(tasks, type)
          tasks.map do |task|
            payload = {"id" => task.id, "status" => task.status,
              "dependencies" => Array(task.dependencies).sort,
              "subtasks" => Array(task.subtasks).map { |sub| [sub.id, sub.status] }.sort}
            {"key" => "#{type}:#{task.id}", "revision" => revision(payload),
             "type" => type, "id" => task.id, "status" => task.status,
             "title" => task.title, "dependencies" => Array(task.dependencies).sort}
          end
        end

        def worktree_events
          result = @worktrees.list_all
          raise Error, result[:error] || "failed to list worktrees" unless result[:success]

          Array(result[:worktrees]).reject(&:bare).map do |worktree|
            payload = {"path" => worktree.path, "branch" => worktree.branch}
            {"key" => "worktree:#{Digest::SHA256.hexdigest(worktree.path)}",
             "revision" => revision(payload), "type" => "worktree",
             "path" => worktree.path, "branch" => worktree.branch}
          end
        end

        # Coworker availability AND assignment progress in one pass: the
        # executor probe reads the worktree's commissioned config and the
        # ace-assign inventory (existing run identifiers — assignment
        # ids, never pane names), the ActiveExecutorRule decides live vs
        # stale, and each in-flight assignment projects its own progress
        # row so a step report revises that assignment only.
        def coworker_events
          result = @worktrees.list_all
          raise Error, result[:error] || "failed to list worktrees" unless result[:success]

          Array(result[:worktrees]).reject(&:bare).flat_map do |worktree|
            probe = @probe_factory.call(worktree.path)
            report = probe.probe(worktree.path)
            verdict = Ace::Coworker::Atoms::ActiveExecutorRule.evaluate(
              config: report[:config], assignments: report[:assignments]
            )
            identity = Digest::SHA256.hexdigest(worktree.path)
            executor = {"key" => "executor:#{identity}",
                        "revision" => revision({"path" => worktree.path,
                                                "active" => verdict[:active],
                                                "evidence" => verdict[:evidence]}),
                        "type" => "executor", "path" => worktree.path,
                        "active" => verdict[:active], "evidence" => verdict[:evidence]}
            assignments = report[:assignments].map do |assignment|
              {"key" => "assignment:#{assignment["id"]}",
               "revision" => revision({"id" => assignment["id"], "state" => assignment["state"],
                                       "progress" => assignment["progress"]}),
               "type" => "assignment", "id" => assignment["id"],
               "state" => assignment["state"], "progress" => assignment["progress"]}
            end
            [executor] + assignments
          end
        end
      end
    end
  end
end
