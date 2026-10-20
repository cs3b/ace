# frozen_string_literal: true

require "ace/support/cli/toolchain"

module Ace
  module Coworker
    module Models
      # Executor brief rendered by `ace-coworker start`.
      class Brief
        attr_reader :config, :instructions_source, :task_path, :assignment_snapshot, :project_root

        def initialize(config:, instructions_source:, task_path:, assignment_snapshot:, project_root:)
          @config = config
          @instructions_source = instructions_source.freeze
          @task_path = task_path.freeze
          @assignment_snapshot = assignment_snapshot
          @project_root = project_root.freeze
        end

        def to_h
          {
            "toolchain" => Ace::Support::Cli::Toolchain.evidence,
            "role" => config.role,
            "instructions" => config.instructions,
            "instructions_source" => instructions_source,
            "start_prompt" => config.start_prompt,
            "task" => config.task,
            "task_path" => task_path,
            "assignment" => config.assignment,
            "assignment_state" => assignment_snapshot&.state,
            "assignment_progress" => assignment_snapshot&.progress,
            "overseer" => config.overseer,
            "reporting_channel" => config.reporting_channel,
            "on_failure" => config.on_failure,
            "project_root" => project_root
          }
        end
      end
    end
  end
end
