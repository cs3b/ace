# frozen_string_literal: true

module Ace
  module Hitl
    module Proposals
      # Authenticated proposer wake. The existing Hermes actor performs
      # reconciliation under its own transport identity after polling.
      class Evaluator
        def initialize(boundary:, project:)
          @boundary, @project = boundary, project
        end

        def call
          results = []
          after = nil
          loop do
            page = @boundary.proposal_wake(project: @project, after: after)
            results.concat(page.fetch("items"))
            cursor = page.fetch("next")
            break unless cursor
            raise Lifecycle::TransportError, "proposal cursor did not advance" unless cursor.is_a?(String) && (!after || cursor > after)
            after = cursor
          end
          results
        end
      end
    end
  end
end
