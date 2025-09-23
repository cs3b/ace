# frozen_string_literal: true

require "pathname"

module Ace
  module Nav
    module Molecules
      # Resolves task:// URIs to task files
      class TaskResolver
        def initialize
          @base_path = find_project_root
        end

        def resolve(task_identifier)
          # Normalize task identifier (018 or v.0.9.0+task.018)
          task_number = extract_task_number(task_identifier)
          return nil unless task_number

          # Search for task files
          patterns = [
            "dev-taskflow/current/*/tasks/*task.#{task_number}*.md",
            "dev-taskflow/current/*/tasks/task.#{task_number}/*.md",
            "dev-taskflow/backlog/*task.#{task_number}*.md"
          ]

          patterns.each do |pattern|
            files = Dir.glob(File.join(@base_path, pattern))
            return files.first unless files.empty?
          end

          nil
        end

        def list_tasks(pattern = "*")
          task_pattern = pattern == "*" ? "*" : "*#{pattern}*"

          patterns = [
            "dev-taskflow/current/*/tasks/#{task_pattern}.md",
            "dev-taskflow/current/*/tasks/task.*/#{task_pattern}.md",
            "dev-taskflow/backlog/#{task_pattern}.md"
          ]

          tasks = []
          patterns.each do |pat|
            files = Dir.glob(File.join(@base_path, pat))
            tasks.concat(files)
          end

          tasks.uniq.sort
        end

        private

        def find_project_root
          # Start from current directory and search upward
          current = Pathname.pwd

          while current.parent != current
            # Check for indicators of project root
            if File.exist?(File.join(current, "dev-taskflow")) ||
               File.exist?(File.join(current, ".ace")) ||
               File.exist?(File.join(current, ".git"))
              return current.to_s
            end
            current = current.parent
          end

          # Default to current directory
          Dir.pwd
        end

        def extract_task_number(identifier)
          return nil if identifier.nil?

          # Handle different formats:
          # - "018", "18" -> "018"
          # - "v.0.9.0+task.018" -> "018"
          # - "task.018" -> "018"

          if identifier =~ /task\.(\d+)/
            $1.rjust(3, "0") # Pad with zeros
          elsif identifier =~ /^(\d+)$/
            $1.rjust(3, "0") # Pad with zeros
          else
            identifier # Return as-is and let the search handle it
          end
        end
      end
    end
  end
end