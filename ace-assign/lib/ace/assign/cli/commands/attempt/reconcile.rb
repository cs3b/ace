# frozen_string_literal: true

require "json"
require_relative "base"

module Ace
  module Assign
    module CLI
      module Commands
        module Attempt
          # Classify interruptions and resolve uncertainty against verified,
          # boundary-attributed receipts. Never replays external effects.
          class Reconcile < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Attempt::Base

            desc "Reconcile an interrupted or uncertain attempt"

            option :attempt, desc: "Attempt ID"
            option :mapping, desc: "Exact installed protected mapping ID"
            option :assignment, desc: "Exact protected assignment ID"
            option :mutation, desc: "Stable original authority mutation ID"
            option :expected_generation, desc: "Original authority mutation generation"
            option :receipt, desc: "Path to the receipt JSON file (required to resolve uncertainty)"

            def call(**options)
              if (context = protected_context(options))
                raise Ace::Support::Cli::Error, "Protected recovery forbids --receipt" unless options[:receipt].to_s.empty?
                usage = "reconcile --mapping MAP --assignment ID --attempt ID --mutation ID --expected-generation N"
                client, params, mutation = protected_attempt_request(context, options, usage)
                emit_json(protected_call(client, "recover", params, mutation))
                return
              end
              attempt_id = require_option(options, :attempt, "reconcile --attempt ID [--receipt FILE]")
              receipt = options[:receipt].to_s.strip

              result = build_coordinator.reconcile(
                attempt_id: attempt_id,
                receipt_path: receipt.empty? ? nil : receipt
              )

              emit_json(result.projection)
            end
          end
        end
      end
    end
  end
end
