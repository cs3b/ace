# frozen_string_literal: true
require_relative "protected_submission"
require_relative "../../authority/campaign_round_transfer"

module Ace
  module Assign
    module CLI
      module Commands
        class CampaignRecordRound < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include ProtectedSubmission
          desc "Consume settled protected campaign children into the original R1 store"
          option :mapping, desc: "Original installed parent mapping"
          option :assignment, desc: "Original parent assignment"
          option :attempt, desc: "Original parent attempt"
          option :head, desc: "Exact parent candidate head"
          option :candidate_generation, desc: "Exact parent candidate counter"
          option :mutation, desc: "Stable R1 round attempt ID"
          option :input, desc: "Closed bounded round envelope"
          option :artifact, type: :array, desc: "Ordered report byte files"

          def call(**options)
            usage = "campaign-record-round with original parent selectors, --mutation ID and --input FILE"
            context = protected_context(options)
            raise AttemptErrors::EvidenceUnavailable, "Campaign consumption requires installed authority" unless context
            params = {"assignment_id" => require_option(options, :assignment, usage),
              "attempt_id" => require_option(options, :attempt, usage), "head" => require_option(options, :head, usage),
              "candidate_generation" => integer_option(options, :candidate_generation, usage, positive: true)}
            unless params["head"].match?(/\A[0-9a-f]{40}\z/)
              raise Ace::Support::Cli::Error, "Campaign head must be an exact SHA-1"
            end
            context.verify_attempt_hints!(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"))
            mutation = require_option(options, :mutation, usage)
            bytes = input_bytes(require_option(options, :input, usage), limit: 16 * 1024)
            files = options.fetch(:artifact, [])
            raise Ace::Support::Cli::Error, "Campaign artifacts require at most 16 files" unless files.is_a?(Array) && files.size <= 16
            parts = [bytes, *files.map { |path| input_bytes(path, limit: 64 * 1024, nonempty: false) }]
            params["input_sha256"] = Digest::SHA256.hexdigest(bytes)
            input = Struct.new(:parts) do
              def count = parts.length
              def bytes(index:) = parts.fetch(index)
            end.new(parts)
            admitted = Ace::Assign::Authority::CampaignRoundTransfer.decode(input: input, sha256: params.fetch("input_sha256"))
            unless admitted.fetch(:round).values_at("attempt_id", "head") == [mutation, params.fetch("head")]
              raise Ace::Support::Cli::Error, "Campaign input request ID or head differs"
            end
            emit_json(upload_call(context.client(options: options), "campaign_record_round", params, mutation, parts, :receipt_artifacts))
          rescue SecurityError, Ace::Runtime::RuntimeUnavailableError
            protected_transport_unavailable!
          rescue ArgumentError => error
            raise Ace::Support::Cli::Error, error.message
          end
        end
      end
    end
  end
end
