# frozen_string_literal: true

require "digest"
require "json"
require_relative "../atoms/observation_sources"
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
          overseer_tasks = []
          collect(sources, events, Atoms::ObservationSources::OVERSEER_TASKS) do
            overseer_tasks = @tasks.list(in_folder: "_overseer")
            task_events(overseer_tasks, "overseer-task")
          end
          collect(sources, events, Atoms::ObservationSources::WORKTREES) { worktree_events }
          collect(sources, events, Atoms::ObservationSources::COWORKERS) { coworker_events(overseer_tasks) }
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
        def coworker_events(overseer_tasks)
          result = @worktrees.list_all
          raise Error, result[:error] || "failed to list worktrees" unless result[:success]

          worktrees = Array(result[:worktrees]).reject(&:bare)
          native = !worktrees.empty? && (@env["ACE_RUNTIME"] == "herdr" || !@env["HERDR_PANE_ID"].to_s.empty? || !@env["HERDR_PANE"].to_s.empty?)
          sessions = native ? executor_sessions : {}
          bindings = native ? executor_bindings(overseer_tasks) : {}
          worktrees.flat_map do |worktree|
            probe = @probe_factory.call(worktree.path)
            report = probe.probe(worktree.path)
            verdict = Ace::Coworker::Atoms::ActiveExecutorRule.evaluate(
              config: report[:config], assignments: report[:assignments]
            )
            identity = Digest::SHA256.hexdigest(worktree.path)
            visible = sessions.fetch(worktree.path, [])
            completed = report[:assignments].filter_map { |row| row["id"] if row["state"] == "completed" }
            missing = bindings.fetch(worktree.path, []).reject do |binding|
              completed.include?(binding["assignment"]) || visible.any? { |session| session["terminal"] == binding["terminal"] }
            end
            payload = {"path" => worktree.path, "active" => verdict[:active],
              "evidence" => verdict[:evidence], "sessions" => visible, "missing_sessions" => missing}
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

        # A coordinator's durable binding also detects a session that
        # started and exited between two native observations.
        def executor_bindings(tasks)
          tasks.flat_map { |task| [task, *Array(task.subtasks)] }.filter_map do |step|
            next if %w[done canceled cancelled].include?(step.status)

            metadata = step.metadata || {}
            worktree, assignment, terminal = metadata.values_at("worktree", "assignment", "terminal")
            next unless worktree.is_a?(String) && worktree.start_with?("/") &&
              assignment.is_a?(String) && assignment.match?(/\A[a-zA-Z0-9_-]+\z/) &&
              terminal.is_a?(String) && terminal.match?(/\Aterm_[0-9a-f]+\z/)

            [worktree, {"task" => step.id, "assignment" => assignment, "terminal" => terminal}]
          end.group_by(&:first).transform_values { |rows| rows.map(&:last).sort_by { |row| row.fetch("task") } }
        end

        # Native sessions can disappear without writing an assignment report.
        # Project their presence on the existing stable worktree row so that
        # even an interruption before the first assignment step is visible.
        def executor_sessions
          response = @herdr.agent_list.parsed_json
          agents = response.is_a?(Hash) && !response.key?("error") && response.dig("result", "agents")
          raise Error, "native executor inventory is unavailable" unless agents.is_a?(Array)

          sessions = Hash.new { |index, cwd| index[cwd] = [] }
          agents.each do |agent|
            next unless agent.is_a?(Hash) && agent["name"].to_s.start_with?("coworker-")

            terminal, cwd = agent.values_at("terminal_id", "cwd")
            unless terminal.is_a?(String) && terminal.match?(/\Aterm_[0-9a-f]+\z/) &&
                cwd.is_a?(String) && cwd.start_with?("/")
              raise Error, "executor session identity is invalid"
            end
            # A provider failure can end a turn while its panel stays alive and
            # no report is written. Herdr exposes completion_seq when done and
            # omits it while working: completion/resumption each revise once,
            # while repeated observations of either state remain silent.
            # This is a signal to inspect the assignment, never success proof.
            sessions[cwd] << {"terminal" => terminal, "agent" => agent["name"],
              "completion_seq" => agent["completion_seq"]}
          end
          sessions.transform_values { |rows| rows.sort_by { |row| row.fetch("terminal") } }
        end
      end
    end
  end
end
