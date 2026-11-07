# frozen_string_literal: true

require "digest"
require "json"
require_relative "../atoms/observation_sources"
require_relative "isolated_runtime"
require "ace/herdr/molecules/herdr_executor"

module Ace
  module Overseer
    module Molecules
      # Standing local-state observation (task 8xs.t.pu0.3): projects the
      # local source classes the started overseer watches — project
      # tasks, private _overseer tasks, worktrees, coworker availability,
      # assignment progress, project sessions and HITL events — each read from its STATE
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
        EXECUTOR_ROLES = %w[worker verifier integrator].freeze

        def initialize(task_manager: nil, worktree_manager: nil, probe_factory: nil, project_sessions: nil,
          herdr: Ace::Herdr::Molecules::HerdrExecutor.new, env: ENV)
          @tasks = task_manager || Ace::Task::Organisms::TaskManager.new
          @worktrees = worktree_manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          @probe_factory = probe_factory || ->(path) {
            Ace::Coworker::Molecules::WorktreeExecutorProbe.new(project_root: path)
          }
          @project_sessions = project_sessions || ProjectSessions.new
          @herdr = herdr
          @env = env
        end

        # @return [Hash] {"events" => Array<{key, revision, type, ...}>,
        #   "sources" => {name => {"status" => "ok"|"degraded", "error"?}}}
        def call
          sources = {}
          events = []

          collect(sources, events, Atoms::ObservationSources::PROJECT_TASKS) { project_task_events }
          collect(sources, events, Atoms::ObservationSources::OVERSEER_TASKS) { overseer_task_events }
          collect(sources, events, Atoms::ObservationSources::WORKTREES) { worktree_events }
          collect(sources, events, Atoms::ObservationSources::COWORKERS) { coworker_events }
          if @project_sessions.configured?
            collect(sources, events, Atoms::ObservationSources::PROJECT_SESSIONS) { @project_sessions.call }
            failed_sessions = events.select { |event| event["type"] == "project-session" && event["state"] == "unavailable" }
            unless failed_sessions.empty?
              sources[Atoms::ObservationSources::PROJECT_SESSIONS] = {"status" => "degraded", "error" => "one or more configured project sessions are unavailable"}
              failures = failed_sessions.map { |event| [event.fetch("key"), event.fetch("revision")] }.sort
              events << {"key" => "source:project_sessions", "revision" => revision(failures),
                         "type" => "source-health", "status" => "degraded",
                         "error" => "one or more configured project sessions are unavailable"}
            end
          end

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

          worktrees = Array(result[:worktrees]).reject(&:bare)
          sessions = worktrees.empty? ? {} : executor_sessions
          worktrees.flat_map do |worktree|
            probe = @probe_factory.call(worktree.path)
            report = probe.probe(worktree.path)
            verdict = Ace::Coworker::Atoms::ActiveExecutorRule.evaluate(
              config: report[:config], assignments: report[:assignments]
            )
            identity = Digest::SHA256.hexdigest(worktree.path)
            payload = {"path" => worktree.path, "active" => verdict[:active],
              "evidence" => verdict[:evidence], "sessions" => sessions.fetch(worktree.path, [])}
            executor = {"key" => "executor:#{identity}", "revision" => revision(payload),
              "type" => "executor"}.merge(payload)
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

        # Native sessions can disappear without writing an assignment report.
        # Project their presence on the existing stable worktree row so that
        # even an interruption before the first assignment step is visible.
        def executor_sessions
          return {} unless IsolatedRuntime.enabled?(env: @env)

          response = @herdr.agent_list.parsed_json
          agents = response.is_a?(Hash) && !response.key?("error") && response.dig("result", "agents")
          raise Error, "isolated native executor inventory is unavailable" unless agents.is_a?(Array)

          sessions = Hash.new { |index, cwd| index[cwd] = [] }
          agents.each do |agent|
            role = agent.dig("isolated_session", "role")
            next unless EXECUTOR_ROLES.include?(role)

            terminal, cwd = agent.values_at("terminal_id", "cwd")
            unless terminal.is_a?(String) && terminal.match?(/\Aterm_[0-9a-f]+\z/) &&
                cwd.is_a?(String) && cwd.start_with?("/")
              raise Error, "isolated executor session identity is invalid"
            end
            sessions[cwd] << {"terminal" => terminal, "role" => role}
          end
          sessions.transform_values { |rows| rows.sort_by { |row| row.fetch("terminal") } }
        end
      end
    end
  end
end
