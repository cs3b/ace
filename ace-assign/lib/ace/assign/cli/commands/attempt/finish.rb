# frozen_string_literal: true

require "json"
require_relative "base"

module Ace
  module Assign
    module CLI
      module Commands
        module Attempt
          # Protected completion selects an already submitted canonical result.
          # Ordinary local completion accepts its structured receipt file.
          class Finish < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Attempt::Base

            desc "Finish a protected canonical result or an ordinary local receipt"

            option :attempt, desc: "Attempt ID"
            option :mapping, desc: "Exact installed protected mapping ID"
            option :assignment, desc: "Exact protected assignment ID"
            option :mutation, desc: "Stable original authority mutation ID"
            option :expected_generation, desc: "Original authority mutation generation"
            option :receipt, desc: "Path to the ordinary local receipt JSON file"
            option :result, desc: "Already submitted canonical protected result ID"
            option :head, desc: "Exact canonical candidate head"
            option :candidate_generation, desc: "Original canonical candidate generation"

            def call(**options)
              if (context = protected_context(options))
                raise Ace::Support::Cli::Error, "Protected finish forbids --receipt" unless options[:receipt].to_s.empty?
                usage = "finish --mapping MAP --assignment ID --attempt ID --result ID --head SHA --candidate-generation N --mutation ID --expected-generation N"
                client, params, mutation = protected_attempt_request(context, options, usage)
                params.merge!("result_id" => require_option(options, :result, usage), "head" => require_option(options, :head, usage),
                  "candidate_generation" => integer_option(options, :candidate_generation, usage, positive: true))
                emit_json(protected_call(client, "finish", params, mutation))
                return
              end
              attempt_id = require_option(options, :attempt, "finish --attempt ID --receipt FILE")
              receipt = require_option(options, :receipt, "finish --attempt ID --receipt FILE")

              result = build_coordinator.finish(attempt_id: attempt_id, receipt_path: receipt)

              emit_json(result.projection)
            end
          end
        end
      end
    end
  end
end
