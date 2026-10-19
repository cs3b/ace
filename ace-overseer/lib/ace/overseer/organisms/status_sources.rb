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

        # Forge pull requests through the forge-neutral ace-git provider
        # contract (the same registry ace-review/ace-git use). Default OFF
        # in config; when enabled but unreachable (no server configured,
        # provider CLI missing, network down) it raises and is shown as a
        # per-source error, never as "no open PRs".
        class ForgeSource
          ORIGIN = "ace-git Providers#recent_pull_requests"
          DEFAULT_LIMIT = 20

          def initialize(config: {}, server_resolver: nil, provider_factory: nil)
            @limit = config["limit"] || DEFAULT_LIMIT
            @server_resolver = server_resolver || -> { Ace::Git::ServerRegistry.resolve_default }
            @provider_factory = provider_factory || ->(server) { Ace::Git::Providers.for(server) }
          end

          def origin = ORIGIN

          def fetch
            server = @server_resolver.call
            provider = @provider_factory.call(server)
            provider.recent_pull_requests(limit: @limit).map do |pr|
              {
                number: pr.number,
                title: pr.title,
                state: pr.state.to_s,
                draft: pr.draft,
                head_ref: pr.head_ref,
                url: pr.url
              }
            end
          end
        end

        # Project task tree through ace-task's TaskManager (the owner of
        # `.ace-tasks/`): ids, statuses, dependencies — the dependency and
        # finished-work view of the project.
        class ProjectTasksSource
          ORIGIN = "ace-task TaskManager (.ace-tasks)"
          TASK_FIELDS = %i[id status title priority dependencies].freeze

          def initialize(manager_factory: nil)
            @manager_factory = manager_factory || -> { Ace::Task::Organisms::TaskManager.new }
          end

          def origin = ORIGIN

          def fetch
            manager = @manager_factory.call
            manager.list(in_folder: "all", sort: "id").map do |task|
              TASK_FIELDS.to_h { |field| [field, task.public_send(field)] }
            end
          end
        end

        # Private overseer tree (`.ace-tasks/_overseer/`) through the same
        # ace-task owner, addressed with the public `--in _overseer`
        # folder surface.
        class OverseerTreeSource
          ORIGIN = "ace-task TaskManager (.ace-tasks/_overseer)"
          TASK_FIELDS = %i[id status title dependencies].freeze

          def initialize(manager_factory: nil)
            @manager_factory = manager_factory || -> { Ace::Task::Organisms::TaskManager.new }
          end

          def origin = ORIGIN

          def fetch
            manager = @manager_factory.call
            manager.list(in_folder: "_overseer", sort: "id").map do |task|
              TASK_FIELDS.to_h { |field| [field, task.public_send(field)] }
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
