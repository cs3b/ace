# frozen_string_literal: true

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
          ensure_issue_linkable!(remote_issue) if remote_issue
          ensure_issue_not_linked_elsewhere!(remote_issue) if remote_issue
          ensure_root_dir
          creator = Molecules::TaskCreator.new(root_dir: @root_dir, config: @config)
          attempts = 0

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
            sync_linked_issues_for(created_task, reason: "create")
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
          sync_relevant_keys = [set, add, remove].compact.flat_map(&:keys).map(&:to_s)
          linked = linked_issue(task)
          deferred_sync = linked &&
            (move_to || move_as_child_of || (sync_relevant_keys & %w[title status]).any?)
          deferred_set = deferred_sync ? set.merge("issue_sync_pending" => true) : set
          # Any linked ID change records the outgoing ID - including pending
          # clears, whose remote marker still names the previous owner.
          deferred_set = deferred_set.merge(
            "issue_sync_previous_id" => task.metadata["issue_sync_previous_id"] || task.id
          ) if deferred_sync && move_as_child_of
          if has_field_updates || deferred_sync
            Ace::Support::Items::Molecules::FieldUpdater.update(
              task.file_path, set: deferred_set, add: add, remove: remove
            )
          end

          # Apply move if requested
          current_path = task.path
          current_special = task.special_folder
          current_id = task.id
          if move_to
            # Relocating a parent moves its children's files too: their issue
            # comments embed repo-relative links that just went stale. Flag
            # linked descendants pending (crash-safe, written pre-move) and
            # sync their comments from the post-move locations.
            linked_descendants_of(task.path, task.id).each do |child|
              Ace::Support::Items::Molecules::FieldUpdater.update(
                child.file_path, set: {"issue_sync_pending" => true}
              )
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
              sync_linked_issues_for(child, reason: "move")
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
            moved_descendants = linked_descendants_of(current_path, current_id)
            moved_descendants.each do |descendant|
              Ace::Support::Items::Molecules::FieldUpdater.update(
                descendant.file_path,
                set: {"issue_sync_pending" => true,
                      "issue_sync_previous_id" => descendant.metadata["issue_sync_previous_id"] || descendant.id}
              )
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
                sync_linked_issues_for(converted_child, reason: "reparent", previous_task: task)
                # Other linked descendants of the converted parent keep their
                # identities; refresh their comments from the new layout too.
                linked_descendants_of(reparented.path, reparented.id)
                  .reject { |descendant| descendant.id == converted_child.id }
                  .each { |descendant| sync_linked_issues_for(descendant, reason: "reparent") }
                return show_after_sync(converted_child) || converted_child
              end
            end
            sync_linked_issues_for(reparented, reason: "reparent", previous_task: task)
            linked_descendants_of(reparented.path, reparented.id).each do |descendant|
              sync_linked_issues_for(descendant, reason: "reparent")
            end
            return show_after_sync(reparented) || reparented
          end

          # Auto-archive hook: if a subtask status was set to terminal,
          # check if all siblings are terminal and auto-move parent to archive
          if set && set.key?("status")
            check_auto_archive(task, set["status"], loader)
          end

          # Reload and return updated task
          updated_task = loader.load(current_path, id: current_id, special_folder: current_special)
          if sync_needed_after_update?(task, updated_task, set: set, add: add, remove: remove, move_to: move_to)
            sync_linked_issues_for(updated_task, reason: "update", previous_task: task)
            return show_after_sync(updated_task) || updated_task
          end
          updated_task
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

          ensure_issue_linkable!(remote_issue) if remote_issue
          ensure_issue_not_linked_elsewhere!(remote_issue) if remote_issue
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
          sync_linked_issues_for(created_subtask, reason: "create")
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
            results = linked_tasks.map { |task| sync_or_clear_linked_issue(task, reason: "manual-sync") }
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

          result = sync_or_clear_linked_issue(task, reason: "manual-sync")
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
          if current
            if current == identity
              if task.metadata["issue_sync_operation"] == "clear"
                raise Ace::Git::ProviderIdentityMismatchError,
                  "Task #{task.id} has a pending clear; complete it before linking again"
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
          ensure_issue_linkable!(identity, task_id: task.id)
          ensure_issue_not_linked_elsewhere!(identity, exclude_id: task.id)
          Ace::Support::Items::Molecules::FieldUpdater.update(
            task.file_path, set: {"remote_issue" => identity, "issue_sync_pending" => true}
          )
          linked = show(ref)
          result = sync_linked_issues_for(linked, reason: "link")
          raise Ace::Git::ProviderUnreachableError, result[:error] unless result[:success]

          show_after_sync(linked) || linked
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
