# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Models
        # Model representing task metadata from ace-taskflow
        class TaskMetadata
          attr_reader :id, :full_id, :release, :number, :title, :status,
                      :priority, :estimate, :dependencies, :path

          def initialize(id:, title:, status: "pending", full_id: nil, release: nil,
                        number: nil, priority: nil, estimate: nil, dependencies: nil, path: nil)
            @id = id
            @full_id = full_id || id
            @release = release
            @number = number || extract_number(id)
            @title = title
            @status = status
            @priority = priority
            @estimate = estimate
            @dependencies = dependencies || []
            @path = path
          end

          # Generate slug from title
          def slug(max_length: 50, separator: "-")
            return "" if title.nil? || title.empty?

            Atoms::SlugGenerator.generate(title, max_length: max_length, separator: separator)
          end

          # Check if task is in progress
          def in_progress?
            status == "in-progress"
          end

          # Check if task is pending
          def pending?
            status == "pending"
          end

          # Check if task is done
          def done?
            status == "done"
          end

          # Check if task is blocked
          def blocked?
            status == "blocked"
          end

          # Format template variables for naming
          def template_variables
            {
              id: number,
              task_id: full_id,
              release: release || "unknown",
              slug: slug
            }
          end

          # Convert to hash representation
          def to_h
            {
              id: id,
              full_id: full_id,
              release: release,
              number: number,
              title: title,
              status: status,
              priority: priority,
              estimate: estimate,
              dependencies: dependencies,
              path: path
            }.compact
          end

          # Parse from ace-taskflow output
          def self.from_taskflow_output(output)
            # Expected format from ace-taskflow task show --content:
            # ---
            # id: v.0.9.0+task.081
            # status: pending
            # priority: high
            # estimate: 2h
            # dependencies: []
            # ---
            # # Task Title Here
            # ...

            require 'yaml'

            # Split frontmatter from content
            if output =~ /\A---\s*\n(.*?)\n---\s*\n(.*)/m
              frontmatter = $1
              content = $2

              metadata = YAML.safe_load(frontmatter, permitted_classes: [Symbol])

              # Extract title from content (first heading)
              title = content[/^#\s+(.+)$/, 1]&.strip

              # Parse task ID components
              if metadata["id"] =~ /^(v\.[^+]+)\+task\.(\d+)$/
                release = $1
                number = $2
              end

              new(
                id: metadata["id"],
                full_id: metadata["id"],
                release: release,
                number: number,
                title: title || "Untitled Task",
                status: metadata["status"] || "pending",
                priority: metadata["priority"],
                estimate: metadata["estimate"],
                dependencies: metadata["dependencies"] || []
              )
            else
              nil
            end
          end

          # Parse from simple ace-taskflow list output
          def self.from_list_output(line)
            # Expected format:
            # v.0.9.0+task.081 🟡 Fix authentication bug
            # Path: .ace-taskflow/v.0.9.0/tasks/081-fix-authentication-bug/task.081.md

            if line =~ /^(v\.[^+]+\+task\.\d+)\s+[⚫⚪🟡🟢🔴]\s+(.+)$/
              id = $1
              title = $2

              # Parse ID components
              if id =~ /^(v\.[^+]+)\+task\.(\d+)$/
                release = $1
                number = $2
              end

              new(
                id: id,
                full_id: id,
                release: release,
                number: number,
                title: title
              )
            else
              nil
            end
          end

          private

          def extract_number(id)
            # Extract number from various ID formats:
            # "081" -> "081"
            # "task.081" -> "081"
            # "v.0.9.0+task.081" -> "081"
            case id
            when /^(\d+)$/
              $1
            when /^task\.(\d+)$/
              $1
            when /\+task\.(\d+)$/
              $1
            else
              id
            end
          end
        end
      end
    end
  end
end