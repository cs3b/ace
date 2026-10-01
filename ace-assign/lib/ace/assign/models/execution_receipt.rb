# frozen_string_literal: true

require_relative "../atoms/evidence_digest"

module Ace
  module Assign
    module Models
      # Structured, non-secret execution receipt.
      #
      # A receipt is the only accepted proof that an attempted operation
      # completed: it names the attributed producer, the attempted operation,
      # the actual tested/reviewed head, the scope, a verdict, the required
      # artifacts with SHA-256 digests, and executed checks. Receipts never
      # carry credentials, terminal bytes, or receipt-file payloads; journal
      # entries keep metadata and digests only.
      class ExecutionReceipt
        VERDICTS = %w[succeeded failed].freeze

        # Field names rejected outright in receipt payloads: accepted evidence
        # is structured metadata, never raw process output or credentials.
        FORBIDDEN_FIELDS = %w[
          stdout stderr terminal_output log logs credentials secret secrets
          token password api_key private_key env environment
        ].freeze

        attr_reader :attempt_id, :assignment_id, :project_id, :scope, :operation,
          :producer, :head, :verdict, :artifacts, :checks, :review, :campaign, :recorded_at, :digest

        # @param attempt_id [String] Attempt the receipt belongs to
        # @param assignment_id [String] Owning assignment ID
        # @param project_id [String] Project the operation ran in
        # @param scope [String] Canonical step/subtree scope
        # @param operation [String] Attempted operation name
        # @param producer [Hash] Attributed producer (actor, role, runtime)
        # @param head [String] Actual tested/reviewed head
        # @param verdict [String] "succeeded" or "failed"
        # @param artifacts [Array<Hash>] Artifacts with path + sha256
        # @param checks [Array<Hash>] Executed checks with name + verdict
        # @param review [Hash, nil] Reviewer verdict for review receipts
        # @param recorded_at [Time] Receipt creation time
        # @param digest [String, nil] Canonical digest (computed when nil)
        def initialize(attempt_id:, assignment_id:, project_id:, scope:, operation:, producer:, head:, verdict:,
          artifacts: [], checks: [], review: nil, campaign: nil, recorded_at:, digest: nil)
          @attempt_id = attempt_id
          @assignment_id = assignment_id
          @project_id = project_id
          @scope = scope
          @operation = operation
          @producer = producer
          @head = head
          @verdict = verdict
          @artifacts = artifacts
          @checks = checks
          @review = review
          @campaign = campaign
          @recorded_at = recorded_at
          @digest = digest || Atoms::EvidenceDigest.digest(digest_payload)
        end

        # Canonical payload covered by the receipt digest (excludes the digest
        # itself and the record timestamp, which is assigned at acceptance).
        #
        # @return [Hash] Digest payload
        def digest_payload
          payload = {
            "attempt_id" => attempt_id,
            "assignment_id" => assignment_id,
            "project_id" => project_id,
            "scope" => scope,
            "operation" => operation,
            "producer" => producer,
            "head" => head,
            "verdict" => verdict,
            "artifacts" => artifacts,
            "checks" => checks,
            "review" => review
          }
          payload["campaign"] = campaign if campaign
          payload
        end

        # Convert to a hash for serialization.
        # @return [Hash] Receipt data with string keys
        def to_h
          digest_payload.merge(
            "recorded_at" => recorded_at.iso8601,
            "digest" => digest
          )
        end

        # Rebuild a receipt from serialized or submitted data.
        #
        # @param data [Hash] Receipt data (string keys); missing digest is computed
        # @return [ExecutionReceipt] Receipt instance
        def self.from_h(data)
          new(
            attempt_id: data["attempt_id"],
            assignment_id: data["assignment_id"],
            project_id: data["project_id"],
            scope: data["scope"],
            operation: data["operation"],
            producer: data["producer"] || {},
            head: data["head"],
            verdict: data["verdict"],
            artifacts: data["artifacts"] || [],
            checks: data["checks"] || [],
            review: data["review"],
            campaign: data["campaign"],
            recorded_at: parse_time(data["recorded_at"]) || Time.now.utc,
            digest: data["digest"]
          )
        end

        # Reject payloads that carry forbidden fields anywhere in the tree.
        #
        # @param data [Hash] Raw submitted receipt data
        # @return [Boolean] True if a forbidden field is present
        def self.forbidden_field?(data)
          case data
          when Hash
            data.any? { |key, value| FORBIDDEN_FIELDS.include?(key.to_s) || forbidden_field?(value) }
          when Array
            data.any? { |item| forbidden_field?(item) }
          else
            false
          end
        end

        def self.parse_time(value)
          return nil if value.nil?
          return value if value.is_a?(Time)
          require "time"
          Time.parse(value)
        end
        private_class_method :parse_time
      end
    end
  end
end
