# frozen_string_literal: true

module Ace
  module Scheduler
    module Atoms
      class CrontabBuilder
        def build_entry(cron:, task_name:, command:, project_root: Dir.pwd)
          "#{cron} cd #{project_root} && ace-scheduler run #{task_name}"
        end

        def build_entries(tasks, project_root: Dir.pwd)
          tasks.map do |task|
            build_entry(cron: task[:cron], task_name: task[:name], command: task[:command], project_root: project_root)
          end
        end
      end
    end
  end
end
