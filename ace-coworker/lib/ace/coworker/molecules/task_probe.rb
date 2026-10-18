# frozen_string_literal: true

require "ace/task"
require "ace/task/organisms/task_manager"

module Ace
  module Coworker
    module Molecules
      # Resolves the config task ref inside the project root using the
      # ace-task library (same resolution ace-overseer relies on).
      class TaskProbe
        def initialize(project_root:, task_manager: nil)
          @project_root = project_root
          @task_manager = task_manager || Ace::Task::Organisms::TaskManager.new(root_dir: task_root)
        end

        # @return [Ace::Task::Models::Task, nil]
        def resolve(ref)
          @task_manager.show(ref.to_s)
        end

        # @return [String] absolute path of the task folder
        # @raise [Error] when the ref does not resolve in this worktree
        def resolve!(ref)
          task = resolve(ref)
          raise Error, "task '#{ref}' not found in this worktree" if task.nil?

          dir = task.respond_to?(:path) ? task.path : nil
          dir || File.join(task_root, task.id.to_s)
        end

        private

        def task_root
          File.join(@project_root, ".ace-tasks")
        end
      end
    end
  end
end
