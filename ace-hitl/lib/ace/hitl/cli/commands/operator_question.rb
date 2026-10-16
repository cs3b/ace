# frozen_string_literal: true
require "ace/support/cli"
require_relative "lifecycle_command"
module Ace
  module Hitl
    module CLI
      module Commands
        class OperatorQuestion < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand
          desc "Create a nonsecret operator question without an execution or effect grant"
          argument :id, required: true, desc: "Stable question ID; reuse for an exact retry"
          option :project, type: :string, required: true, desc: "Exact installed operator project scope"
          option :question, type: :string, required: true, desc: "Nonsecret question"
          option :plan, type: :string, desc: "Nonsecret question context"
          option :options, type: :array, desc: "Nonsecret choices (comma-separated)"
          def call(id:, **options)
            emit(lifecycle_client.operator_question(id: id, project: options.fetch(:project),
              question: options.fetch(:question), plan: options.fetch(:plan, ""), options: options.fetch(:options, [])))
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
