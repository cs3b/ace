# frozen_string_literal: true

require_relative "../atoms/yaml_parser"
require_relative "../atoms/path_builder"

module Ace
  module Taskflow
    module Molecules
      # Load and parse task files
      class TaskLoader
        attr_reader :root_path

        def initialize(root_path = nil)
          @root_path = root_path || default_root_path
        end

        # Load a single task file
        # @param path [String] Path to the task file
        # @return [Hash, nil] Task data or nil if not found
        def load_task(path)
          return nil unless File.exist?(path)

          content = File.read(path)
          parsed = Atoms::YamlParser.parse(content)

          frontmatter = parsed[:frontmatter]
          body_content = parsed[:content]

          # Extract task number and context from path
          task_number = Atoms::PathBuilder.extract_task_number(path)
          context = Atoms::PathBuilder.extract_context(path)

          # Build task data
          {
            id: frontmatter["id"],
            status: frontmatter["status"] || "pending",
            priority: frontmatter["priority"] || "medium",
            estimate: frontmatter["estimate"],
            dependencies: frontmatter["dependencies"] || [],
            sort: frontmatter["sort"],
            title: extract_title(body_content),
            content: body_content,
            path: path,
            task_number: task_number,
            context: context,
            metadata: frontmatter
          }
        rescue StandardError => e
          nil
        end

        # Load all tasks from a release or context
        # @param context_path [String] Path to the release or context
        # @return [Array<Hash>] Array of task data
        def load_tasks_from_context(context_path)
          tasks = []
          task_dir = File.join(context_path, "t")

          return tasks unless File.directory?(task_dir)

          # Iterate through task directories
          # Supports both old format (t/001/) and new format (t/001-feat-taskflow/)
          Dir.glob(File.join(task_dir, "*")).select { |d| File.directory?(d) }.each do |task_folder|
            # Find .md files in the task folder (not in subfolders)
            md_files = Dir.glob(File.join(task_folder, "*.md"))

            # Find the task file - the one with YAML frontmatter containing task metadata
            task_file = md_files.find do |file|
              has_task_frontmatter?(file)
            end

            if task_file
              task_data = load_task(task_file)
              tasks << task_data if task_data
            end
          end

          tasks
        end

        # Load all tasks across all contexts
        # @return [Array<Hash>] Array of all tasks
        def load_all_tasks
          tasks = []

          # Load from active releases
          Dir.glob(File.join(root_path, "v.*")).each do |release_path|
            next unless File.directory?(release_path)
            tasks.concat(load_tasks_from_context(release_path))
          end

          # Load from backlog
          backlog_path = File.join(root_path, "backlog")
          if File.directory?(backlog_path)
            # Direct backlog tasks
            tasks.concat(load_tasks_from_context(backlog_path))

            # Backlog releases
            Dir.glob(File.join(backlog_path, "v.*")).each do |release_path|
              next unless File.directory?(release_path)
              tasks.concat(load_tasks_from_context(release_path))
            end
          end

          # Load from done releases
          done_path = File.join(root_path, "done")
          if File.directory?(done_path)
            Dir.glob(File.join(done_path, "v.*")).each do |release_path|
              next unless File.directory?(release_path)
              tasks.concat(load_tasks_from_context(release_path))
            end
          end

          tasks
        end

        # Find task by qualified reference
        # @param reference [String] Qualified reference (e.g., v.0.9.0+018)
        # @return [Hash, nil] Task data or nil if not found
        def find_task_by_reference(reference)
          require_relative "../atoms/task_reference_parser"

          parsed = Atoms::TaskReferenceParser.parse(reference)
          return nil unless parsed

          context = parsed[:context]
          number = parsed[:number]

          # Resolve context to path
          context_path = if context == "current"
            # Find primary active release
            require_relative "release_resolver"
            resolver = ReleaseResolver.new(root_path)
            primary = resolver.find_primary_active
            primary ? primary[:path] : nil
          elsif context == "backlog"
            File.join(root_path, "backlog")
          else
            # Try to find as release
            require_relative "release_resolver"
            resolver = ReleaseResolver.new(root_path)
            release = resolver.find_release(context)
            release ? release[:path] : nil
          end

          return nil unless context_path

          # Try to find the task directory (supports both old and new formats)
          task_dir = find_task_directory(context_path, number)
          return nil unless task_dir && File.directory?(task_dir)

          md_files = Dir.glob(File.join(task_dir, "*.md"))
          return nil if md_files.empty?

          # Find the task file - the one with YAML frontmatter containing task metadata
          task_file = md_files.find do |file|
            has_task_frontmatter?(file)
          end

          # Load the task file if found
          load_task(task_file) if task_file
        end

        # Update task status
        # @param task_path [String] Path to the task file
        # @param new_status [String] New status value
        # @return [Boolean] True if successful
        def update_task_status(task_path, new_status)
          return false unless File.exist?(task_path)

          content = File.read(task_path)

          # Update status in frontmatter
          updated_content = content.sub(/^status:\s*.+$/m, "status: #{new_status}")

          File.write(task_path, updated_content)
          true
        rescue StandardError
          false
        end

        private

        def default_root_path
          File.join(Dir.pwd, ".ace-taskflow")
        end

        def has_task_frontmatter?(file_path)
          return false unless File.exist?(file_path)

          begin
            content = File.read(file_path, encoding: "utf-8")
            parsed = Atoms::YamlParser.parse(content)

            # Check if frontmatter exists and contains task metadata
            frontmatter = parsed[:frontmatter]
            return false unless frontmatter

            # A task file should have at least an id and status in frontmatter
            !!(frontmatter["id"] && frontmatter["status"])
          rescue StandardError
            false
          end
        end

        def extract_title(content)
          # Extract title from first heading or first line
          lines = content.to_s.split("\n")
          lines.each do |line|
            # Look for markdown heading
            if match = line.match(/^#\s+(.+)$/)
              return match[1].strip
            end
            # Return first non-empty line if no heading
            return line.strip unless line.strip.empty?
          end
          "Untitled Task"
        end

        # Find task directory, supporting both old and new formats
        # @param context_path [String] The context directory path
        # @param number [String] The task number
        # @return [String, nil] The task directory path or nil if not found
        def find_task_directory(context_path, number)
          task_base = File.join(context_path, "t")
          padded_number = number.to_s.rjust(3, '0')

          # First try old format (just the number)
          old_format_dir = File.join(task_base, padded_number)
          return old_format_dir if File.directory?(old_format_dir)

          # Then try new format (number with slug)
          # Look for directories starting with the padded number followed by a hyphen
          pattern = File.join(task_base, "#{padded_number}-*")
          matching_dirs = Dir.glob(pattern).select { |d| File.directory?(d) }
          return matching_dirs.first unless matching_dirs.empty?

          # Finally try unpadded number for compatibility
          unpadded_dir = File.join(task_base, number.to_s)
          return unpadded_dir if File.directory?(unpadded_dir)

          nil
        end
      end
    end
  end
end