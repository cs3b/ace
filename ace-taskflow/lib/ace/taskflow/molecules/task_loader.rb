# frozen_string_literal: true

require "set"
require "ace/support/markdown"
require_relative "../atoms/yaml_parser"
require_relative "../atoms/path_builder"
require_relative "../configuration"

module Ace
  module Taskflow
    module Molecules
      # Load and parse task files
      class TaskLoader
        attr_reader :root_path

        def initialize(root_path = nil)
          @root_path = root_path || default_root_path
          @config = Configuration.new
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

          # Extract task number and release from path
          task_number = Atoms::PathBuilder.extract_task_number(path)
          release = Atoms::PathBuilder.extract_release(path)

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
            release: release,
            metadata: frontmatter
          }
        rescue StandardError => e
          nil
        end

        # Load all tasks from a release
        # @param release_path [String] Path to the release
        # @return [Array<Hash>] Array of task data
        def load_tasks_from_release(release_path)
          tasks = []
          task_dir = File.join(release_path, @config.task_dir)

          return tasks unless File.directory?(task_dir)

          # Iterate through task directories in main t/ directory
          # Supports both old format (t/001/) and new format (t/001-feat-taskflow/)
          Dir.glob(File.join(task_dir, "*")).select { |d| File.directory?(d) && File.basename(d) != "done" }.each do |task_folder|
            # Find .s.md files in the task folder (not in subfolders)
            md_files = Dir.glob(File.join(task_folder, "*.s.md"))

            # Find the task file - supports both formats:
            # - Old format: task.NNN.s.md (where NNN is task number)
            # - New format: NNN-{description}.s.md (where NNN is task number)
            task_file = md_files.find do |file|
              has_task_frontmatter?(file)
            end

            if task_file
              task_data = load_task(task_file)
              tasks << task_data if task_data
            end
          end

          # Also load tasks from done/ subdirectory
          done_dir = File.join(task_dir, @config.done_dir)
          if File.directory?(done_dir)
            Dir.glob(File.join(done_dir, "*")).select { |d| File.directory?(d) }.each do |task_folder|
              # Find .s.md files in the task folder
              md_files = Dir.glob(File.join(task_folder, "*.s.md"))

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

        # Load all tasks across all releases
        # @return [Array<Hash>] Array of all tasks
        def load_all_tasks
          tasks = []

          # Load from active releases
          Dir.glob(File.join(root_path, "v.*")).each do |release_path|
            next unless File.directory?(release_path)
            tasks.concat(load_tasks_from_release(release_path))
          end

          # Load from backlog
          backlog_path = File.join(root_path, "backlog")
          if File.directory?(backlog_path)
            # Direct backlog tasks
            tasks.concat(load_tasks_from_release(backlog_path))

            # Backlog releases
            Dir.glob(File.join(backlog_path, "v.*")).each do |release_path|
              next unless File.directory?(release_path)
              tasks.concat(load_tasks_from_release(release_path))
            end
          end

          # Load from done releases
          done_path = File.join(root_path, "done")
          if File.directory?(done_path)
            Dir.glob(File.join(done_path, "v.*")).each do |release_path|
              next unless File.directory?(release_path)
              tasks.concat(load_tasks_from_release(release_path))
            end
          end

          tasks
        end

        # Load tasks using glob patterns
        # @param release_path [String] Base path for glob evaluation
        # @param glob_patterns [Array<String>] Glob patterns to match
        # @return [Array<Hash>] Array of matched tasks
        def load_tasks_with_glob(release_path, glob_patterns)
          tasks = []
          matched_paths = Set.new

          Array(glob_patterns).each do |pattern|
            Dir.glob(File.join(release_path, pattern)).each do |path|
              # Avoid duplicates
              next if matched_paths.include?(path)
              matched_paths.add(path)

              # Load task if it's a .s.md file
              if File.file?(path) && path.end_with?('.s.md')
                task = load_task(path)
                tasks << task if task
              end
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

          # Determine search scope
          if parsed[:qualified]
            # Qualified reference: search specific release only
            release_path = resolve_release_to_path(parsed[:release])
            return nil unless release_path
            tasks = load_tasks_from_release(release_path)
          else
            # Simple reference: search globally across all tasks
            tasks = load_all_tasks
          end

          # Create a simple release resolver for normalization
          resolver = ContextResolver.new(@root_path)
          canonical_id = Atoms::TaskReferenceParser.normalize_to_canonical_id(reference, resolver)

          # Search by ID field (primary) or by task_number (fallback for compatibility)
          tasks.find do |t|
            t[:id] == canonical_id ||
            (t[:task_number] == parsed[:number] && t[:id]&.include?(parsed[:release]))
          end
        end

        # Update task status
        # @param task_path [String] Path to the task file
        # @param new_status [String] New status value
        # @return [Boolean] True if successful
        def update_task_status(task_path, new_status)
          return false unless File.exist?(task_path)

          # Use DocumentEditor for safe frontmatter manipulation
          # This prevents frontmatter corruption that occurred with regex-based editing
          editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(task_path)
          editor.update_frontmatter("status" => new_status)

          # Save with backup and validation enabled
          result = editor.save!(backup: true, validate_before: true)
          result[:success]
        rescue StandardError => e
          # Enhanced error logging for better debugging
          warn "TaskLoader: Failed to update task status in #{task_path}: #{e.class} - #{e.message}"
          warn e.backtrace.join("\n") if $DEBUG
          false
        end

        # Update task dependencies
        # @param task_path [String] Path to the task file
        # @param new_dependencies [Array<String>] New dependency list
        # @return [Boolean] True if successful
        def update_task_dependencies(task_path, new_dependencies)
          return false unless File.exist?(task_path)

          # Use DocumentEditor for safe frontmatter manipulation
          editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(task_path)
          editor.update_frontmatter("dependencies" => new_dependencies || [])

          # Save with backup and validation enabled
          result = editor.save!(backup: true, validate_before: true)
          result[:success]
        rescue StandardError => e
          # Enhanced error logging for better debugging
          warn "TaskLoader: Failed to update task dependencies in #{task_path}: #{e.class} - #{e.message}"
          warn e.backtrace.join("\n") if $DEBUG
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
            title: extract_title(result[:content])
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

        # Resolve release string to a file system path
        # @param release_name [String] Release identifier (current, backlog, or release name)
        # @return [String, nil] Resolved path or nil if not found
        def resolve_release_to_path(release_name)
          if release_name == "current"
            # Find primary active release
            require_relative "release_resolver"
            resolver = ReleaseResolver.new(root_path)
            primary = resolver.find_primary_active
            primary ? primary[:path] : nil
          elsif release_name == "backlog"
            File.join(root_path, "backlog")
          else
            # Try to find as release
            require_relative "release_resolver"
            resolver = ReleaseResolver.new(root_path)
            release = resolver.find_release(release_name)
            release ? release[:path] : nil
          end
        end

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
        # @param release_path [String] The release directory path
        # @param number [String] The task number
        # @return [String, nil] The task directory path or nil if not found
        def find_task_directory(release_path, number)
          task_base = File.join(release_path, @config.task_dir)
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
          done_base = File.join(task_base, @config.done_dir)
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

      # Simple release resolver for normalizing task references
      class ContextResolver
        def initialize(root_path)
          @root_path = root_path
        end

        def resolve_release(release)
          case release
          when "current", "active"
            require_relative "release_resolver"
            resolver = ReleaseResolver.new(@root_path)
            primary = resolver.find_primary_active
            primary ? primary[:name] : release
          when "backlog"
            "backlog"
          else
            release
          end
        end
      end
    end
  end
end