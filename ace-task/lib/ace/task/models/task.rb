# frozen_string_literal: true

module Ace
  module Task
    module Models
      # Value object representing a task.
      Task = Struct.new(
        :id,             # Formatted task ID (e.g., "8pp.t.q7w")
        :status,         # Task status (e.g., "pending", "in-progress", "done")
        :title,          # Human-readable title
        :priority,       # Priority level (e.g., "critical", "high", "medium", "low")
        :estimate,       # Effort estimate
        :dependencies,   # Array of task IDs this task depends on
        :tags,           # Array of tag strings
        :content,        # Body markdown content
        :path,           # Directory path
        :file_path,      # Full path to spec file
        :special_folder, # Special folder name (e.g., "_maybe", nil if none)
        :created_at,     # Time decoded from ID
        :subtasks,       # Array of subtask Task objects (loaded from folder co-location)
        :parent_id,      # Parent task ID if this is a subtask
        :metadata,       # Extra frontmatter fields
        keyword_init: true
      ) do
        # Last 3 characters of the ID (shortcut for resolution)
        def shortcut
          id[-3..] if id
        end

        # Whether this task is a subtask (has a parent)
        def subtask?
          !parent_id.nil?
        end

        # Whether this task has subtasks
        def has_subtasks?
          subtasks && !subtasks.empty?
        end

        def to_s
          "Task(#{id}: #{title})"
        end
      end
    end
  end
end
