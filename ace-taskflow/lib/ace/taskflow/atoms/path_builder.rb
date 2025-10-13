# frozen_string_literal: true

module Ace
  module Taskflow
    module Atoms
      # Pure function to build paths for the new structure (.ace-taskflow/v.X.Y.Z/tasks/NNN/)
      class PathBuilder
        # Build task path for new directory structure
        # @param root [String] The root directory (e.g., .ace-taskflow)
        # @param context [String] The context (backlog, v.X.Y.Z, done/v.X.Y.Z)
        # @param task_number [String, Integer] The task number
        # @param slug_part [String] Optional descriptive slug part (e.g., "feat-taskflow-idea")
        # @param config [Configuration] Optional configuration object
        # @return [String] The complete path to the task directory
        def self.build_task_path(root, context, task_number, slug_part = nil, config = nil)
          config ||= Ace::Taskflow.configuration
          task_dir = config.task_dir

          task_dir_name = if slug_part
            "#{task_number.to_s.rjust(3, '0')}-#{slug_part}"
          else
            task_number.to_s
          end
          File.join(root, context, task_dir, task_dir_name)
        end

        # Build task file path (with optional filename)
        # @param root [String] The root directory
        # @param context [String] The context
        # @param task_number [String, Integer] The task number
        # @param filename [String] Optional filename (defaults to "task.NNN.md" for new format)
        # @param slug_part [String] Optional descriptive slug part
        # @param config [Configuration] Optional configuration object
        # @return [String] The complete path to the task file
        def self.build_task_file_path(root, context, task_number, filename = nil, slug_part = nil, config = nil)
          # Use new naming convention: task.NNN.md when slug is present
          actual_filename = filename || (slug_part ? "task.#{task_number.to_s.rjust(3, '0')}.md" : "task.md")
          File.join(build_task_path(root, context, task_number, slug_part, config), actual_filename)
        end

        # Build release path
        # @param root [String] The root directory
        # @param release_name [String] The release name (e.g., v.0.9.0)
        # @param status [String] The release status (backlog, active, done)
        # @return [String] The complete path to the release directory
        def self.build_release_path(root, release_name, status = "active")
          case status
          when "backlog"
            File.join(root, "backlog", release_name)
          when "done"
            File.join(root, "done", release_name)
          when "active"
            File.join(root, release_name)
          else
            File.join(root, release_name)
          end
        end

        # Build ideas directory path
        # @param root [String] The root directory
        # @param context [String] The context (backlog, v.X.Y.Z, current)
        # @return [String] The path to the ideas directory
        def self.build_ideas_path(root, context)
          if context == "backlog"
            File.join(root, "backlog", "ideas")
          else
            File.join(root, context, "ideas")
          end
        end

        # Extract task number from path
        # @param path [String] The file or directory path
        # @param config [Configuration] Optional configuration object
        # @return [String, nil] The task number or nil if not found
        def self.extract_task_number(path, config = nil)
          config ||= Ace::Taskflow.configuration
          task_dir = config.task_dir

          # Match patterns like:
          # - /tasks/019/ (new format)
          # - /tasks/019/task.md (new format)
          # - /tasks/019-feat-taskflow/ (new format with slug)
          # - /tasks/019-feat-taskflow/task.019.md (new format with slug and numbered filename)
          # Also support legacy /t/ paths
          pattern = %r{/(?:#{Regexp.escape(task_dir)}|t)/(\d+)(?:-[^/]+)?(?:/|$)}
          match = path.match(pattern)
          match ? match[1] : nil
        end

        # Extract release version from path
        # @param path [String] The file or directory path
        # @return [String, nil] The release version or nil if not found
        def self.extract_release(path)
          # Match v.X.Y.Z patterns
          match = path.match(%r{/(v\.\d+\.\d+\.\d+[^/]*)(?:/|$)})
          match ? match[1] : nil
        end

        # Determine context from path
        # @param path [String] The file or directory path
        # @return [String] The context (backlog, active release, or done)
        def self.extract_context(path)
          if path.include?("/backlog/")
            "backlog"
          elsif path.include?("/done/")
            "done"
          else
            extract_release(path) || "unknown"
          end
        end

        # Build qualified task reference
        # @param context [String] The context (v.0.9.0, backlog, current)
        # @param task_number [String, Integer] The task number
        # @return [String] The qualified reference (e.g., v.0.9.0+018)
        def self.build_qualified_reference(context, task_number)
          "#{context}+#{task_number.to_s.rjust(3, '0')}"
        end

        # Generate descriptive filename from title
        # @param title [String] The task title
        # @param max_length [Integer] Maximum filename length (default: 50)
        # @return [String] The sanitized filename with .md extension
        # @deprecated Use task.NNN.md naming convention with descriptive directory names instead
        def self.generate_task_filename(title, max_length = 50)
          # Remove special characters and convert to lowercase with hyphens
          filename = title.downcase
                          .gsub(/[^a-z0-9\s-]/, "") # Remove special chars
                          .gsub(/\s+/, "-")          # Replace spaces with hyphens
                          .gsub(/-+/, "-")           # Collapse multiple hyphens
                          .gsub(/^-|-$/, "")         # Remove leading/trailing hyphens

          # Truncate if needed
          filename = filename[0, max_length] if filename.length > max_length

          # Ensure it doesn't end with a hyphen after truncation
          filename = filename.gsub(/-$/, "")

          # Add .md extension
          "#{filename}.md"
        end

        # Extract slug part from a task directory name
        # @param dir_name [String] Directory name (e.g., "025-feat-taskflow-idea")
        # @return [String, nil] The slug part without number, or nil for old format
        def self.extract_slug_from_dir(dir_name)
          # Match pattern like 025-feat-taskflow-idea
          if dir_name =~ /^\d{3}-(.+)$/
            $1
          else
            nil
          end
        end
      end
    end
  end
end