# frozen_string_literal: true

require "ace/herdr"

module Ace
  module Overseer
    module Organisms
      # Configurable status sources for `ace-overseer status` (L7.2).
      #
      # Every source is a read-only adapter over an interface owned by
      # another tool (ADR-034: no persisted copy of any queue). Each one
      # answers two methods:
      #   origin -> String  explicit provenance of the information
      #   fetch   -> data   live, JSON-serializable payload
      # A source signals failure by raising; the collector turns that into
      # a per-source error entry rendered next to the healthy results, so
      # missing data never reads as a free worktree or a finished task.
      module StatusSources
        # Live worktree contexts (worktrees + assignment progress + git
        # state) through the existing StatusCollector worktree pipeline —
        # the public surface of `ace-git-worktree list` plus assignment
        # context, not a second worktree implementation.
        class WorktreesSource
          ORIGIN = "ace-git-worktree WorktreeManager + worktree assignment context"

          def initialize(collector:)
            @collector = collector
          end

          def origin = ORIGIN

          def fetch
            @collector.to_h(@collector.collect)
          end
        end

        # Forge pull requests AND issues (spec .6.1: "PR/issues GitHub or
        # Forgejo") through the forge-neutral ace-git provider contract
        # (the same registry ace-review/ace-git use). Default OFF in
        # config; when enabled but unreachable (no server configured,
        # provider CLI missing, network down) it raises and is shown as a
        # per-source error, never as "no open PRs". Issue listing uses the
        # provider's own listing API when it exposes one; when the
        # provider package ships no issue-listing API the issues section
        # carries an EXPLICIT per-source unavailable marker — issues are
        # never silently substituted with pull-request-only data.
        class ForgeSource
          ORIGIN = "ace-git Providers#recent_pull_requests + #recent_issues"
          DEFAULT_LIMIT = 20
          ISSUES_UNAVAILABLE = "the resolved provider exposes no issue-listing API; " \
            "issues are unavailable, not empty"

          def initialize(config: {}, server_resolver: nil, provider_factory: nil)
            @limit = resolve_limit(config["limit"])
            @server_resolver = server_resolver || -> { Ace::Git::ServerRegistry.resolve_default }
            @provider_factory = provider_factory || ->(server) { Ace::Git::Providers.for(server) }
          end

          def origin = ORIGIN

          def fetch
            server = @server_resolver.call
            provider = @provider_factory.call(server)
            {
              pull_requests: provider.recent_pull_requests(limit: @limit).map do |pr|
                {
                  number: pr.number,
                  title: pr.title,
                  state: pr.state.to_s,
                  draft: pr.draft,
                  head_ref: pr.head_ref,
                  url: pr.url
                }
              end,
              issues: issues_of(provider)
            }
          end

          private

          # Issue listing stays the provider's own capability: when no
          # listing API exists the unavailability is explicit, so the
          # consumer can never read PR-only data as the full forge view.
          def issues_of(provider)
            unless provider.respond_to?(:recent_issues)
              return {status: "unavailable", reason: ISSUES_UNAVAILABLE}
            end

            provider.recent_issues(limit: @limit).map do |issue|
              {number: issue.number, title: issue.title, state: issue.state.to_s, url: issue.url}
            end
          end

          # Explicit 0 lists nothing; a negative limit clamps to 0; a
          # missing/typo'd value falls back to the default.
          def resolve_limit(value)
            limit = Integer(value)
            limit.negative? ? 0 : limit
          rescue ArgumentError, TypeError
            DEFAULT_LIMIT
          end
        end

        # Project task tree through ace-task's TaskManager (the owner of
        # `.ace-tasks/`): ids, statuses, dependencies — the dependency and
        # finished-work view of the project. `in_folder: "all"` includes
        # every special folder, so the special_folder provenance field is
        # carried and the CONSUMER can tell project-root tasks from
        # `_overseer`/`_archive` entries (attention must not double-count
        # or mislabel them as project blockers). The FULL descendant tree
        # is flattened: TaskManager.list attaches direct subtasks, and
        # deeper levels (a three-level backlog) are re-read through the
        # owner's own scanner/loader — so blocked children and
        # dependencies naming subtasks resolve instead of silently
        # disappearing from status.
        class ProjectTasksSource
          ORIGIN = "ace-task TaskManager (.ace-tasks)"
          TASK_FIELDS = %i[id status title priority dependencies special_folder].freeze

          def initialize(manager_factory: nil)
            @manager_factory = manager_factory || -> { Ace::Task::Organisms::TaskManager.new }
          end

          def origin = ORIGIN

          def fetch
            manager = @manager_factory.call
            TreeRows.flatten(manager.list(in_folder: "all", sort: "id"), TASK_FIELDS, root_dir: manager.root_dir)
          end
        end

        # Private overseer tree (`.ace-tasks/_overseer/`) through the same
        # ace-task owner, addressed with the public `--in _overseer`
        # folder surface. The full descendant tree is flattened (see
        # ProjectTasksSource), and each row carries the step's recorded
        # processed report (the owner's task metadata) so consumers can
        # tell a processed report from one still waiting.
        class OverseerTreeSource
          ORIGIN = "ace-task TaskManager (.ace-tasks/_overseer)"
          TASK_FIELDS = %i[id status title dependencies].freeze
          PRIVATE_TREE = "_overseer"

          def initialize(manager_factory: nil)
            @manager_factory = manager_factory || -> { Ace::Task::Organisms::TaskManager.new }
          end

          def origin = ORIGIN

          def fetch
            manager = @manager_factory.call
            TreeRows.flatten(manager.list(in_folder: "_overseer", sort: "id"), TASK_FIELDS,
              root_dir: manager.root_dir).map do |entry|
              entry[:special_folder] = "_overseer"
              entry
            end
          end
        end

        # Depth-first flattening of the task tree through the owner's own
        # interfaces: attached #subtasks first, and — where the owner's
        # loader stops (it never attaches children to a parented task) —
        # a read-only re-scan of the task's directory with the same
        # TaskScanner/TaskLoader molecules ace-task itself uses. Nothing
        # is cached or persisted; descendants inherit their parent's
        # special folder because they live under the parent's directory.
        module TreeRows
          module_function

          # @param tasks [Array<Object>] primary tasks from TaskManager#list
          # @param fields [Array<Symbol>] serialized task fields
          # @param root_dir [String] the manager's task root (e.g.
          #   TaskManager#root_dir); the descendant re-scan reads the
          #   actual tree, never a CWD-relative guess
          # @return [Array<Hash>] rows for the primary and every descendant
          def flatten(tasks, fields, root_dir:)
            Array(tasks).flat_map { |task| subtree_rows(task, fields, root_dir) }
          end

          def subtree_rows(task, fields, root_dir)
            row = fields.to_h { |field| [field, task.public_send(field)] }
            row[:processed_report] = task.metadata["processed_report"] if task.respond_to?(:metadata)
            [row].concat(descendant_rows(task, fields, root_dir))
          end

          def descendant_rows(task, fields, root_dir)
            children = task.respond_to?(:subtasks) ? Array(task.subtasks) : []
            children = linked_descendants(task, root_dir) if children.empty?
            children.flat_map { |child| subtree_rows(child, fields, root_dir) }
          end

          # @return [Array<Object>] children the owner's loader did not
          #   attach, read from the task's own directory.
          def linked_descendants(task, root_dir)
            return [] unless task.respond_to?(:path) && task.respond_to?(:id)

            scanner = Ace::Task::Molecules::TaskScanner.new(root_dir)
            loader = Ace::Task::Molecules::TaskLoader.new
            scanner.scan_subtasks(task.path.to_s, parent_id: task.id.to_s).filter_map do |result|
              loader.load(result.dir_path, id: result.id, special_folder: task.special_folder)
            end
          end
        end

        # Live Herdr layout through ace-herdr's own ControlSurface +
        # StatusComposer (read-only list calls; the same composition
        # `ace-herdr status` uses). An unreachable runtime raises and is
        # reported per-source, never as an empty layout.
        class HerdrSource
          ORIGIN = "ace-herdr ControlSurface + StatusComposer"

          def initialize(control_surface: nil)
            @control_surface = control_surface || -> { Ace::Herdr::Organisms::ControlSurface.new }
          end

          def origin = ORIGIN

          def fetch
            control = @control_surface.call
            Ace::Herdr::Molecules::StatusComposer.call(
              workspaces: control.list_workspaces,
              tabs: control.list_tabs,
              panes: control.list_panes
            )
          end
        end

        # Coworker progress per worktree: the coworker-owned
        # WorktreeExecutorProbe (commissioned config + assignment
        # inventory) evaluated with the coworker ActiveExecutorRule, so an
        # unknown or unparseable commission reads as busy/unknown — never
        # as a free worktree. One worktree's probe failure stays visible
        # as a per-worktree error entry; a worktree-listing failure raises
        # and fails the whole source.
        class CoworkersSource
          ORIGIN = "ace-coworker WorktreeExecutorProbe + ActiveExecutorRule"

          def initialize(worktree_manager: nil, probe_factory: nil)
            @worktree_manager = worktree_manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
            @probe_factory = probe_factory || ->(worktree_path) {
              Ace::Coworker::Molecules::WorktreeExecutorProbe.new(project_root: worktree_path)
            }
          end

          def origin = ORIGIN

          def fetch
            result = @worktree_manager.list_all
            raise Error, result[:error] || "Failed to list worktrees" unless result[:success]

            Array(result[:worktrees]).reject(&:bare).map do |worktree|
              probe_one(worktree)
            end
          end

          private

          def probe_one(worktree)
            probe = @probe_factory.call(worktree.path)
            executor = probe.probe(worktree.path)
            verdict = Ace::Coworker::Atoms::ActiveExecutorRule.evaluate(
              config: executor[:config], assignments: executor[:assignments]
            )
            {
              worktree: worktree.path,
              active: verdict[:active],
              evidence: verdict[:evidence],
              assignments: executor[:assignments]
            }
          rescue StandardError => e
            {worktree: worktree.path, error: "#{e.class}: #{e.message}"}
          end
        end
      end
    end
  end
end
