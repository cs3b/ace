# frozen_string_literal: true

require "tmpdir"

require_relative "../molecules/task_config_loader"
require_relative "../molecules/task_scanner"
require_relative "../molecules/task_resolver"
require_relative "../molecules/task_loader"
require_relative "../molecules/task_creator"
require_relative "../molecules/subtask_creator"
require_relative "../molecules/task_reparenter"
require_relative "../molecules/issue_link"
require_relative "../atoms/task_validation_rules"

module Ace
  module Task
    module Organisms
      # Orchestrates all task CRUD operations.
      # Entry point for task management with config-driven root directory.
      class TaskManager
        CREATE_RETRY_LIMIT = 3
        class CreateRetriesExhaustedError < StandardError; end

        attr_reader :last_list_total, :last_folder_counts, :last_list_cycle_ids

        # @param root_dir [String, nil] Override root directory for tasks
        # @param config [Hash, nil] Override configuration
        def initialize(root_dir: nil, config: nil)
          @config = config || load_config
          @root_dir = root_dir || resolve_root_dir
          @last_update_note = nil
          @last_list_cycle_ids = []
          @last_scan_results = []
        end

        attr_reader :last_update_note

        # Create a new task.
        # @param title [String] Task title
        # @param status [String, nil] Initial status
        # @param priority [String, nil] Priority level
        # @param tags [Array<String>] Tags
        # @param dependencies [Array<String>] Dependency task IDs
        # @param use_llm_slug [Boolean] Whether to attempt LLM slug generation
        # @return [Models::Task] Created task
        def create(
          title,
          status: nil,
          priority: nil,
          tags: [],
          dependencies: [],
          use_llm_slug: false,
          estimate: nil,
          remote_issue: nil
        )
          ensure_root_dir
          creator = Molecules::TaskCreator.new(root_dir: @root_dir, config: @config)
          attempts = 0

          # Authoritative validation precedes the task write: an offline or
          # conflicting link must not create a task artifact at all. Offline
          # validation is the one accepted pre-write failure mode - the task
          # is then created with the complete pending link for replay.
          ensure_issue_linkable!(remote_issue) if remote_issue
          begin
            attempts += 1
            created_task = creator.create(
              title,
              status: status,
              priority: priority,
              tags: tags,
              dependencies: dependencies,
              use_llm_slug: use_llm_slug,
              time: Time.now.utc + ((attempts - 1) * 2),
              estimate: estimate,
              remote_issue: remote_issue
            )
            sync_started = false
            begin
              result = nil
              with_issue_identity_lock(remote_issue) do
                ensure_issue_not_linked_elsewhere!(remote_issue, exclude_id: created_task.id) if remote_issue
                sync_started = true
                result = sync_linked_issues_for(created_task, reason: "create")
              end
              if result[:success] == false && result[:error].to_s.start_with?("Ace::Git::ProviderIdentityMismatchError")
                # Ownership was confirmed to have changed: the task must not
                # survive as a second local claimant for the issue.
                FileUtils.rm_rf(created_task.path)
                raise Ace::Git::ProviderIdentityMismatchError, result[:error].to_s
              end
            rescue Ace::Git::ProviderUnreachableError
              # Offline sync retains the complete local link + pending flag:
              # offline replay is the spec-mandated recovery path.
              raise
            rescue StandardError
              # Confirmed rejections (ownership conflict, unknown server) must
              # not leave a second local claimant for the issue. Once sync has
              # begun the remote marker may exist: retain the task and its
              # pending identity as the recovery record instead of deleting it.
              FileUtils.rm_rf(created_task.path) unless sync_started
              raise
            end
            show_after_sync(created_task) || created_task
          rescue Molecules::TaskCreator::IdCollisionError
            retry if attempts < CREATE_RETRY_LIMIT
            raise CreateRetriesExhaustedError,
              "Failed to create task: unable to generate a unique ID after #{CREATE_RETRY_LIMIT} attempts"
          end
        end

        # Show (load) a single task by reference, including subtasks.
        # @param ref [String] Full ID, shortcut, or subtask reference
        # @return [Models::Task, nil] Loaded task or nil if not found
        def show(ref)
          scan_result = resolve_scan_result(ref)
          return nil unless scan_result

          loader = Molecules::TaskLoader.new
          loader.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
        end

        # List tasks with optional filtering and sorting.
        # @param status [String, nil] Filter by status
        # @param in_folder [String, nil] Filter by special folder (default: "next" = root items only)
        # @param tags [Array<String>] Filter by tags (any match)
        # @param filters [Array<String>, nil] Generic filter strings
        # @param sort [String] Sort order: "smart" (default, dependency-aware), "id", "priority", "created"
        # @return [Array<Models::Task>] List of tasks
        def list(status: nil, in_folder: "next", tags: [], filters: nil, sort: "smart")
          scanner = Molecules::TaskScanner.new(@root_dir)
          scan_results = scanner.scan_in_folder(in_folder)
          @last_list_total = scanner.last_scan_total
          @last_folder_counts = scanner.last_folder_counts
          @last_scan_results = scanner.last_scan_results
          @last_list_cycle_ids = []

          loader = Molecules::TaskLoader.new
          tasks = scan_results.filter_map do |sr|
            loader.load(sr.dir_path, id: sr.id, special_folder: sr.special_folder)
          end

          # Apply legacy filters
          tasks = tasks.select { |t| t.status == status } if status
          tasks = filter_by_tags(tasks, tags) if tags.any?

          # Apply generic --filter specs
          if filters && !filters.empty?
            filter_specs = Ace::Support::Items::Atoms::FilterParser.parse(filters)
            tasks = Ace::Support::Items::Molecules::FilterApplier.apply(
              tasks, filter_specs, value_accessor: method(:task_value_accessor)
            )
          end

          apply_sort(tasks, sort)
        end

        # Update a task's frontmatter fields and optionally move to a folder.
        # @param ref [String] Task reference
        # @param set [Hash] Fields to set (supports dot-notation for nested keys)
        # @param add [Hash] Fields to add to arrays
        # @param remove [Hash] Fields to remove from arrays
        # @param move_to [String, nil] Target folder to move to (archive, maybe, anytime, next/root//)
        # @param move_as_child_of [String, nil] Reparent: parent ref, "none" (promote), "self" (orchestrator)
        # @return [Models::Task, nil] Updated task or nil if not found
        def update(ref, set: {}, add: {}, remove: {}, move_to: nil, move_as_child_of: nil)
          @last_update_note = nil
          scan_result = resolve_scan_result(ref)
          return nil unless scan_result

          loader = Molecules::TaskLoader.new
          task = loader.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
          return nil unless task

          # Apply field updates if any
          has_field_updates = [set, add, remove].any? { |h| h && !h.empty? }
          reject_issue_metadata_update!(set, add, remove)
          # Linked tasks defer remote sync: persist the pending flag in the
          # same write as the local change so a crash cannot lose the replay.
          # The trigger mirrors sync_needed_after_update?: only changes that
          # require remote reconciliation (title/status/path/identity) count.
          # Reparents additionally persist the outgoing ID so replay can prove
          # ownership of a marker written under the previous task ID.
          # The deferred decision is computed under the issue + task locks
          # from reloaded state so a concurrent clear/link cannot leave a
          # pending flag with no remote_issue target.
          sync_relevant_keys = [set, add, remove].compact.flat_map(&:keys).map(&:to_s)
          sync_planned = move_to || move_as_child_of || (sync_relevant_keys & %w[title status]).any?
          current_path = task.path
          current_special = task.special_folder
          current_id = task.id
          linked = linked_issue(task)
          if linked && sync_planned
            # The pending flag, the relocation, and the post-relocation syncs
            # run under one hold of every linked participant's issue lock: a
            # replay slipping in between would sync the pre-move path, clear
            # the pending flag, and leave the remote marker stale with no
            # replay pending after a post-move stop.
            with_identity_locks(participant_identities(task)) do
              with_issue_identity_lock("task" => task.id) do
                fresh = show(task.id) || task
                linked_fresh = linked_issue(fresh)
                deferred_sync = linked_fresh && fresh.metadata["issue_sync_operation"] != "clear" && sync_planned
                deferred_set = deferred_sync ? set.merge("issue_sync_pending" => true) : set
                deferred_set = deferred_set.merge(
                  "issue_sync_previous_id" => fresh.metadata["issue_sync_previous_id"] || task.id
                ) if deferred_sync && move_as_child_of
                if has_field_updates || deferred_sync
                  Ace::Support::Items::Molecules::FieldUpdater.update(
                    fresh.file_path, set: deferred_set, add: add, remove: remove
                  )
                end
                early, current_path, current_special, current_id = apply_relocation_phase(
                  task, loader, current_path: task.path, current_special: task.special_folder,
                  current_id: task.id, move_to: move_to, move_as_child_of: move_as_child_of
                )
                return early if early
              end
            end
          else
            if has_field_updates
              Ace::Support::Items::Molecules::FieldUpdater.update(
                task.file_path, set: set, add: add, remove: remove
              )
            end
            early, current_path, current_special, current_id = apply_relocation_phase(
              task, loader, current_path: task.path, current_special: task.special_folder,
              current_id: task.id, move_to: move_to, move_as_child_of: move_as_child_of
            )
            return early if early
          end

          # Auto-archive hook: if a subtask status was set to terminal,
          # check if all siblings are terminal and auto-move parent to archive
          if set && set.key?("status")
            check_auto_archive(task, set["status"], loader)
          end

          # Reload and return updated task
          updated_task = loader.load(current_path, id: current_id, special_folder: current_special)
          if sync_needed_after_update?(task, updated_task, set: set, add: add, remove: remove, move_to: move_to)
            sync_failed_definitively = false
            with_issue_identity_lock(linked_issue(updated_task) || {}) do
              # Reload inside the lock: a concurrent clear may have removed
              # the link while this update waited; syncing the stale snapshot
              # would resurrect an orphaned remote marker.
              fresh = show(updated_task.id)
              if fresh.nil? || linked_issue(fresh).nil? ||
                  fresh.metadata["issue_sync_operation"] == "clear"
                next show_after_sync(updated_task) || updated_task
              end
              result = sync_linked_issues_for(fresh, reason: "update", previous_task: task)
              if result[:success] == false &&
                  result[:error].to_s.start_with?("Ace::Git::ProviderIdentityMismatchError")
                # Established links keep the stored identity for recovery and
                # stay pending; the identity was written before this update,
                # so there is no fresh mapping to roll back.
                Ace::Support::Items::Molecules::FieldUpdater.update(
                  fresh.file_path, set: {"issue_sync_pending" => true}
                )
                sync_failed_definitively = true
              end
            end
            raise Ace::Git::ProviderIdentityMismatchError, "Issue link rejected during update sync" if sync_failed_definitively
            return show_after_sync(updated_task) || updated_task
          end
          updated_task
        end

        # Relocate spec files (move_to or move_as_child_of). Pending flags for
        # every linked participant are written before the relocation and their
        # comments resynced after it. Callers hold the participants' issue
        # locks across the whole phase so a concurrent replay cannot clear a
        # pending flag mid-move and strand a stale remote marker.
        # Returns [early_result, current_path, current_special, current_id]:
        # early_result is a relocation that ends the update (reparent), nil
        # when the caller should continue with its own tail.
        def apply_relocation_phase(task, loader, current_path:, current_special:, current_id:,
          move_to:, move_as_child_of:)
          if move_to
            # Relocating a parent moves its children's files too: their issue
            # comments embed repo-relative links that just went stale. Flag
            # linked descendants pending (crash-safe, written pre-move) and
            # sync their comments from the post-move locations.
            linked_descendants_of(task.path, task.id).each do |child|
              with_issue_identity_lock(linked_issue(child) || {}) do
                Ace::Support::Items::Molecules::FieldUpdater.update(
                  child.file_path, set: {"issue_sync_pending" => true}
                )
              end
            end
            if archive_move_for_subtask?(task, move_to)
              result = handle_subtask_archive_move(task, loader)
              current_path = result[:path]
              current_special = result[:special_folder]
              current_id = result[:id]
            else
              mover = Ace::Support::Items::Molecules::FolderMover.new(@root_dir)
              new_path = if Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?(move_to)
                mover.move_to_root(task)
              else
                archive_date = parse_archive_date(task)
                mover.move(task, to: move_to, date: archive_date)
              end
              current_path = new_path
              current_special = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
                new_path, root: @root_dir
              )
            end
            linked_descendants_of(current_path, current_id).each do |child|
              with_issue_identity_lock(linked_issue(child) || {}) do
                fresh = show(child.id) || child
                sync_linked_issues_for(fresh, reason: "move") if linked_issue(fresh)
              end
            end
          end

          # Reparent if requested (mutually exclusive with move_to)
          if move_as_child_of
            reparenter = Molecules::TaskReparenter.new(root_dir: @root_dir, config: @config)
            resolve_fn = ->(r) { show(r) }
            # Reload task from current path before reparenting (may have been field-updated)
            task_for_reparent = loader.load(current_path, id: task.id, special_folder: current_special)
            # Demoting a parent relocates its descendants' files too; their
            # issue comment links need the same pending-and-sync treatment.
            linked_descendants_of(current_path, current_id).each do |descendant|
              with_issue_identity_lock(linked_issue(descendant) || {}) do
                Ace::Support::Items::Molecules::FieldUpdater.update(
                  descendant.file_path,
                  set: {"issue_sync_pending" => true,
                        "issue_sync_previous_id" => descendant.metadata["issue_sync_previous_id"] || descendant.id}
                )
              end
            end
            reparented = reparenter.reparent(task_for_reparent, target: move_as_child_of, resolve_ref: resolve_fn)
            if linked_issue(task) && linked_issue(reparented).nil?
              # Orchestrator conversion: the linked spec became a child that
              # retains the remote_issue mapping (and the pending transfer
              # metadata). Sync that child, not the newly created parent.
              scanner = Molecules::TaskScanner.new(@root_dir)
              converted_child = scanner.scan_subtasks(reparented.path, parent_id: reparented.id)
                .filter_map { |sr| loader.load(sr.dir_path, id: sr.id, special_folder: sr.special_folder) }
                .find { |t| linked_issue(t) }
              if converted_child
                with_issue_identity_lock(linked_issue(converted_child) || {}) do
                  sync_linked_issues_for(converted_child, reason: "reparent", previous_task: task)
                end
                # Other linked descendants of the converted parent keep their
                # identities; refresh their comments from the new layout too.
                linked_descendants_of(reparented.path, reparented.id)
                  .reject { |descendant| descendant.id == converted_child.id }
                  .each do |descendant|
                    with_issue_identity_lock(linked_issue(descendant) || {}) do
                      fresh = show(descendant.id) || descendant
                      sync_linked_issues_for(fresh, reason: "reparent") if linked_issue(fresh)
                    end
                  end
                return [show_after_sync(converted_child) || converted_child,
                  current_path, current_special, current_id]
              end
            end
            with_issue_identity_lock(linked_issue(reparented) || {}) do
              sync_linked_issues_for(reparented, reason: "reparent", previous_task: task)
            end
            linked_descendants_of(reparented.path, reparented.id).each do |descendant|
              with_issue_identity_lock(linked_issue(descendant) || {}) do
                fresh = show(descendant.id) || descendant
                sync_linked_issues_for(fresh, reason: "reparent") if linked_issue(fresh)
              end
            end
            return [show_after_sync(reparented) || reparented, current_path, current_special, current_id]
          end

          [nil, current_path, current_special, current_id]
        end

        # Every linked identity a relocation of this task touches: the task's
        # own link plus each linked descendant's.
        def participant_identities(task)
          [linked_issue(task)] + linked_descendants_of(task.path, task.id)
            .filter_map { |child| linked_issue(child) }
        end

        # Acquire identity locks in one stable sorted order so concurrent
        # relocations cannot deadlock on opposite orders; nested acquisitions
        # of held identities are re-entrant no-ops.
        def with_identity_locks(identities, &block)
          ordered = identities.compact.sort_by do |identity|
            identity.values_at("server_name", "provider", "repository_url", "number").join("--")
          end
          return block.call if ordered.empty?

          with_issue_identity_lock(ordered.first) do
            with_identity_locks(ordered[1..], &block)
          end
        end

        # Reload persisted metadata after synchronization: the in-memory task
        # predates the pending-flag clear that a successful sync performs.
        def show_after_sync(task)
          return nil unless task

          show(task.id)
        end

        # Direct linked subtasks of a task directory (used to refresh their
        # issue comment links after the parent directory relocates).
        # Linked descendants at any depth (a grandchild under an unlinked
        # child still holds a remote comment whose path went stale).
        def linked_descendants_of(path, id)
          scanner = Molecules::TaskScanner.new(@root_dir)
          loader = Molecules::TaskLoader.new
          collect = lambda do |p, i|
            scanner.scan_subtasks(p, parent_id: i).flat_map do |sr|
              child = loader.load(sr.dir_path, id: sr.id, special_folder: sr.special_folder)
              next [] unless child

              deeper = collect.call(sr.dir_path, sr.id)
              linked_issue(child) ? [child] + deeper : deeper
            end
          end
          collect.call(path, id)
        end

        # Create a subtask within a parent task.
        # @param parent_ref [String] Parent task reference
        # @param title [String] Subtask title
        # @param status [String, nil] Initial status
        # @param priority [String, nil] Priority level
        # @param tags [Array<String>] Tags
        # @return [Models::Task, nil] Created subtask or nil if parent not found
        def create_subtask(parent_ref, title, status: nil, priority: nil, tags: [], estimate: nil, remote_issue: nil)
          parent = show(parent_ref)
          return nil unless parent

          # Authoritative validation precedes the write: the spec forbids
          # leaving an unvalidated offline link after a failed command.
          ensure_issue_linkable!(remote_issue) if remote_issue
          subtask_creator = Molecules::SubtaskCreator.new(config: @config)
          created_subtask = subtask_creator.create(
            parent,
            title,
            status: status,
            priority: priority,
            tags: tags,
            estimate: estimate,
            remote_issue: remote_issue
          )
          sync_started = false
          begin
            result = nil
            with_issue_identity_lock(remote_issue) do
              ensure_issue_linkable!(remote_issue) if remote_issue
              ensure_issue_not_linked_elsewhere!(remote_issue, exclude_id: created_subtask.id) if remote_issue
              sync_started = true
              result = sync_linked_issues_for(created_subtask, reason: "create")
            end
            if result[:success] == false && result[:error].to_s.start_with?("Ace::Git::ProviderIdentityMismatchError")
              FileUtils.rm_rf(created_subtask.path)
              raise Ace::Git::ProviderIdentityMismatchError, result[:error].to_s
            end
          rescue StandardError
            # Any pre-sync failure (unreachable validation included) must not
            # leave an artifact claiming a link that was never validated; once
            # sync has begun the remote marker may exist, so retain the task
            # and its pending identity as the recovery record.
            FileUtils.rm_rf(created_subtask.path) unless sync_started
            raise
          end
          show_after_sync(created_subtask) || created_subtask
        end

        def issue_sync(ref: nil, all: false, pending: false)
          raise ArgumentError, "Provide --all or a task reference" if !all && !pending && (ref.nil? || ref.strip.empty?)
          raise ArgumentError, "--all and --pending are mutually exclusive" if all && pending
          raise ArgumentError, "REF cannot be combined with --all or --pending" if ref && (all || pending)

          if all || pending
            tasks = all_tasks_including_subtasks
            tasks = tasks.select { |t| t.metadata["issue_sync_pending"] } if pending
            linked_tasks = tasks.select { |t| linked_issue(t) }
            results = linked_tasks.map do |task|
              locked_identity = linked_issue(task)
              with_issue_identity_lock(locked_identity || {}) do
                # Reload inside the lock: another process may have cleared,
                # synced, or REPLACED this link while this replay waited. A
                # replaced identity must not be mutated under the old lock.
                fresh = show(task.id)
                if fresh.nil?
                  # A concurrent reparent changed the task's ID; report a
                  # retryable failure rather than claiming a sync that never
                  # happened.
                  next sync_result_for(task: task, issues: [locked_identity].compact, success: false,
                    reason: "manual-sync", error: "Task relocated during replay; retry the command")
                end

                if linked_issue(fresh) != locked_identity
                  next sync_result_for(task: fresh, issues: [locked_identity].compact, success: false,
                    reason: "manual-sync", error: "Issue link changed during replay; retry the command")
                end

                sync_or_clear_linked_issue(fresh, reason: "manual-sync")
              end
            end
            # An unlinked task with a pending flag is inconsistent state: it
            # fails in every mode (matching REF and --pending semantics).
            inconsistent = (tasks - linked_tasks).select { |t| t.metadata["issue_sync_pending"] }
            results.concat(inconsistent.map do |task|
              sync_result_for(task: task, issues: [], success: false,
                reason: "manual-sync", error: "Pending task has no remote_issue recovery identity")
            end)
            skipped = tasks.length - linked_tasks.length - inconsistent.length
            return summarize_manual_sync_results(results, skipped: pending ? 0 : skipped)
          end

          task = show(ref)
          return nil unless task

          unless linked_issue(task)
            if task.metadata["issue_sync_pending"]
              # Inconsistent state: pending without a recovery identity is a
              # failure, not a skip (the CLI must exit nonzero).
              return {synced: 0, failed: 1, pending: 0, skipped: 0, task_id: task.id,
                      failures: [{task_id: task.id, remote_issues: [], error: "Pending task has no remote_issue recovery identity"}]}
            end
            return {synced: 0, failed: 0, pending: 0, skipped: 1, task_id: task.id, failures: []}
          end

          locked_identity = linked_issue(task)
          result = with_issue_identity_lock(locked_identity || {}) do
            fresh = show(task.id)
            if fresh.nil?
              return {synced: 0, failed: 1, pending: 0, skipped: 0, task_id: task.id,
                      failures: [{task_id: task.id, remote_issues: [locked_identity].compact,
                                  error: "Task relocated during replay; retry the command"}]}
            end
            if linked_issue(fresh) != locked_identity
              return {synced: 0, failed: 1, pending: 0, skipped: 0, task_id: task.id,
                      failures: [{task_id: task.id, remote_issues: [locked_identity].compact,
                                  error: "Issue link changed during replay; retry the command"}]}
            end
            sync_or_clear_linked_issue(fresh || task, reason: "manual-sync")
          end
          summary = summarize_manual_sync_results([result], skipped: 0)
          summary.merge(task_id: task.id)
        end

        def issue_link(ref, issue: nil, clear: false, server_name: nil, use_default: false)
          raise ArgumentError, "Choose --issue or --clear" if (issue.nil? && !clear) || (issue && clear)
          task = show(ref)
          return nil unless task

          current = linked_issue(task)
          if clear
            raise ArgumentError, "Task #{task.id} has no remote issue" unless current
            clear_issue_link(task)
            return show(ref)
          end

          identity = Molecules::IssueLink.from_input(issue, server_name: server_name, use_default: use_default)
          # Lock order is issue-first everywhere; the task transition lock
          # nests inside so concurrent link/clear/replay serialize.
          with_issue_identity_lock(identity) do
            with_issue_identity_lock("task" => task.id) do
              # Reload: a concurrent link may have changed this task's state
              # while this call waited for the locks.
              task = show(ref) || task
              current = linked_issue(task)
              issue_link_locked(task, identity, current, ref: ref,
                server_name: server_name, use_default: use_default)
            end
          end
          show(ref)
        end

        def issue_link_locked(task, identity, current, ref:, server_name:, use_default:)
          if current
            if current == identity
              if task.metadata["issue_sync_operation"] == "clear"
                raise Ace::Git::ProviderIdentityMismatchError,
                  "Task #{task.id} has a pending clear; complete it before linking again"
              end
              # A completed identical link (synced, no pending operations)
              # is idempotent: return the current task without touching the
              # forge. Guarded (reconcile-create) and pending-clear links
              # keep the recovery paths below.
              if task.metadata["issue_sync_pending"] != true &&
                  task.metadata["issue_sync_operation"] != "clear" &&
                  task.metadata["issue_sync_operation"] != "reconcile-create"
                return show(ref)
              end
              # An explicit identical-link retry is the documented recovery
              # for a create that never committed. Reconcile first so a slow
              # commit is adopted rather than duplicated; only after the
              # reconcile window finds no marker does the retry authorize a
              # fresh create. Failed validation retains the guard.
              if task.metadata["issue_sync_operation"] == "reconcile-create"
                reconciled = sync_linked_issues_for(task, reason: "link-retry-reconcile")
                if reconciled[:success]
                  return show_after_sync(task) || task
                end
                # Only authoritative absence (reads succeeded, marker never
                # appeared) authorizes a fresh create. Unreadable forges keep
                # the guard so a later pending replay can adopt a slow commit.
                unless reconciled[:error].to_s.start_with?("Ace::Git::ProviderUnknownOutcomeError")
                  raise Ace::Git::ProviderUnreachableError, reconciled[:error]
                end
                Ace::Support::Items::Molecules::FieldUpdater.update(
                  task.file_path, set: {"issue_sync_operation" => nil}
                )
                task = show(ref)
              end
              ensure_issue_linkable!(identity, task_id: task.id,
                previous_task_id: task.metadata["issue_sync_previous_id"])
              result = sync_linked_issues_for(task, reason: "link-retry")
              raise Ace::Git::ProviderUnreachableError, result[:error] unless result[:success]
              return show(ref)
            end

            raise Ace::Git::ProviderIdentityMismatchError,
              "Task #{task.id} already links another issue; clear it before linking a different issue"
          end
          with_issue_identity_lock(identity) do
            ensure_issue_linkable!(identity, task_id: task.id)
            ensure_issue_not_linked_elsewhere!(identity, exclude_id: task.id)
            Ace::Support::Items::Molecules::FieldUpdater.update(
              task.file_path, set: {"remote_issue" => identity, "issue_sync_pending" => true}
            )
            linked = show(ref)
            result = sync_linked_issues_for(linked, reason: "link")
            if result[:success] == false &&
                result[:error].to_s.start_with?("Ace::Git::ProviderIdentityMismatchError")
              # Definitive pre-mutation rejection (sync validates ownership
              # before touching the forge): roll back the freshly written
              # mapping so no local claim survives for an issue this task
              # never owned.
              Ace::Support::Items::Molecules::FieldUpdater.update(
                linked.file_path, set: {"remote_issue" => nil, "issue_sync_pending" => nil}
              )
              raise Ace::Git::ProviderIdentityMismatchError, result[:error].to_s
            end
            raise Ace::Git::ProviderUnreachableError, result[:error] unless result[:success]
          end

          show_after_sync(show(ref) || task) || show(ref) || task
        end

        # Get the root directory.
        # @return [String] Absolute path to tasks root
        attr_reader :root_dir

        private

        def load_config
          Molecules::TaskConfigLoader.load
        end

        def resolve_root_dir
          Molecules::TaskConfigLoader.root_dir(@config)
        end

        def ensure_root_dir
          require "fileutils"
          FileUtils.mkdir_p(@root_dir) unless Dir.exist?(@root_dir)
        end

        def resolve_scan_result(ref)
          scanner = Molecules::TaskScanner.new(@root_dir)
          scan_results = scanner.scan
          resolver = Molecules::TaskResolver.new(scan_results)
          resolver.resolve(ref)
        end

        def apply_sort(tasks, sort_mode)
          case sort_mode
          when "smart"
            smart_sort(tasks)
          when "id"
            tasks.sort_by(&:id)
          when "priority"
            priority_order = {"critical" => 0, "high" => 1, "medium" => 2, "low" => 3}
            tasks.sort_by { |t| priority_order[t.priority] || 99 }
          when "created"
            tasks.sort_by { |t| t.created_at || Time.at(0) }
          else
            tasks
          end
        end

        def smart_sort(tasks)
          result = Molecules::DependencyAwareSmartSorter.sort(
            tasks,
            score_fn: method(:compute_task_score),
            pin_accessor: ->(t) { t.metadata&.dig("position") },
            external_statuses: external_dep_statuses(tasks)
          )
          @last_list_cycle_ids = result.cycle_ids
          result.tasks
        end

        # Load statuses for dependency references pointing outside the current
        # listing (e.g. archived tasks), so smart sort can classify them as
        # satisfied or unmet.
        def external_dep_statuses(tasks)
          listed_ids = {}
          tasks.each { |t| listed_ids[t.id] = true }
          external_ids = tasks.flat_map { |t| Array(t.dependencies) }.uniq - listed_ids.keys
          return {} if external_ids.empty?

          by_id = {}
          @last_scan_results.each { |sr| by_id[sr.id] = sr }

          loader = Molecules::TaskLoader.new
          external_ids.each_with_object({}) do |dep_id, statuses|
            scan_result = by_id[dep_id]
            next unless scan_result

            dep = loader.load(scan_result.dir_path, id: scan_result.id, special_folder: scan_result.special_folder)
            statuses[dep_id] = [dep.status, dep.special_folder] if dep
          end
        end

        def compute_task_score(task)
          weight = Ace::Support::Items::Atoms::SortScoreCalculator.priority_weight(task.priority)
          age = if task.created_at
            [(Time.now - task.created_at) / 86_400.0, 0].max
          else
            0
          end
          Ace::Support::Items::Atoms::SortScoreCalculator.compute(
            priority_weight: weight,
            age_days: age,
            status: task.status
          )
        end

        def filter_by_tags(tasks, tags)
          return tasks if tags.empty?

          tasks.select do |task|
            tags.any? { |tag| task.tags.include?(tag) }
          end
        end

        # Auto-archive: if a subtask reaches terminal status and all siblings
        # in the parent directory are also terminal, move the parent to archive.
        def check_auto_archive(task, new_status, loader)
          terminal = Ace::Support::Items::Atoms::FolderCompletionDetector::TERMINAL_STATUSES
          return unless terminal.include?(new_status.to_s.downcase)

          # Only applies to subtasks (task dir is nested inside a parent dir)
          parent_dir = File.dirname(task.path)
          return if File.expand_path(parent_dir) == File.expand_path(@root_dir)

          # Check if all specs in the parent dir (recursive for subtask subdirs) are terminal
          return unless Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(
            parent_dir, recursive: true
          )

          parent = load_parent_from_directory(parent_dir, loader)
          return unless parent

          archive_parent_via_update(parent)
        end

        def parse_archive_date(task)
          raw = task.metadata["completed_at"] || task.metadata["created_at"]
          return nil unless raw

          case raw
          when Time then raw
          when DateTime then raw.to_time
          else begin
            Time.parse(raw.to_s)
          rescue
            nil
          end
          end
        end

        def archive_move_for_subtask?(task, move_to)
          normalized = Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(move_to)
          task.subtask? && normalized == "_archive"
        end

        def handle_subtask_archive_move(task, loader)
          parent = show(task.parent_id)
          unless parent
            @last_update_note = "Subtask #{task.id} was not archived because parent task '#{task.parent_id}' was not found."
            return {
              path: task.path,
              special_folder: task.special_folder,
              id: task.id
            }
          end

          parent_with_subtasks = loader.load(parent.path, id: parent.id, special_folder: parent.special_folder)
          subtasks = parent_with_subtasks&.subtasks || []
          all_terminal = subtasks.any? &&
            subtasks.all? { |st| Atoms::TaskValidationRules.terminal_status?(st.status.to_s.downcase) }

          unless all_terminal
            @last_update_note = "Subtask #{task.id} was not archived because sibling subtasks are not all terminal."
            return {
              path: task.path,
              special_folder: task.special_folder,
              id: task.id
            }
          end

          archived_parent = archive_parent_via_update(parent)
          return {
            path: task.path,
            special_folder: task.special_folder,
            id: task.id
          } unless archived_parent

          @last_update_note = "Archived parent task #{parent.id} because all subtasks are terminal."
          {
            path: File.join(archived_parent.path, File.basename(task.path)),
            special_folder: archived_parent.special_folder,
            id: task.id
          }
        end

        def archive_parent_via_update(parent)
          previous_note = @last_update_note
          archived_parent = update(
            parent.id,
            set: {"status" => "done"},
            move_to: "archive"
          )

          if archived_parent && @last_update_note == previous_note
            @last_update_note = "Archived parent task #{parent.id} because all subtasks are terminal."
          end

          archived_parent
        end

        def load_parent_from_directory(parent_dir, loader)
          parent_id = File.basename(parent_dir).split("-", 2).first
          return nil unless parent_id

          parent_special = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
            parent_dir, root: @root_dir
          )
          loader.load(parent_dir, id: parent_id, special_folder: parent_special)
        end

        # Value accessor for FilterApplier
        def task_value_accessor(item, key)
          case key
          when "status" then item.status
          when "title" then item.title
          when "tags" then item.tags
          when "id" then item.id
          when "priority" then item.priority
          when "estimate" then item.estimate
          when "special_folder" then item.special_folder
          else
            item.metadata[key] || item.metadata[key.to_sym] if item.respond_to?(:metadata) && item.metadata
          end
        end

        def sync_needed_after_update?(before_task, after_task, set:, add:, remove:, move_to:)
          return false unless after_task
          return true if move_to
          return true if before_task.path != after_task.path
          return true if linked_issue(before_task) != linked_issue(after_task)

          touched_keys = [set, add, remove].compact.flat_map(&:keys).map(&:to_s)
          touched_keys.any? do |key|
            key == "title" || key == "status"
          end
        end

        def linked_issue(task)
          task&.metadata&.[]("remote_issue")
        end

        def reject_issue_metadata_update!(*changes)
          keys = changes.compact.flat_map(&:keys).map(&:to_s)
          forbidden = keys.find do |key|
            key == "remote_issue" || key.start_with?("remote_issue.") ||
              %w[issue_sync_pending issue_sync_previous_id issue_sync_operation github_issue github_sync_pending].include?(key)
          end
          raise ArgumentError, "Use ace-task issue-link to change #{forbidden}" if forbidden
        end

        def issue_adapter
          require_relative "../molecules/issue_sync_adapter"
          Molecules::IssueSyncAdapter.new
        end

        def ensure_issue_linkable!(identity, task_id: nil, previous_task_id: nil)
          issue_adapter.validate_link!(identity: identity, task_id: task_id, previous_task_id: previous_task_id)
        end

        # One task owns at most one exact issue: reject a second local task
        # holding the same identity even when the first link is still pending
        # and has therefore written no remote owner marker yet.
        def ensure_issue_not_linked_elsewhere!(identity, exclude_id: nil)
          target = identity.slice("server_name", "provider", "repository_url", "number")
          all_tasks_including_subtasks.each do |task|
            next if exclude_id && task.id == exclude_id.to_s

            existing = task.metadata["remote_issue"]
            next unless existing.is_a?(Hash) && (existing["number"] || existing[:number]).to_s == target["number"].to_s

            held = {
              "server_name" => (existing["server_name"] || existing[:server_name]).to_s,
              "provider" => (existing["provider"] || existing[:provider]).to_s,
              "repository_url" => (existing["repository_url"] || existing[:repository_url]).to_s,
              "number" => (existing["number"] || existing[:number]).to_s
            }
            next unless held.values == target.values.map(&:to_s)

            raise Ace::Git::ProviderIdentityMismatchError,
              "Issue ##{target["number"]} on #{target["server_name"]} is already linked to task #{task.id}"
          end
        end

        # Serialize link operations per exact issue identity: ownership
        # validation, the local write, and the remote marker creation must not
        # interleave across processes, or two tasks can claim one issue.
        def with_issue_identity_lock(identity)
          return yield unless identity.is_a?(Hash)

          key = identity.values_at("server_name", "provider", "repository_url", "number")
            .map { |value| value.to_s.gsub(%r{[^\w.-]}, "_") }.join("--")
          held = (Thread.current[:ace_task_identity_locks] ||= [])
          return yield if held.include?(key)

          lock_path = File.join(Dir.tmpdir, "ace-task-issue-#{key}.lock")
          File.open(lock_path, File::CREAT | File::RDWR) do |lock|
            lock.flock(File::LOCK_EX)
            held << key
            begin
              yield
            ensure
              held.delete(key)
              lock.flock(File::LOCK_UN)
            end
          end
        end

        # Bulk issue sync must see linked subtasks too; TaskScanner#scan
        # excludes subtask folders, which would hide deferred child replays.
        # Descendants are traversed recursively (grandchildren included).
        def all_tasks_including_subtasks
          scanner = Molecules::TaskScanner.new(@root_dir)
          loader = Molecules::TaskLoader.new
          collect = lambda do |path, id, special_folder|
            primary = loader.load(path, id: id, special_folder: special_folder)
            descendants = scanner.scan_subtasks(path, parent_id: id).flat_map do |sub|
              collect.call(sub.dir_path, sub.id, sub.special_folder)
            end
            primary ? [primary] + descendants : descendants
          end
          scanner.scan.flat_map { |sr| collect.call(sr.dir_path, sr.id, sr.special_folder) }
        end

        # Provider outcomes that conclusively prove a create POST never
        # committed. Everything else (unknown outcome, unreachable reads)
        # keeps the reconcile-create guard so replay reconciles instead of
        # duplicating the comment.
        DEFINITIVE_CREATE_OUTCOME_ERRORS = [
          Ace::Git::ProviderAuthenticationError,
          Ace::Git::ProviderObjectNotFoundError
        ].freeze

        def sync_linked_issues_for(task, reason:, previous_task: nil)
          identity = linked_issue(task)
          return sync_result_for(task: task, issues: [], success: true, reason: reason) unless identity

          if task.metadata["issue_sync_operation"] == "clear"
            @last_update_note = "Issue clear pending for task #{task.id}; replay with 'ace-task issue-sync --pending'"
            return sync_result_for(task: task, issues: [identity], success: false,
              reason: reason, error: "Pending clear must be replayed")
          end
          previous_id = task.metadata["issue_sync_previous_id"] || previous_task&.id
          reconcile_only = task.metadata["issue_sync_operation"] == "reconcile-create"
          reached_post = false
          locked_identity = linked_issue(task)
          issue_adapter.sync_task(
            task: task, previous_task_id: previous_id,
            before_create: lambda do
              mark_issue_sync_pending(task)
              reached_post = true
              Ace::Support::Items::Molecules::FieldUpdater.update(
                task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
              )
            end
          )
          # The caller holds the locked identity's lock; a link changed to a
          # different issue mid-sync would have mutated B without its lock.
          if locked_identity && linked_issue(task) != locked_identity
            raise Ace::Git::ProviderIdentityMismatchError,
              "Task #{task.id} link changed during sync; retry the command"
          end
          clear_issue_sync_pending(task)
          sync_result_for(task: task, issues: [identity], success: true, reason: reason)
        rescue Ace::Git::ProviderUnknownOutcomeError => e
          # Only an uncertain comment creation blocks a second POST; label or
          # state updates are idempotent and need no create guard.
          mark_issue_sync_pending(task)
          if reached_post
            Ace::Support::Items::Molecules::FieldUpdater.update(
              task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
            )
          end
          @last_update_note = "Issue sync warning for task #{task&.id}: #{e.class}: #{e.message}; " \
            "flagged for 'ace-task issue-sync --pending'"
          sync_result_for(task: task, issues: [identity].compact, success: false,
            reason: reason, error: "#{e.class}: #{e.message}")
        rescue StandardError => e
          mark_issue_sync_pending(task)
          # Only a definitive provider rejection of the create POST itself
          # (auth failure, object-not-found) proves it did not commit; the
          # guard then clears so replay may retry. Unknown outcomes and
          # unreachable reconciliation reads keep the guard: the first POST
          # may still commit and a second one would duplicate the comment.
          if reached_post && !reconcile_only &&
              DEFINITIVE_CREATE_OUTCOME_ERRORS.any? { |klass| e.is_a?(klass) }
            Ace::Support::Items::Molecules::FieldUpdater.update(
              task.file_path, set: {"issue_sync_operation" => nil}
            )
          end
          @last_update_note = "Issue sync warning for task #{task&.id}: #{e.class}: #{e.message}; " \
            "flagged for 'ace-task issue-sync --pending'"
          sync_result_for(task: task, issues: [identity].compact, success: false,
            reason: reason, error: "#{e.class}: #{e.message}")
        end

        def mark_issue_sync_pending(task)
          return unless task&.file_path && File.exist?(task.file_path)

          Ace::Support::Items::Molecules::FieldUpdater.update(
            task.file_path, set: {"issue_sync_pending" => true}
          )
        end

        def clear_issue_sync_pending(task)
          return unless task&.file_path && File.exist?(task.file_path)

          Ace::Support::Items::Molecules::FieldUpdater.update(
            task.file_path,
            set: {"issue_sync_pending" => nil, "issue_sync_previous_id" => nil,
                  "issue_sync_operation" => nil}
          )
        end

        def clear_issue_link(task)
          # Lock order is issue-first everywhere (link, sync, clear) so
          # concurrent clear and replay cannot deadlock on opposite orders.
          locked_identity = linked_issue(task)
          with_issue_identity_lock(locked_identity || {}) do
            with_issue_identity_lock("task" => task.id) do
              fresh = show(task.id) || task
              # If the link changed while this clear waited (A cleared, B
              # linked), reject the stale request so the new link's marker is
              # only cleared under its own lock.
              if locked_identity.is_a?(Hash) && linked_issue(fresh) != locked_identity
                raise Ace::Git::ProviderIdentityMismatchError,
                  "Task #{task.id} link changed during clear; retry the command"
              end
              clear_issue_link_locked(fresh)
            end
          end
        end

        def clear_issue_link_locked(task)
          if task.metadata["issue_sync_operation"] == "reconcile-create"
            # A tracking comment may still be committing forge-side; dropping
            # the link now would orphan it. Reconcile comment ownership only -
            # clear must never change issue state as a side effect.
            issue_adapter.reconcile_comment(task: task)
          end
          Ace::Support::Items::Molecules::FieldUpdater.update(task.file_path,
            set: {"issue_sync_pending" => true, "issue_sync_operation" => "clear"})
          issue_adapter.clear_task(task: task, previous_task_id: task.metadata["issue_sync_previous_id"])
          Ace::Support::Items::Molecules::FieldUpdater.update(task.file_path,
            set: {"remote_issue" => nil, "issue_sync_pending" => nil,
                  "issue_sync_operation" => nil, "issue_sync_previous_id" => nil})
        end

        def sync_or_clear_linked_issue(task, reason:)
          return sync_linked_issues_for(task, reason: reason) unless task.metadata["issue_sync_operation"] == "clear"

          identity = linked_issue(task)
          clear_issue_link(task)
          sync_result_for(task: task, issues: [identity], success: true, reason: reason)
        rescue StandardError => e
          sync_result_for(task: task, issues: [identity].compact, success: false,
            reason: reason, error: "#{e.class}: #{e.message}")
        end

        def sync_result_for(task:, issues:, success:, reason:, error: nil)
          {
            task_id: task&.id,
            issue_ids: issues,
            success: success,
            reason: reason,
            error: error
          }
        end

        def summarize_manual_sync_results(results, skipped:)
          failures = results.reject { |result| result[:success] }
          # A failed sync persists issue_sync_pending; classify it as pending
          # (recoverable) rather than failed so replay counts stay truthful.
          pending = failures.count do |result|
            show(result[:task_id])&.metadata&.[]("issue_sync_pending") == true
          end
          failures_detail = failures.map do |result|
            {
              task_id: result[:task_id],
              remote_issues: result[:issue_ids],
              error: result[:error]
            }
          end

          {
            synced: results.length - failures.length,
            failed: failures.length - pending,
            pending: pending,
            skipped: skipped,
            failures: failures_detail
          }
        end
      end
    end
  end
end
