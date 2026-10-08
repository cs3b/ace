# frozen_string_literal: true
require_relative "protected_submission"
require_relative "../../authority/receipt_transfer"
module Ace
  module Assign
    module CLI
      module Commands
        class SubmitResult < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include ProtectedSubmission
          desc "Submit original protected worker receipt bytes"
          option :mapping, desc: "Installed mapping"
          option :assignment, desc: "Original assignment"
          option :attempt, desc: "Original attempt"
          option :head, desc: "Exact candidate head"
          option :candidate_generation, desc: "Positive candidate generation"
          option :expected_generation, desc: "Persisted authority generation"
          option :mutation, desc: "Stable original mutation"
          option :receipt, desc: "Bounded local byte file"
          option :artifact, type: :array, desc: "Ordered artifact byte files"

          def call(**options)
            usage = "submit-result with original selectors, generation, mutation and --receipt FILE"
            client, params, mutation = submission_request(options, usage)
            head = require_option(options, :head, usage)
            raise Ace::Support::Cli::Error, "Head must be an exact SHA-1" unless head.match?(/\A[0-9a-f]{40}\z/)
            params.merge!("head" => head, "candidate_generation" => integer_option(options, :candidate_generation, usage, positive: true))
            bytes = input_bytes(require_option(options, :receipt, usage), limit: 16 * 1024)
            receipt = input_json(bytes)
            raise Ace::Support::Cli::Error, "Receipt must be an object" unless receipt.is_a?(Hash)
            allowed = %w[attempt_id assignment_id project_id scope operation producer head verdict artifacts checks review recorded_at digest]
            if (receipt.keys - allowed).any? || Models::ExecutionReceipt.forbidden_field?(receipt)
              raise Ace::Support::Cli::Error, "Receipt contains unsupported fields"
            end
            unless receipt.values_at("assignment_id", "attempt_id", "head") == params.values_at("assignment_id", "attempt_id", "head") &&
                Models::ExecutionReceipt::VERDICTS.include?(receipt["verdict"])
              raise Ace::Support::Cli::Error, "Receipt identity or verdict differs"
            end
            files = options.fetch(:artifact, [])
            unless files.is_a?(Array) && files.size <= 16 && !(receipt["verdict"] == "succeeded" && files.empty?)
              raise Ace::Support::Cli::Error, "Receipt artifact declarations are invalid"
            end
            artifacts = files.map { |path| input_bytes(path, limit: 64 * 1024, nonempty: false) }
            parts = [bytes, *artifacts]
            digest = Digest::SHA256.hexdigest(bytes)
            input = Struct.new(:parts) do
              def count = parts.length
              def bytes(index: 0) = parts.fetch(index)
            end.new(parts)
            # Reuse the maintained ordered artifact validator. This is input
            # checking only; canonical result/producer admission remains Endcap's.
            Ace::Assign::Authority::ReceiptTransfer.decode(input: input, receipt_sha256: digest,
              artifact_field: "artifacts", reference_key: "path")
            params["receipt_sha256"] = digest
            emit_json(upload_call(client, "submit_result", params, mutation, parts, :receipt_artifacts))
          end
        end
      end
    end
  end
end
