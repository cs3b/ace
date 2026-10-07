# frozen_string_literal: true
require "json"
require_relative "../../organisms/protected_steering"
module Ace
  module Overseer
    module CLI
      module Commands
        class Stop < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Request proof-authenticated stop of an exact protected attempt"
          option :project, required: true, desc: "Installed project ID"
          option :agent, required: true, desc: "Literal installed mapping ID"
          option :assignment, required: true, desc: "Original assignment ID"
          option :attempt, required: true, desc: "Original attempt ID"
          option :mutation, required: true, desc: "Stable stop mutation ID"
          option :expected_generation, type: :integer, required: true, desc: "Observed original generation; never refreshed"
          def initialize(steering: nil)
            super()
            @steering = steering || Organisms::ProtectedSteering.new
          end
          def call(project:, agent:, assignment:, attempt:, mutation:, expected_generation:, **extra)
            raise Error, "Unsupported stop options" unless extra.empty?
            result = @steering.stop(project: project, agent: agent, assignment: assignment, attempt: attempt,
              mutation: mutation, expected_generation: expected_generation)
            puts JSON.pretty_generate(result)
          rescue StandardError => error
            raise Ace::Support::Cli::Error, error.message
          end
        end
      end
    end
  end
end
