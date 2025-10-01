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

          # Iterate through task directories in main t/ directory
          # Supports both old format (t/001/) and new format (t/001-feat-taskflow/)
          Dir.glob(File.join(task_dir, "*")).select { |d| File.directory?(d) && File.basename(d) != "done" }.each do |task_folder|
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

          # Also load tasks from done/ subdirectory
          done_dir = File.join(task_dir, "done")
          if File.directory?(done_dir)
            Dir.glob(File.join(done_dir, "*")).select { |d| File.directory?(d) }.each do |task_folder|
              # Find .md files in the task folder
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

        # Update task dependencies
        # @param task_path [String] Path to the task file
        # @param new_dependencies [Array<String>] New dependency list
        # @return [Boolean] True if successful
        def update_task_dependencies(task_path, new_dependencies)
          return false unless File.exist?(task_path)

          content = File.read(task_path)

          # Format dependencies for YAML
          deps_yaml = if new_dependencies.nil? || new_dependencies.empty?
            "dependencies: []"
          else
            formatted_deps = new_dependencies.map { |d| d.to_s }
            "dependencies: [#{formatted_deps.join(', ')}]"
          end

          # Check if dependencies field exists
          if content =~ /^dependencies:/m
            # Update existing dependencies field
            updated_content = content.sub(/^dependencies:.*$/m, deps_yaml)
          else
            # Add dependencies field after status or priority
            if content =~ /^(status:.*?)$/m
              updated_content = content.sub(/^(status:.*?)$/m, "\\1\n#{deps_yaml}")
            elsif content =~ /^(priority:.*?)$/m
              updated_content = content.sub(/^(priority:.*?)$/m, "\\1\n#{deps_yaml}")
            else
              # Add after id field
              updated_content = content.sub(/^(id:.*?)$/m, "\\1\n#{deps_yaml}")
            end
          end

          File.write(task_path, updated_content)
          true
        rescue StandardError
          false
        end

        # Parse task metadata from content string (unit testable)
        # @param content [String] Task file content
        # @return [Hash] Parsed metadata
        def parse_metadata(content)
          parsed = Atoms::YamlParser.parse(content)
          frontmatter = parsed[:frontmatter]

          return nil unless frontmatter

          {
            id: frontmatter["id"],
            status: frontmatter["status"] || "pending",
            priority: frontmatter["priority"] || "medium",
            estimate: frontmatter["estimate"],
            dependencies: frontmatter["dependencies"] || [],
            sort: frontmatter["sort"],
            title: extract_title(parsed[:content])
          }
        rescue StandardError
          nil
        end

        # Extract title from content (unit testable)
        # @param content [String] Task body content
        # @return [String] Extracted title
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

        # Validate task structure (unit testable)
        # @param task [Hash] Task hash to validate
        # @return [Boolean] True if valid
        def valid_task?(task)
          return false unless task.is_a?(Hash)
          return false unless task[:id] || task["id"]

          true
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

        # Find task directory, supporting both old and new formats
        # @param context_path [String] The context directory path
        # @param number [String] The task number
        # @return [String, nil] The task directory path or nil if not found
        def find_task_directory(context_path, number)
          task_base = File.join(context_path, "t")
          padded_number = number.to_s.rjust(3, '0')

          # First try in main t/ directory
          # Try old format (just the number)
          old_format_dir = File.join(task_base, padded_number)
          return old_format_dir if File.directory?(old_format_dir)

          # Then try new format (number with slug)
          # Look for directories starting with the padded number followed by a hyphen
          pattern = File.join(task_base, "#{padded_number}-*")
          matching_dirs = Dir.glob(pattern).select { |d| File.directory?(d) }
          return matching_dirs.first unless matching_dirs.empty?

          # Try unpadded number for compatibility
          unpadded_dir = File.join(task_base, number.to_s)
          return unpadded_dir if File.directory?(unpadded_dir)

          # Now try in done/ subdirectory
          done_base = File.join(task_base, "done")
          if File.directory?(done_base)
            # Try old format in done/
            old_format_done_dir = File.join(done_base, padded_number)
            return old_format_done_dir if File.directory?(old_format_done_dir)

            # Try new format in done/
            done_pattern = File.join(done_base, "#{padded_number}-*")
            done_matching_dirs = Dir.glob(done_pattern).select { |d| File.directory?(d) }
            return done_matching_dirs.first unless done_matching_dirs.empty?

            # Try unpadded in done/
            unpadded_done_dir = File.join(done_base, number.to_s)
            return unpadded_done_dir if File.directory?(unpadded_done_dir)
          end

          nil
        end
      end
    end
  end
end