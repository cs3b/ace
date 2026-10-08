# frozen_string_literal: true
require_relative "protected_submission"
module Ace
  module Assign
    module CLI
      module Commands
        class SubmitCandidate < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include ProtectedSubmission
          desc "Submit original protected worker bundle bytes"
          option :mapping, desc: "Installed mapping"
          option :assignment, desc: "Original assignment"
          option :attempt, desc: "Original attempt"
          option :head, desc: "Exact candidate head"
          option :candidate_generation, desc: "Expected current candidate generation (zero before first submission)"
          option :expected_generation, desc: "Persisted authority generation"
          option :mutation, desc: "Stable original mutation"
          option :bundle, desc: "Bounded local byte file"

          def call(**options)
            usage = "submit-candidate with original selectors, generation, mutation and --bundle FILE"
            client, params, mutation = submission_request(options, usage)
            head = require_option(options, :head, usage)
            raise Ace::Support::Cli::Error, "Head must be an exact SHA-1" unless head.match?(/\A[0-9a-f]{40}\z/)
            params.merge!("head" => head, "candidate_generation" => integer_option(options, :candidate_generation, usage))
            bytes = input_bytes(require_option(options, :bundle, usage), limit: 64 * 1024 * 1024)
            parts = [bytes]
            emit_json(upload_call(client, "submit_candidate", params, mutation, parts, :candidate))
          end
        end
      end
    end
  end
end
