# frozen_string_literal: true
require "json"
require_relative "../../organisms/protected_review"

module Ace
  module Overseer
    module CLI
      module Commands
        class Review < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Review an exact protected candidate, inspect its request, or cancel its reservation"
          option :project, required: true, desc: "Installed project ID"
          option :agent, required: true, desc: "Installed agent mapping ID"
          option :assignment, required: true, desc: "Assignment ID"
          option :attempt, required: true, desc: "Attempt ID"
          option :mutation, required: true, desc: "Request or cancel mutation; original request ID for status"
          option :status, type: :boolean, default: false, desc: "Observe the original review request without execution"
          option :cancel, type: :boolean, default: false, desc: "Cancel the exact review reservation"
          option :head, desc: "Exact candidate commit"
          option :candidate_generation, type: :integer, desc: "Exact candidate generation"
          option :expected_generation, type: :integer, desc: "Observed authority generation; never refreshed implicitly"
          option :accept_mutation, desc: "Distinct acceptance mutation for a new review"
          option :review_event, desc: "Exact reservation event to cancel"

          def initialize(review: nil)
            super()
            @review = review || Organisms::ProtectedReview.new
          end

          def call(project:, agent:, assignment:, attempt:, mutation:, status: false, cancel: false,
            head: nil, candidate_generation: nil, expected_generation: nil, accept_mutation: nil, review_event: nil, **extra)
            raise Error, "Unsupported review options" unless extra.empty?
            result = @review.call(project: project, agent: agent, assignment: assignment, attempt: attempt,
              mutation: mutation, status: status, cancel: cancel, head: head, candidate_generation: candidate_generation,
              expected_generation: expected_generation, accept_mutation: accept_mutation, review_event: review_event)
            puts JSON.pretty_generate(result)
          rescue StandardError => error
            raise Ace::Support::Cli::Error.new(error.message)
          end
        end
      end
    end
  end
end
