# frozen_string_literal: true

require "ace/support/items"
require "ace/b36ts"

module Ace
  module Task
    module Molecules
      # Loads a single task from its directory.
      # Parses the spec file frontmatter and content into a Task model.
      # Detects subtasks from folder co-location.
      class TaskLoader
        # Load a task from a directory
        # @param dir_path [String] Path to the task directory
        # @param id [String] Formatted task ID (e.g., "8pp.t.q7w")
        # @param special_folder [String, nil] Special folder name if applicable
        # @param load_subtasks [Boolean] Whether to scan for subtask directories (default: true)
        # @return [Models::Task] Loaded task
        def load(dir_path, id:, special_folder: nil, load_subtasks: true)
          spec_files = Dir.glob(File.join(dir_path, "*.s.md"))
          return nil if spec_files.empty?

          # Find primary spec file matching the folder ID
          spec_file = find_primary_spec(spec_files, id) || spec_files.first
          content = File.read(spec_file)

          # Parse frontmatter
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)

          # Extract title from body
          title = Ace::Support::Items::Atoms::TitleExtractor.extract(body) ||
                  frontmatter["title"] ||
                  File.basename(dir_path)

          # Decode creation time from raw b36ts
          created_at = decode_created_at(id)

          # Detect parent_id from frontmatter
          parent_id = frontmatter["parent"]

          # Load subtasks from co-located directories
          subtasks = if load_subtasks && !parent_id
            load_subtask_dirs(dir_path, id, special_folder)
          else
            []
          end

          Models::Task.new(
            id: id,
            status: frontmatter["status"] || "pending",
            title: title,
            priority: frontmatter["priority"] || "medium",
            estimate: frontmatter["estimate"],
            dependencies: Array(frontmatter["dependencies"]),
            tags: Array(frontmatter["tags"]),
            content: body,
            path: dir_path,
            file_path: spec_file,
            special_folder: special_folder,
            created_at: created_at,
            subtasks: subtasks,
            parent_id: parent_id,
            metadata: frontmatter
          )
        end

        private

        # Find the primary spec file matching the task ID (not a subtask file).
        def find_primary_spec(spec_files, folder_id)
          spec_files.find do |f|
            Atoms::TaskFilePattern.primary_file?(File.basename(f), folder_id)
          end
        end

        def decode_created_at(id)
          raw_b36ts = Ace::Support::Items::Atoms::ItemIdFormatter.reconstruct(id)
          Ace::B36ts.decode(raw_b36ts)
        rescue StandardError
          nil
        end

        # Scan for subtask directories within the parent task directory.
        def load_subtask_dirs(parent_dir, parent_id, special_folder)
          subtask_dirs = find_subtask_dirs(parent_dir, parent_id)
          subtask_dirs.filter_map do |subtask_id, subtask_dir|
            load(subtask_dir, id: subtask_id, special_folder: special_folder, load_subtasks: false)
          end
        end

        # Find all subtask directories within a parent directory.
        # Returns array of [subtask_id, dir_path] pairs.
        def find_subtask_dirs(parent_dir, parent_id)
          results = []
          return results unless Dir.exist?(parent_dir)

          Dir.entries(parent_dir).sort.each do |entry|
            next if entry.start_with?(".")

            full_path = File.join(parent_dir, entry)
            next unless File.directory?(full_path)

            # Match subtask folder pattern: "8pp.t.q7w.a-slug"
            match = entry.match(/^([0-9a-z]{3}\.[a-z]\.[0-9a-z]{3}\.[a-z0-9])-?/)
            next unless match

            subtask_id = match[1]
            next unless subtask_id.start_with?(parent_id + ".")

            results << [subtask_id, full_path]
          end

          results
        end
      end
    end
  end
end
