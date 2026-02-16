# frozen_string_literal: true

require "set"
require "ace/support/markdown"
require_relative "../atoms/yaml_parser"
require_relative "../atoms/path_builder"
require_relative "../atoms/task_reference_parser"
require_relative "../configuration"

module Ace
  module Taskflow
    module Molecules
      # Load and parse task files
      # Supports hierarchical task structures (orchestrators + subtasks)
      class TaskLoader
        attr_reader :root_path

        # File pattern recognition for hierarchical tasks
        # Orchestrator: 121.00-orchestrator.s.md
        ORCHESTRATOR_PATTERN = /^(\d+)\.00-.*\.s\.md$/
        # Subtask: 121.01-archive.s.md (NN > 00)
        SUBTASK_PATTERN = /^(\d+)\.(\d{2})-.*\.s\.md$/
        # Single task: 119-feature.s.md (no dot before hyphen)
        SINGLE_TASK_PATTERN = /^(\d+)-[^.][^\/]*\.s\.md$/

        # Class-level cache for per-command memoization
        # Cleared at CLI command start to ensure fresh data each invocation
        # Thread-safe via mutex for potential parallel operations
        @task_cache = {}
        @cache_mutex = Mutex.new

        class << self
          attr_accessor :task_cache, :cache_mutex

          # Clear all cached data (call at start of each CLI command)
          def clear_cache!
            cache_mutex.synchronize { @task_cache = {} }
          end

          # Invalidate cache entries containing the given path
          # Call this when a task file is modified to ensure fresh data
          # @param path [String] Path to the modified file or its parent directory
          def invalidate_cache_for_path(path)
            return unless path

            cache_mutex.synchronize do
              # Remove any cache entries that could contain this path
              # Cache keys are release paths, so find which release contains this file
              @task_cache.delete_if { |key, _| path.start_with?(key) || key.start_with?(File.dirname(path)) }
            end
          end
        end

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

          # Classify file type based on filename
          filename = File.basename(path)
          file_type = classify_task_file(filename)

          # Extract parent_id from frontmatter or derive from filename for subtasks
          parent_id = frontmatter["parent"]

          # Build task data with hierarchical fields
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
            metadata: frontmatter,
            # Hierarchical fields
            parent_id: parent_id,
            subtask_ids: frontmatter["subtasks"] || [],
            is_orchestrator: file_type == :orchestrator || (frontmatter["subtasks"] && !frontmatter["subtasks"].empty?),
            file_type: file_type
          }
        rescue StandardError => e
          nil
        end

        # Load all tasks from a release
        # Uses class-level cache to avoid re-reading files within same command
        # @param release_path [String] Path to the release
        # @return [Array<Hash>] Array of task data
        def load_tasks_from_release(release_path)
          cache_key = release_path

          # Check cache first (thread-safe)
          self.class.cache_mutex.synchronize do
            return self.class.task_cache[cache_key].dup if self.class.task_cache.key?(cache_key)
          end

          # Load from filesystem
          tasks = load_tasks_from_release_uncached(release_path)

          # Store in cache (thread-safe)
          self.class.cache_mutex.synchronize do
            self.class.task_cache[cache_key] = tasks
          end

          tasks.dup
        end

        private

        # Actual implementation without caching
        # Optimized: single file read per task (removed has_task_frontmatter? + load_task double-read)
        def load_tasks_from_release_uncached(release_path)
          tasks = []
          task_dir = File.join(release_path, @config.task_dir)

          return tasks unless File.directory?(task_dir)

          # Iterate through task directories in main t/ directory
          # Supports both old format (t/001/) and new format (t/001-feat-taskflow/)
          archive_dir = @config.done_dir
          Dir.glob(File.join(task_dir, "*")).select { |d| File.directory?(d) && File.basename(d) != archive_dir }.each do |task_folder|
            # Find ALL .s.md files in the task folder (not in subfolders)
            # This includes orchestrators (121.00-*.s.md) and subtasks (121.01-*.s.md)
            md_files = Dir.glob(File.join(task_folder, "*.s.md"))

            # Load task files - single read per file (load_task returns nil on parse errors)
            # Check for required frontmatter fields (id, status) to filter non-task files
            md_files.each do |file|
              task_data = load_task(file)
              tasks << task_data if task_data && task_data[:id] && task_data[:status]
            end
          end

          # Also load tasks from done/ subdirectory
          done_dir = File.join(task_dir, @config.done_dir)
          if File.directory?(done_dir)
            Dir.glob(File.join(done_dir, "*")).select { |d| File.directory?(d) }.each do |task_folder|
              # Find ALL .s.md files in the task folder
              md_files = Dir.glob(File.join(task_folder, "*.s.md"))

              # Load task files - single read per file
              md_files.each do |file|
                task_data = load_task(file)
                tasks << task_data if task_data && task_data[:id] && task_data[:status]
              end
            end
          end

          # Build parent-child relationships after loading all tasks
          build_task_relationships(tasks)

          tasks
        end

        public

        # Build parent-child relationships between orchestrators and subtasks
        # @param tasks [Array<Hash>] Array of tasks to process (modified in place)
        # @return [void]
        def build_task_relationships(tasks)
          # Group tasks by their parent number (from filename or frontmatter)
          # Orchestrators and subtasks share the same parent number
          orchestrators = {}  # parent_number -> orchestrator task
          subtasks_by_parent = {}  # parent_number -> [subtask tasks]

          tasks.each do |task|
            filename = File.basename(task[:path] || "")
            parent_num = extract_parent_number(filename)

            case task[:file_type]
            when :orchestrator
              orchestrators[parent_num] = task if parent_num
            when :subtask
              if parent_num
                subtasks_by_parent[parent_num] ||= []
                subtasks_by_parent[parent_num] << task
              end
            end
          end

          # Link subtasks to their orchestrators
          subtasks_by_parent.each do |parent_num, subtasks|
            orchestrator = orchestrators[parent_num]

            subtasks.each do |subtask|
              # Set parent_id from frontmatter or derive from orchestrator
              if subtask[:parent_id].nil? && orchestrator
                subtask[:parent_id] = orchestrator[:id]
              elsif subtask[:parent_id].nil?
                # Virtual parent - no orchestrator file exists
                # Derive parent_id from filename pattern
                # e.g., for subtask 121.01, parent would be v.0.9.0+task.121
                subtask[:parent_id] = derive_parent_id(subtask, parent_num)
              end
            end

            # Populate orchestrator's subtask_ids
            # Merge frontmatter subtasks with discovered ones, actual files are authoritative
            if orchestrator
              frontmatter_ids = orchestrator[:subtask_ids] || []
              discovered_ids = subtasks.map { |s| s[:id] }.compact.sort
              # Normalize short IDs (e.g., "243.02") to canonical form (e.g., "v.0.9.0+task.243.02")
              # so .uniq deduplicates correctly when frontmatter mixes short and full IDs
              resolver = ContextResolver.new(@root_path)
              normalized_frontmatter_ids = frontmatter_ids.map do |id|
                Atoms::TaskReferenceParser.normalize_to_canonical_id(id, resolver) || id
              end
              orchestrator[:subtask_ids] = (normalized_frontmatter_ids + discovered_ids).uniq
              orchestrator[:is_orchestrator] = true
            end
          end

          # Also mark orchestrators without subtasks
          orchestrators.each do |parent_num, orchestrator|
            orchestrator[:is_orchestrator] = true unless orchestrator[:is_orchestrator]
          end
        end

        # Derive a parent_id for a subtask when no orchestrator file exists
        # @param subtask [Hash] The subtask data
        # @param parent_num [String] The parent task number
        # @return [String] The derived parent_id
        def derive_parent_id(subtask, parent_num)
          # Extract release from subtask's canonical ID to stay stable across folder moves
          # e.g., "v.0.9.0+task.121.01" -> "v.0.9.0"
          # This is needed because subtask[:release] comes from PathBuilder which returns
          # "done" for archived tasks, but the canonical ID in frontmatter is always correct
          release = if subtask[:id]
            parsed = Atoms::TaskReferenceParser.parse(subtask[:id])
            parsed ? parsed[:release] : (subtask[:release] || "current")
          else
            subtask[:release] || "current"
          end

          padded = parent_num.to_s.rjust(3, '0')
          "#{release}+task.#{padded}"
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
          backlog_path = File.join(root_path, @config.backlog_dir)
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
          done_path = File.join(root_path, @config.done_dir)
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

        # Find task by qualified reference with hierarchical lookup support
        #
        # Lookup Strategy:
        # - Qualified references (v.0.9.0+task.121): Direct canonical ID match within specified release
        # - Simple references (121): Multi-step precedence lookup with orchestrator priority
        #
        # Simple Reference Precedence:
        # 1. Exact canonical ID match (highest precedence)
        # 2. Orchestrator task with this number (user likely wants the parent task)
        # 3. Any task with matching task_number (fallback for single tasks)
        #
        # Why orchestrators get priority: When users reference "121", they typically want
        # the orchestrator task rather than a specific subtask, as orchestrators represent
        # the primary work item. Subtasks should be referenced explicitly (121.01, etc.).
        #
        # Supports hierarchical references: 121, 121.00, 121.01, v.0.9.0+task.121.01
        # @param reference [String] Qualified reference (e.g., v.0.9.0+018, 121.01)
        # @param tasks [Array<Hash>, nil] Optional pre-loaded tasks for testing
        # @return [Hash, nil] Task data or nil if not found
        def find_task_by_reference(reference, tasks: nil)
          parsed = Atoms::TaskReferenceParser.parse(reference)
          return nil unless parsed

          # Use provided tasks or load based on reference type
          tasks ||= if parsed[:qualified]
            # Qualified reference: search specific release only
            release_path = resolve_release_to_path(parsed[:release])
            return nil unless release_path
            load_tasks_from_release(release_path)
          else
            # Simple reference: search globally across all tasks
            load_all_tasks
          end

          # Create a simple release resolver for normalization
          resolver = ContextResolver.new(@root_path)
          canonical_id = Atoms::TaskReferenceParser.normalize_to_canonical_id(reference, resolver)

          # Handle hierarchical references
          if parsed[:subtask]
            # Looking for specific subtask (121.01) or orchestrator (121.00)
            # Match by canonical ID
            tasks.find { |t| t[:id] == canonical_id }
          else
            # Simple reference (e.g., "121") lookup precedence:
            # 1. Exact match by canonical ID (highest precedence)
            # 2. Orchestrator task with this number (user likely wants parent)
            # 3. Any task with matching task_number (fallback for single tasks)
            #
            # Step 1: First try exact match by canonical ID
            exact_match = tasks.find { |t| t[:id] == canonical_id }
            return exact_match if exact_match

            # Step 2: Look for orchestrator with this task number
            orchestrator = tasks.find do |t|
              t[:is_orchestrator] &&
              t[:task_number] == parsed[:number] &&
              (parsed[:release] == "current" || t[:id]&.include?(parsed[:release]))
            end
            return orchestrator if orchestrator

            # Step 3: Fallback to any task with matching task_number (single tasks)
            tasks.find do |t|
              t[:task_number] == parsed[:number] &&
              (parsed[:release] == "current" || t[:id]&.include?(parsed[:release]))
            end
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

          # Invalidate cache since file was modified
          self.class.invalidate_cache_for_path(task_path) if result[:success]

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

          # Invalidate cache since file was modified
          self.class.invalidate_cache_for_path(task_path) if result[:success]

          result[:success]
        rescue StandardError => e
          # Enhanced error logging for better debugging
          warn "TaskLoader: Failed to update task dependencies in #{task_path}: #{e.class} - #{e.message}"
          warn e.backtrace.join("\n") if $DEBUG
          false
        end

        # Update arbitrary task fields
        # @param task_path [String] Path to task file
        # @param field_updates [Hash] Hash of field paths to values
        # @return [Hash] Result with :success, :message, :updated_fields, :path
        def update_task_field(task_path, field_updates)
          return { success: false, message: "Task file not found: #{task_path}" } unless File.exist?(task_path)

          # Read current content
          content = File.read(task_path)

          # Parse document using ace-support-markdown
          document = Ace::Support::Markdown::Models::MarkdownDocument.parse(content, file_path: task_path)

          # Apply field updates using FrontmatterEditor
          updated_doc = Ace::Support::Markdown::Molecules::FrontmatterEditor.update(document, field_updates)

          # Get updated content
          updated_content = updated_doc.to_markdown

          # Use SafeFileWriter for atomic write with backup
          result = Ace::Support::Markdown::Organisms::SafeFileWriter.write(
            task_path,
            updated_content,
            backup: true,
            validate: false
          )

          if result[:success]
            # Invalidate cache since file was modified
            self.class.invalidate_cache_for_path(task_path)
            {
              success: true,
              message: "Task updated successfully",
              updated_fields: field_updates.keys,
              path: task_path
            }
          else
            {
              success: false,
              message: "Failed to write task file: #{result[:error] || 'Unknown error'}",
              path: task_path
            }
          end
        rescue Ace::Support::Markdown::Models::MarkdownDocument::ValidationError => e
          {
            success: false,
            message: "Invalid document format: #{e.message}",
            path: task_path
          }
        rescue StandardError => e
          {
            success: false,
            message: "Unexpected error: #{e.message}",
            path: task_path
          }
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
            File.join(root_path, @config.backlog_dir)
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

        # Classify a task file based on filename pattern
        # @param filename [String] The filename (basename) to classify
        # @return [Symbol] :orchestrator, :subtask, :single, or :unknown
        def classify_task_file(filename)
          case filename
          when ORCHESTRATOR_PATTERN
            :orchestrator
          when SUBTASK_PATTERN
            # Subtask pattern matches both orchestrators and subtasks
            # Check if it's actually .00 (orchestrator) or .01-.99 (subtask)
            if filename.match(/^(\d+)\.00-/)
              :orchestrator
            else
              :subtask
            end
          when SINGLE_TASK_PATTERN
            :single
          else
            :unknown
          end
        end

        # Extract subtask number from filename (e.g., "121.01-foo.s.md" -> "01")
        # @param filename [String] The filename
        # @return [String, nil] The subtask number or nil
        def extract_subtask_number(filename)
          if match = filename.match(SUBTASK_PATTERN)
            match[2]
          end
        end

        # Extract parent task number from filename (e.g., "121.01-foo.s.md" -> "121")
        # @param filename [String] The filename
        # @return [String, nil] The parent task number or nil
        def extract_parent_number(filename)
          if match = filename.match(SUBTASK_PATTERN)
            match[1]
          elsif match = filename.match(ORCHESTRATOR_PATTERN)
            match[1]
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