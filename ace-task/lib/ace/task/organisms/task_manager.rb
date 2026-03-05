# frozen_string_literal: true

require_relative "../molecules/task_config_loader"
require_relative "../molecules/task_scanner"
require_relative "../molecules/task_resolver"
require_relative "../molecules/task_loader"
require_relative "../molecules/task_creator"
require_relative "../molecules/subtask_creator"
require_relative "../molecules/task_reparenter"
require_relative "../atoms/task_validation_rules"

module Ace
  module Task
    module Organisms
      # Orchestrates all task CRUD operations.
      # Entry point for task management with config-driven root directory.
      class TaskManager
        attr_reader :last_list_total, :last_folder_counts

        # @param root_dir [String, nil] Override root directory for tasks
        # @param config [Hash, nil] Override configuration
        def initialize(root_dir: nil, config: nil)
          @config = config || load_config
          @root_dir = root_dir || resolve_root_dir
          @last_update_note = nil
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
        def create(title, status: nil, priority: nil, tags: [], dependencies: [], use_llm_slug: false)
          ensure_root_dir
          creator = Molecules::TaskCreator.new(root_dir: @root_dir, config: @config)
          creator.create(title, status: status, priority: priority, tags: tags,
                         dependencies: dependencies, use_llm_slug: use_llm_slug)
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
        # @param sort [String] Sort order: "smart", "id", "priority", "created" (default: "smart")
        # @return [Array<Models::Task>] List of tasks
        def list(status: nil, in_folder: "next", tags: [], filters: nil, sort: "smart")
          scanner = Molecules::TaskScanner.new(@root_dir)
          scan_results = scanner.scan_in_folder(in_folder)
          @last_list_total = scanner.last_scan_total
          @last_folder_counts = scanner.last_folder_counts

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
          if has_field_updates
            Ace::Support::Items::Molecules::FieldUpdater.update(
              task.file_path, set: set, add: add, remove: remove
            )
          end

          # Apply move if requested
          current_path = task.path
          current_special = task.special_folder
          current_id = task.id
          if move_to
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
          end

          # Reparent if requested (mutually exclusive with move_to)
          if move_as_child_of
            reparenter = Molecules::TaskReparenter.new(root_dir: @root_dir, config: @config)
            resolve_fn = ->(r) { show(r) }
            # Reload task from current path before reparenting (may have been field-updated)
            task_for_reparent = loader.load(current_path, id: task.id, special_folder: current_special)
            return reparenter.reparent(task_for_reparent, target: move_as_child_of, resolve_ref: resolve_fn)
          end

          # Auto-archive hook: if a subtask status was set to terminal,
          # check if all siblings are terminal and auto-move parent to archive
          if set && set.key?("status")
            check_auto_archive(task, set["status"], loader)
          end

          # Reload and return updated task
          loader.load(current_path, id: current_id, special_folder: current_special)
        end

        # Create a subtask within a parent task.
        # @param parent_ref [String] Parent task reference
        # @param title [String] Subtask title
        # @param status [String, nil] Initial status
        # @param priority [String, nil] Priority level
        # @param tags [Array<String>] Tags
        # @return [Models::Task, nil] Created subtask or nil if parent not found
        def create_subtask(parent_ref, title, status: nil, priority: nil, tags: [])
          parent = show(parent_ref)
          return nil unless parent

          subtask_creator = Molecules::SubtaskCreator.new(config: @config)
          subtask_creator.create(parent, title, status: status, priority: priority, tags: tags)
        end

        # Get the root directory.
        # @return [String] Absolute path to tasks root
        def root_dir
          @root_dir
        end

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
            priority_order = { "critical" => 0, "high" => 1, "medium" => 2, "low" => 3 }
            tasks.sort_by { |t| priority_order[t.priority] || 99 }
          when "created"
            tasks.sort_by { |t| t.created_at || Time.at(0) }
          else
            tasks
          end
        end

        def smart_sort(tasks)
          Ace::Support::Items::Molecules::SmartSorter.sort(
            tasks,
            score_fn: method(:compute_task_score),
            pin_accessor: ->(t) { t.metadata&.dig("position") }
          )
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

          # Auto-move the parent folder to archive
          parent_stub = Struct.new(:path).new(parent_dir)
          mover = Ace::Support::Items::Molecules::FolderMover.new(@root_dir)
          mover.move(parent_stub, to: "archive")
        end

        def parse_archive_date(task)
          raw = task.metadata["completed_at"] || task.metadata["created_at"]
          return nil unless raw

          case raw
          when Time then raw
          when DateTime then raw.to_time
          else Time.parse(raw.to_s) rescue nil
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

          unless Atoms::TaskValidationRules.terminal_status?(parent.status.to_s.downcase)
            Ace::Support::Items::Molecules::FieldUpdater.update(
              parent.file_path, set: { "status" => "done" }
            )
            parent = loader.load(parent.path, id: parent.id, special_folder: parent.special_folder)
          end

          mover = Ace::Support::Items::Molecules::FolderMover.new(@root_dir)
          new_parent_path = mover.move(parent, to: "archive", date: parse_archive_date(parent))
          new_special_folder = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
            new_parent_path, root: @root_dir
          )

          @last_update_note = "Archived parent task #{parent.id} because all subtasks are terminal."
          {
            path: File.join(new_parent_path, File.basename(task.path)),
            special_folder: new_special_folder,
            id: task.id
          }
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
      end
    end
  end
end
