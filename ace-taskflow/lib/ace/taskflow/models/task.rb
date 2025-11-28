# frozen_string_literal: true

module Ace
  module Taskflow
    module Models
      # Task data structure
      class Task
        attr_reader :id, :status, :priority, :estimate, :dependencies,
                    :title, :content, :path, :task_number, :release, :metadata,
                    :sort

        def initialize(attributes = {})
          @id = attributes[:id]
          @status = attributes[:status] || "pending"
          @priority = attributes[:priority] || "medium"
          @estimate = attributes[:estimate]
          @dependencies = attributes[:dependencies] || []
          @title = attributes[:title]
          @content = attributes[:content]
          @path = attributes[:path]
          @task_number = attributes[:task_number]
          @release = attributes[:release]
          @metadata = attributes[:metadata] || {}
          @sort = attributes[:sort]
        end

        # Convert to hash
        def to_h
          {
            id: id,
            status: status,
            priority: priority,
            estimate: estimate,
            dependencies: dependencies,
            title: title,
            content: content,
            path: path,
            task_number: task_number,
            release: release,
            metadata: metadata,
            sort: sort
          }
        end

        # Check if task is actionable
        def actionable?
          status == "pending" && dependencies.empty?
        end

        # Check if task is complete
        def done?
          status == "done"
        end

        # Check if task is in progress
        def in_progress?
          status == "in-progress"
        end

        # Check if task is blocked
        def blocked?
          status == "blocked"
        end

        # Get qualified reference
        # For subtasks (which have a full ID like v.0.9.0+task.122.04), return the ID directly
        # For regular tasks, construct the qualified reference from release + task_number
        def qualified_reference
          # If we have a full ID from frontmatter, use it (handles subtasks correctly)
          return id if id && id.include?("+task.")

          return nil unless release && task_number

          if release == "current"
            task_number
          else
            "#{release}+task.#{task_number}"
          end
        end

        # Compare tasks for sorting
        def <=>(other)
          return 0 unless other.is_a?(Task)

          # First by sort value if both have it
          if sort && other.sort
            sort_order = sort <=> other.sort
            return sort_order unless sort_order == 0
          elsif sort || other.sort
            # One has sort value, it comes first
            return sort ? -1 : 1
          end

          # Then by priority
          priority_order = priority_value <=> other.priority_value
          return priority_order unless priority_order == 0

          # Then by status
          status_order = status_value <=> other.status_value
          return status_order unless status_order == 0

          # Finally by ID
          id.to_s <=> other.id.to_s
        end

        protected

        def priority_value
          case priority.to_s.downcase
          when "critical" then 0
          when "high" then 1
          when "medium" then 2
          when "low" then 3
          else 4
          end
        end

        def status_value
          case status.to_s.downcase
          when "in-progress" then 0
          when "pending" then 1
          when "blocked" then 2
          when "done" then 3
          else 4
          end
        end
      end
    end
  end
end