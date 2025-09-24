# frozen_string_literal: true

module Ace
  module Taskflow
    module Atoms
      # Pure function to build paths for the new structure (.ace-taskflow/v.X.Y.Z/t/NNN/)
      class PathBuilder
        # Build task path for new directory structure
        # @param root [String] The root directory (e.g., .ace-taskflow)
        # @param context [String] The context (backlog, v.X.Y.Z, done/v.X.Y.Z)
        # @param task_number [String, Integer] The task number
        # @return [String] The complete path to the task directory
        def self.build_task_path(root, context, task_number)
          File.join(root, context, "t", task_number.to_s)
        end

        # Build task file path
        # @param root [String] The root directory
        # @param context [String] The context
        # @param task_number [String, Integer] The task number
        # @return [String] The complete path to the task.md file
        def self.build_task_file_path(root, context, task_number)
          File.join(build_task_path(root, context, task_number), "task.md")
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
        # @return [String, nil] The task number or nil if not found
        def self.extract_task_number(path)
          # Match patterns like /t/019/ or /t/019/task.md
          match = path.match(%r{/t/(\d+)(?:/|$)})
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
      end
    end
  end
end