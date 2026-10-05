# frozen_string_literal: true

require "json"
require "digest"

module Ace
  module Assign
    module Authority
      # Receipt-first binary framing. Field names come from source operations,
      # never from the wire. Artifact order and declared digests are exact.
      module ReceiptTransfer
        def self.decode(input:, receipt_sha256:, artifact_field:, reference_key:)
          unless input && input.count.between?(1, 17) && %w[artifacts evidence].include?(artifact_field) &&
              %w[path ref].include?(reference_key) && receipt_sha256.is_a?(String) && receipt_sha256.match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::ReceiptRejected, "receipt transfer binding is invalid"
          end
          bytes = input.bytes(index: 0)
          unless bytes.bytesize.between?(1, 16 * 1024) && Digest::SHA256.hexdigest(bytes) == receipt_sha256
            raise AttemptErrors::ReceiptRejected, "first transfer part must be the exact receipt"
          end
          receipt = JSON.parse(bytes)
          unless receipt.is_a?(Hash) && !Models::ExecutionReceipt.forbidden_field?(receipt)
            raise AttemptErrors::ReceiptRejected, "receipt must contain bounded structured evidence"
          end
          references = receipt.fetch(artifact_field)
          unless references.is_a?(Array) && references.length == input.count - 1 && references.length <= 16 &&
              references.all? { |entry| entry.is_a?(Hash) && entry.keys.sort == [reference_key, "sha256"].sort &&
                entry[reference_key].is_a?(String) && entry[reference_key].bytesize.between?(1, 256) &&
                entry["sha256"].is_a?(String) && entry["sha256"].match?(/\A[0-9a-f]{64}\z/) } &&
              references.map { |entry| entry[reference_key] }.uniq.length == references.length
            raise AttemptErrors::ReceiptRejected, "receipt artifact parts are incomplete or duplicated"
          end
          artifacts = references.each_with_index.map do |reference, index|
            artifact = input.bytes(index: index + 1)
            unless artifact.bytesize <= 64 * 1024 && Digest::SHA256.hexdigest(artifact) == reference.fetch("sha256")
              raise AttemptErrors::ReceiptRejected, "receipt artifact part differs from declaration"
            end
            artifact
          end
          raise AttemptErrors::ReceiptRejected, "receipt evidence exceeds its transfer limit" if artifacts.sum(&:bytesize) > 256 * 1024
          {receipt: receipt, artifacts: artifacts, receipt_sha256: receipt_sha256}
        rescue JSON::ParserError, KeyError
          raise AttemptErrors::ReceiptRejected, "receipt transfer schema is invalid"
        end
      end
    end
  end
end
