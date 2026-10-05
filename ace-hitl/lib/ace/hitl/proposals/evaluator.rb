# frozen_string_literal: true

require "open3"
require "json"

module Ace
  module Hitl
    module Proposals
      # Invoked by the living overseer and on restart. No held HITL lock
      # while entering Hermes: reconcile acquires ingress then HITL/journal.
      class Evaluator
        def initialize(boundary:, config:, runner: Open3, binary: "/usr/local/bin/ace-hitl-hermes")
          @boundary, @config, @runner, @binary = boundary, config, runner, binary
        end

        def call
          raise Lifecycle::TransportError, "Hermes runtime configuration required" if @config.to_s.empty?
          results = []
          after = nil
          loop do
            page = @boundary.proposal_due(after: after)
            page.fetch("items").each do |proposal|
              out, _err, status = @runner.capture3(@binary, "ingress", "reconcile", "--config", @config,
                "--request", proposal.fetch("request_id"), "--through", proposal.fetch("deadline"), "--format", "json")
              unless status.success?
                results << {"proposal_id" => proposal["proposal_id"], "status" => "deferred"}
                next
              end
              checkpoint = JSON.parse(out)
              results << {"proposal_id" => proposal["proposal_id"],
                "status" => checkpoint.dig("proposal", "state") || "deferred"}
            end
            cursor = page.fetch("next")
            break unless cursor
            raise Lifecycle::TransportError, "proposal cursor did not advance" unless cursor.is_a?(String) && (!after || cursor > after)
            after = cursor
          end
          results
        rescue JSON::ParserError, KeyError, SystemCallError
          raise Lifecycle::TransportError, "proposal reconciliation unavailable; no authorization issued"
        end
      end
    end
  end
end
