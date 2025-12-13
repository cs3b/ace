# frozen_string_literal: true

require_relative "../configuration"

module Ace
  module Taskflow
    module Atoms
      # Pure function to build paths for the new structure (.ace-taskflow/v.X.Y.Z/tasks/NNN/)
      class PathBuilder
        # Build task path for new directory structure
        # @param root [String] The root directory (e.g., .ace-taskflow)
        # @param release [String] The release (backlog, v.X.Y.Z, done/v.X.Y.Z)
        # @param task_number [String, Integer] The task number
        # @param slug_part [String] Optional descriptive slug part (e.g., "feat-taskflow-idea")
        # @param config [Configuration] Optional configuration object
        # @return [String] The complete path to the task directory
        def self.build_task_path(root, release, task_number, slug_part = nil, config_param = nil)
          config_obj = (config_param || config)
          task_dir = config_obj.task_dir

          task_dir_name = if slug_part
            "#{task_number.to_s.rjust(3, '0')}-#{slug_part}"
          else
            task_number.to_s
          end

          # Map logical "backlog" to configured backlog directory
          actual_release = if release == "backlog"
            config_obj.backlog_dir
          else
            release
          end

          File.join(root, actual_release, task_dir, task_dir_name)
        end

        # Build task file path (with optional filename)
        # @param root [String] The root directory
        # @param release [String] The release
        # @param task_number [String, Integer] The task number
        # @param filename [String] Optional filename (defaults to "task.NNN.s.md" for new format)
        # @param slug_part [String] Optional descriptive slug part
        # @param config [Configuration] Optional configuration object
        # @return [String] The complete path to the task file
        def self.build_task_file_path(root, release, task_number, filename = nil, slug_part = nil, config_param = nil)
          # Use new naming convention: task.NNN.s.md when slug is present
          actual_filename = filename || (slug_part ? "task.#{task_number.to_s.rjust(3, '0')}.s.md" : "task.s.md")
          File.join(build_task_path(root, release, task_number, slug_part, config_param), actual_filename)
        end

        # Build release path
        # @param root [String] The root directory
        # @param release_name [String] The release name (e.g., v.0.9.0)
        # @param status [String] The release status (backlog, pending, active, done)
        # @return [String] The complete path to the release directory
        def self.build_release_path(root, release_name, status = "active")
          archive_dir = Ace::Taskflow.configuration.done_dir
          backlog_dir = Ace::Taskflow.configuration.backlog_dir
          case status
          when "backlog"
            File.join(root, backlog_dir, release_name)
          when "pending"
            File.join(root, "pending", release_name)
          when "done"
            File.join(root, archive_dir, release_name)
          when "active"
            File.join(root, release_name)
          else
            File.join(root, release_name)
          end
        end

        # Build ideas directory path
        # @param root [String] The root directory
        # @param release [String] The release (backlog, v.X.Y.Z, current)
        # @return [String] The path to the ideas directory
        def self.build_ideas_path(root, release)
          backlog_dir = Ace::Taskflow.configuration.backlog_dir
          if release == "backlog"
            File.join(root, backlog_dir, "ideas")
          else
            File.join(root, release, "ideas")
          end
        end

        # Extract task number from path
        # @param path [String] The file or directory path
        # @param config [Configuration] Optional configuration object
        # @return [String, nil] The task number or nil if not found
        def self.extract_task_number(path, config_param = nil)
          task_dir = (config_param || config).task_dir

          # Match patterns like:
          # - /tasks/019/ (old format)
          # - /tasks/019/task.019.s.md (old format with file)
          # - /tasks/019-feat-taskflow/ (new hierarchical format with slug)
          # - /tasks/019-feat-taskflow/019-specific-desc.s.md (new hierarchical format with file)
          # Also support legacy /t/ paths

          # First try to extract from folder name: /tasks/NNN-slug/ or /tasks/NNN/
          folder_pattern = %r{/(?:#{Regexp.escape(task_dir)}|t)/(\d+)(?:-[^/]+)?(?:/|$)}
          folder_match = path.match(folder_pattern)
          return folder_match[1] if folder_match

          # Also try to extract from filename: NNN-description.s.md
          file_pattern = %r{/(\d+)-[^/]+\.s\.md$}
          file_match = path.match(file_pattern)
          return file_match[1] if file_match

          nil
        end

        # Extract release version string from path
        # @param path [String] The file or directory path
        # @return [String, nil] The release version or nil if not found
        def self.extract_release_version(path)
          # Match v.X.Y.Z patterns
          match = path.match(%r{/(v\.\d+\.\d+\.\d+[^/]*)(?:/|$)})
          match ? match[1] : nil
        end

        # Determine release/location from path
        # @param path [String] The file or directory path
        # @return [String] The release (backlog, pending, active release version, or done)
        def self.extract_release(path)
          archive_dir = Ace::Taskflow.configuration.done_dir
          backlog_dir = Ace::Taskflow.configuration.backlog_dir
          if path.include?("/#{backlog_dir}/")
            "backlog"
          elsif path.include?("/pending/")
            "pending"
          elsif path.include?("/#{archive_dir}/")
            "done"
          else
            extract_release_version(path) || "unknown"
          end
        end

        # Build qualified task reference
        # @param release [String] The release (v.0.9.0, backlog, current)
        # @param task_number [String, Integer] The task number
        # @return [String] The qualified reference (e.g., v.0.9.0+task.018)
        def self.build_qualified_reference(release, task_number)
          "#{release}+task.#{task_number.to_s.rjust(3, '0')}"
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

        class << self
          protected

          # Get configuration - extracted for test stubbing
          def config
            Ace::Taskflow.configuration
          end
        end
      end
    end
  end
end