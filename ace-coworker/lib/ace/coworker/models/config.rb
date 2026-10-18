# frozen_string_literal: true

module Ace
  module Coworker
    module Models
      # Immutable validated coworker run configuration.
      class Config
        attr_reader :role, :instructions, :start_prompt, :start_prompt_file, :task, :assignment,
          :overseer, :reporting_channel, :on_failure, :source_path

        def initialize(role:, instructions:, start_prompt:, task:, assignment:, overseer:,
          start_prompt_file: nil, reporting_channel: "hitl", on_failure: "report", source_path: nil)
          @role = role.freeze
          @instructions = instructions.freeze
          @start_prompt = start_prompt.freeze
          @start_prompt_file = start_prompt_file.freeze
          @task = task.freeze
          @assignment = assignment.freeze
          @overseer = overseer.freeze
          @reporting_channel = reporting_channel.freeze
          @on_failure = on_failure.freeze
          @source_path = source_path.freeze
        end

        # A copy with a different assignment, e.g. a --assignment CLI
        # override threaded through report/resume. Single place so new
        # fields can never drift between the two identities.
        def with(assignment:)
          return self if assignment == @assignment

          self.class.new(role: role, instructions: instructions,
            start_prompt: start_prompt, start_prompt_file: start_prompt_file,
            task: task, assignment: assignment, overseer: overseer,
            reporting_channel: reporting_channel, on_failure: on_failure,
            source_path: source_path)
        end

        def to_h
          {
            "role" => role,
            "instructions" => instructions,
            "start_prompt" => start_prompt,
            "start_prompt_file" => start_prompt_file,
            "task" => task,
            "assignment" => assignment,
            "overseer" => overseer,
            "reporting" => {"channel" => reporting_channel},
            "errors" => {"on_failure" => on_failure}
          }.compact
        end
      end
    end
  end
end
