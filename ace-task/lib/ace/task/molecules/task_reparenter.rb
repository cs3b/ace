# frozen_string_literal: true

require "fileutils"
require_relative "../atoms/task_id_formatter"
require_relative "task_loader"
require_relative "subtask_creator"

module Ace
  module Task
    module Molecules
      # Reparents tasks: promote subtask to standalone, convert to orchestrator,
      # or demote standalone to subtask of another task.
      class TaskReparenter
        # @param root_dir [String] Root directory for tasks
        # @param config [Hash] Configuration hash
        def initialize(root_dir:, config: {})
          @root_dir = root_dir
          @config = config
        end

        # Reparent a task based on the target value.
        #
        # @param task [Models::Task] The task to reparent
        # @param target [String] "none" (promote), "self" (orchestrator), or a parent ref
        # @param resolve_ref [Proc] Callable that resolves a ref to a Task (for "<ref>" case)
        # @return [Models::Task] The reparented task at its new location
        def reparent(task, target:, resolve_ref:)
          case target.downcase
          when "none"
            promote_to_standalone(task)
          when "self"
            convert_to_orchestrator(task)
          else
            demote_to_subtask(task, parent_ref: target, resolve_ref: resolve_ref)
          end
        end

        private

        # Promote a subtask to a standalone task at root level.
        # Moves the folder to root, strips parent from frontmatter, assigns new standalone ID.
        def promote_to_standalone(task)
          unless task.subtask?
            raise ArgumentError, "Task #{task.id} is already a standalone task"
          end

          # Generate new standalone ID preserving the original timestamp
          raw_b36ts = Atoms::TaskIdFormatter.reconstruct(base_task_id(task.id))
          new_item_id = Atoms::TaskIdFormatter.format(raw_b36ts)
          new_id = new_item_id.formatted_id

          # Extract slug from current folder name
          slug = extract_slug(task.path, task.id)

          # Build new folder/file names
          new_folder_name = Atoms::TaskIdFormatter.folder_name(new_id, slug)
          new_dir = File.join(@root_dir, new_folder_name)

          raise ArgumentError, "Destination already exists: #{new_dir}" if File.exist?(new_dir)

          # Move the folder
          FileUtils.mv(task.path, new_dir)

          # Rename spec file and update frontmatter
          old_spec_basename = File.basename(task.file_path)
          new_spec_basename = "#{new_folder_name}.s.md"
          old_spec_in_new_dir = File.join(new_dir, old_spec_basename)
          new_spec_path = File.join(new_dir, new_spec_basename)

          File.rename(old_spec_in_new_dir, new_spec_path) if old_spec_basename != new_spec_basename

          # Update frontmatter: change ID, remove parent
          update_frontmatter(new_spec_path) do |fm|
            fm["id"] = new_id
            fm.delete("parent")
          end

          loader = TaskLoader.new
          loader.load(new_dir, id: new_id)
        end

        # Convert a standalone task into an orchestrator with itself as first subtask.
        # Creates orchestrator spec in current dir, renames current spec to subtask .a.
        def convert_to_orchestrator(task)
          if task.subtask?
            raise ArgumentError, "Cannot convert subtask #{task.id} to orchestrator — promote first"
          end

          slug = extract_slug(task.path, task.id)

          # Create subtask ID using first subtask char (0)
          next_char = SubtaskCreator::SUBTASK_CHARS[0]
          subtask_id = "#{task.id}.#{next_char}"
          subtask_folder_name = "#{next_char}-#{slug}"
          subtask_dir = File.join(task.path, subtask_folder_name)

          raise ArgumentError, "Subtask directory already exists: #{subtask_dir}" if File.exist?(subtask_dir)

          FileUtils.mkdir_p(subtask_dir)

          # Move current spec file into subtask dir with renamed filename
          subtask_spec_name = "#{subtask_id}-#{slug}.s.md"
          subtask_spec_path = File.join(subtask_dir, subtask_spec_name)
          FileUtils.mv(task.file_path, subtask_spec_path)

          # Update subtask frontmatter: new ID, add parent
          update_frontmatter(subtask_spec_path) do |fm|
            fm["id"] = subtask_id
            fm["parent"] = task.id
          end

          # Create orchestrator spec file
          orch_spec_name = "#{File.basename(task.path)}.s.md"
          orch_spec_path = File.join(task.path, orch_spec_name)

          orch_frontmatter = Atoms::TaskFrontmatterDefaults.build(
            id: task.id,
            status: task.status,
            priority: task.priority,
            tags: task.tags
          )
          orch_content = Ace::Support::Items::Atoms::FrontmatterSerializer.serialize(orch_frontmatter)
          File.write(orch_spec_path, "#{orch_content}\n\n# #{task.title}\n")

          loader = TaskLoader.new
          loader.load(task.path, id: task.id)
        end

        # Demote a standalone task to a subtask of another parent.
        def demote_to_subtask(task, parent_ref:, resolve_ref:)
          parent_task = resolve_ref.call(parent_ref)
          raise ArgumentError, "Parent task '#{parent_ref}' not found" unless parent_task

          if task.id == parent_task.id
            raise ArgumentError, "Cannot reparent task to itself"
          end

          # Allocate next subtask char
          existing_chars = scan_existing_subtask_chars(parent_task.path, parent_task.id)
          next_char = allocate_next_char(existing_chars)

          # Build new subtask ID
          new_id = "#{parent_task.id}.#{next_char}"
          slug = extract_slug(task.path, task.id)
          new_folder_name = "#{next_char}-#{slug}"
          new_dir = File.join(parent_task.path, new_folder_name)

          raise ArgumentError, "Destination already exists: #{new_dir}" if File.exist?(new_dir)

          # Move folder into parent
          FileUtils.mv(task.path, new_dir)

          # Rename spec file
          old_spec_basename = File.basename(task.file_path)
          new_spec_basename = "#{new_id}-#{slug}.s.md"
          old_spec_in_new_dir = File.join(new_dir, old_spec_basename)
          new_spec_path = File.join(new_dir, new_spec_basename)

          File.rename(old_spec_in_new_dir, new_spec_path) if old_spec_basename != new_spec_basename

          # Update frontmatter: new ID, set parent
          update_frontmatter(new_spec_path) do |fm|
            fm["id"] = new_id
            fm["parent"] = parent_task.id
          end

          loader = TaskLoader.new
          loader.load(new_dir, id: new_id)
        end

        # Extract the base task ID (without subtask char) from a potentially dotted ID
        # "8pp.t.q7w.a" => "8pp.t.q7w"
        def base_task_id(id)
          parts = id.split(".")
          if parts.length > 3
            parts[0..2].join(".")
          else
            id
          end
        end

        # Extract slug from folder path and task ID.
        def extract_slug(path, id)
          folder = File.basename(path)

          # Try full ID prefix first: "8pp.t.q7w.0-slug" or "8pp.t.q7w-slug"
          prefix = "#{id}-"
          return folder[prefix.length..] if folder.start_with?(prefix)

          # Try short format: "0-slug" (subtask char + dash + slug)
          parts = id.split(".")
          if parts.length > 3
            char_prefix = "#{parts.last}-"
            return folder[char_prefix.length..] if folder.start_with?(char_prefix)
          end

          folder
        end

        # Update frontmatter in a spec file, yielding the hash for modification.
        def update_frontmatter(file_path)
          content = File.read(file_path)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
          body = body.sub(/\A\n/, "")

          yield frontmatter

          new_content = Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, body)
          tmp_path = "#{file_path}.tmp.#{Process.pid}"
          File.write(tmp_path, new_content)
          File.rename(tmp_path, file_path)
        rescue StandardError
          File.unlink(tmp_path) if tmp_path && File.exist?(tmp_path)
          raise
        end

        # Reuse subtask char allocation logic from SubtaskCreator.
        def scan_existing_subtask_chars(parent_dir, _parent_id)
          chars = []
          return chars unless Dir.exist?(parent_dir)

          Dir.entries(parent_dir).sort.each do |entry|
            next if entry.start_with?(".")

            full_path = File.join(parent_dir, entry)
            next unless File.directory?(full_path)

            # Short format: "0-slug" or "a-slug"
            if (short_match = entry.match(/^([a-z0-9])-/))
              chars << short_match[1]
            end
          end

          chars
        end

        def allocate_next_char(existing_chars)
          SubtaskCreator::SUBTASK_CHARS.each do |char|
            return char unless existing_chars.include?(char)
          end

          raise RangeError, "Maximum number of subtasks (#{SubtaskCreator::MAX_SUBTASKS}) exceeded"
        end
      end
    end
  end
end
