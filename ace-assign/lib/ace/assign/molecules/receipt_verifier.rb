# frozen_string_literal: true

require "digest"
require "json"

module Ace
  module Assign
    module Molecules
      # Canonical receipt validation for accepted execution evidence.
      #
      # Verifies schema and field hygiene, attempt binding, producer
      # attribution, transition authority, current-head candidate binding,
      # artifact digests, executed checks, and independent review verdicts.
      # Every failure is a rejection with an actionable reason; a receipt is
      # never partially accepted.
      class ReceiptVerifier
        # Operations that act outside the local repository once executed.
        EXTERNAL_EFFECT_OPERATIONS = %w[merge publish deploy release].freeze

        REVIEW_OPERATION = "review"
        HEAD_PATTERN = /\A[0-9a-f]{7,64}\z/.freeze
        APPROVED_VERDICT = "approved"

        # @param identity_resolver [ExecutionIdentityResolver] Trust boundary
        # @param artifact_reader [#call, nil] Source-owned canonical byte
        #   reader for protected composition; nil selects explicit local files
        def initialize(identity_resolver: nil, artifact_reader: nil, campaign_verifier: nil)
          @identity_resolver = identity_resolver || ExecutionIdentityResolver.new
          unless artifact_reader.nil? || artifact_reader.respond_to?(:call)
            raise ArgumentError, "artifact reader must be a source-owned callable"
          end
          @artifact_reader = artifact_reader
          unless campaign_verifier.nil? || campaign_verifier.respond_to?(:call)
            raise ArgumentError, "campaign verifier must be a source-owned callable"
          end
          @campaign_verifier = campaign_verifier
        end

        # Validate a submitted receipt against an attempt.
        #
        # @param data [Hash] Parsed receipt payload
        # @param attempt [Models::Attempt] Target attempt (loaded by coordinator)
        # @param identity [ExecutionIdentityResolver::Identity] Finishing boundary identity
        # @param live_head [String] Current candidate revision (git rev-parse HEAD)
        # @param repo_root [String] Project root for artifact resolution
        # @return [Models::ExecutionReceipt] Normalized receipt with digest
        # @raise [AttemptErrors::ReceiptRejected] on any validation failure
        def verify!(data, attempt:, identity:, live_head:, repo_root:)
          verify_receipt!(data, attempt: attempt, live_head: live_head, repo_root: repo_root) do
            verify_authority(data, identity)
          end
        end

        # Submission validates evidence without granting terminal acceptance.
        # The authenticated owner separately checks the exact worker attribution.
        def verify_result!(data, attempt:, live_head:, repo_root:)
          verify_receipt!(data, attempt: attempt, live_head: live_head, repo_root: repo_root)
        end

        def verify_receipt!(data, attempt:, live_head:, repo_root:)
          reject_unless(data.is_a?(Hash), "receipt must be a JSON object")

          if Models::ExecutionReceipt.forbidden_field?(data)
            reject("receipt carries forbidden fields (credentials, environment, or terminal output)")
          end

          required = %w[attempt_id assignment_id project_id scope operation producer head verdict]
          missing = required.select { |key| data[key].nil? || data[key].to_s.strip.empty? }
          reject("missing required fields: #{missing.join(', ')}") unless missing.empty?
          unless Models::ExecutionReceipt::VERDICTS.include?(data["verdict"].to_s)
            reject("unsupported verdict '#{data['verdict']}': must be one of #{Models::ExecutionReceipt::VERDICTS.join(', ')}")
          end

          verify_binding(data, attempt)
          verify_producer(data)
          yield if block_given?
          verify_head(data, live_head)
          verify_artifacts(data, repo_root) if data["verdict"] == "succeeded"
          verify_checks(data)
          verify_review(data)
          verify_campaign(data, repo_root: repo_root, live_head: live_head)

          receipt = Models::ExecutionReceipt.from_h(data.merge("recorded_at" => Time.now.utc))
          verify_digest(receipt)

          receipt
        end
        private :verify_receipt!

        # Recheck the source artifacts/checks of an already accepted receipt.
        # Local historical reads (recorded at a past head) validate acceptance from
        # the append-only journal without re-hashing artifacts: the review
        # lifecycle legitimately archives and annotates finding files after
        # collection, and `.ace-local` working files are disposable, so their
        # current existence proves nothing about an accepted past receipt.
        # Current-head reads keep full artifact re-verification. Protected
        # readers always reverify imported bytes, including historical reads.
        def verify_accepted_evidence!(data, live_head:, repo_root:, historical: false)
          verify_head(data, live_head)
          artifacts = data["artifacts"]
          reject_unless(artifacts.is_a?(Array), "accepted artifacts must be an array")
          if (@artifact_reader || !historical) && (data["verdict"] == "succeeded" || !artifacts.empty?)
            verify_artifacts(data, repo_root)
          end
          verify_checks(data)
          verify_review(data)
          verify_campaign(data, repo_root: repo_root, live_head: live_head) if @artifact_reader
        end

        # @param operation [String] Receipt operation
        # @return [Boolean] True when the operation acts outside the repository
        def external_effect?(operation)
          EXTERNAL_EFFECT_OPERATIONS.include?(operation.to_s)
        end

        private

        def verify_binding(data, attempt)
          binding = attempt.binding
          unless data["attempt_id"] == attempt.attempt_id
            reject("receipt attempt_id #{data['attempt_id']} does not match attempt #{attempt.attempt_id}")
          end
          unless data["assignment_id"] == binding.assignment_id
            reject("receipt assignment #{data['assignment_id']} does not match attempt assignment #{binding.assignment_id}")
          end
          unless data["project_id"] == binding.project_id
            reject("receipt project #{data['project_id']} does not match attempt project #{binding.project_id}")
          end
          unless Atoms::AssignmentScope.equal?(data["scope"], binding.scope)
            reject("receipt scope #{data['scope']} does not match attempt scope #{binding.scope}")
          end
        end

        def verify_producer(data)
          producer = data["producer"]
          reject_unless(producer.is_a?(Hash), "producer must be an object with actor, role, runtime")

          actor = producer["actor"].to_s.strip
          role = producer["role"].to_s.strip
          runtime = producer["runtime"].to_s.strip
          if actor.empty? || runtime.empty? || !ExecutionIdentityResolver::ROLES.include?(role)
            reject("producer attribution incomplete: actor, runtime, and a known role are required")
          end
        end

        # Workers submit attributable results but cannot self-approve
        # succeeded outcomes; only coordinator/service authority accepts them.
        def verify_authority(data, identity)
          return if data["verdict"] != "succeeded"
          return if @identity_resolver.trusted?(identity)

          reject("identity #{identity.actor}/#{identity.role} may not accept a succeeded verdict")
        end

        # The tested/reviewed head must be the live candidate revision; stale
        # heads are rejected (candidate invalidation is recorded by the
        # coordinator).
        def verify_head(data, live_head)
          reject("live candidate head unavailable") if live_head.nil? || live_head.to_s.strip.empty?
          reject("receipt head '#{data['head']}' is not a git SHA") unless data["head"].match?(HEAD_PATTERN)

          unless data["head"] == live_head
            reject("receipt head #{data['head']} is stale; current candidate is #{live_head}")
          end
        end

        # Succeeded outcomes need at least one artifact whose recorded digest
        # matches the file on disk. Paths stay below the project root; symlink
        # or traversal escapes are rejected.
        def verify_artifacts(data, repo_root)
          artifacts = data["artifacts"]
          reject_unless(artifacts.is_a?(Array) && !artifacts.empty?, "succeeded verdict requires at least one artifact")

          artifacts.each do |artifact|
            reject_unless(artifact.is_a?(Hash), "artifact entries must be objects")
            path = artifact["path"].to_s
            recorded = artifact["sha256"].to_s
            reject("artifact missing path or sha256") if path.empty? || recorded.empty?

            actual = Digest::SHA256.hexdigest(artifact_bytes(data, artifact, repo_root))
            reject("artifact digest mismatch for #{path}") unless actual == recorded
          end
        end

        def verify_checks(data)
          checks = data["checks"] || []
          reject_unless(checks.is_a?(Array), "checks must be an array")
          if data["verdict"] == "succeeded" && checks.empty?
            reject("succeeded verdict requires at least one executed check")
          end

          checks.each do |check|
            reject_unless(check.is_a?(Hash), "check entries must be objects")
            reject("check missing name") if check["name"].to_s.strip.empty?
            reject("check #{check['name']} did not pass") if check["verdict"].to_s != "passed" && data["verdict"] == "succeeded"
          end
        end

        # A caller-supplied digest must equal the canonical digest of the
        # receipt payload; arbitrary or all-zero digests are rejected.
        def verify_digest(receipt)
          return if receipt.digest == Atoms::EvidenceDigest.digest(receipt.digest_payload)

          reject("receipt digest mismatch: supplied digest does not match the canonical payload")
        end

        # Review receipts need an executed, independent reviewer verdict for
        # exactly the tested head — a report existing is not approval, and a
        # review receipt without a reviewer verdict is not evidence.
        def verify_review(data)
          review = data["review"]
          if review.nil?
            if data["operation"] == REVIEW_OPERATION && data["verdict"] == "succeeded"
              reject("review receipt requires an executed independent reviewer verdict")
            end

            return
          end

          reject_unless(review.is_a?(Hash), "review must be an object")
          reviewer = review["reviewer"]
          reject_unless(reviewer.is_a?(Hash) && !reviewer["actor"].to_s.strip.empty?, "review must name an executed reviewer")

          producer_actor = data.dig("producer", "actor").to_s.strip
          if reviewer["actor"].to_s.strip == producer_actor
            reject("reviewer and producer must differ (self-approval rejected)")
          end

          reject("review verdict must be '#{APPROVED_VERDICT}' for a succeeded receipt") if review["verdict"] != APPROVED_VERDICT && data["verdict"] == "succeeded"
          unless review["head"] == data["head"]
            reject("review head #{review['head']} does not match receipt head #{data['head']}")
          end
        end

        # Consume ace-review's single campaign authority through the existing
        # receipt boundary; a worker-supplied local result grants no authority.
        def verify_campaign(data, repo_root:, live_head:)
          campaign = data["campaign"]
          return unless campaign
          reject_unless(campaign.is_a?(Hash), "campaign must be an object")
          reject("campaign result requires a succeeded review receipt") unless
            data["operation"] == REVIEW_OPERATION && data["verdict"] == "succeeded"
          reference = campaign["result"]
          reject_unless(reference.is_a?(Hash), "campaign requires a result artifact reference")
          unless Array(data["artifacts"]).include?(reference)
            reject("campaign result must be included in verified receipt artifacts")
          end
          result = JSON.parse(artifact_bytes(data, reference, repo_root))
          reject_unless(result.is_a?(Hash), "campaign result must be an object")
          if @campaign_verifier
            @campaign_verifier.call(data, result, live_head)
            return
          end
          require "ace/review"
          manager = Ace::Review::Organisms::CampaignManager.new(repo_root: repo_root)
          current = manager.status(campaign["id"])
          reject("campaign result ID differs from receipt") unless result["campaign_id"] == campaign["id"]
          manager.with_verified_result!(result: result, subject: current.fetch("subject"),
            contract_identity: current.fetch("contract_identity"), policy: current.fetch("effective_policy"),
            head: live_head, base: current.fetch("evidence").fetch("current_base"),
            producer: data.dig("producer", "actor"), reviewer: data.dig("review", "reviewer", "actor")) { true }
        rescue JSON::ParserError, ArgumentError, TypeError, KeyError => e
          reject("invalid campaign result: #{e.message}")
        end

        # Protected composition injects the canonical imported-byte owner.
        # Its failure never falls through to the disposable workspace copy.
        def artifact_bytes(data, artifact, repo_root)
          if @artifact_reader
            bytes = @artifact_reader.call(data, artifact)
            reject("canonical artifact reader did not return bytes") unless bytes.is_a?(String)
            return bytes.b
          end
          path = artifact["path"].to_s
          expanded = begin
            File.expand_path(path, File.realpath(repo_root))
          rescue Errno::ENOENT, Errno::EACCES
            nil
          end
          reject("artifact file not found: #{path}") if expanded.nil? || !File.exist?(expanded)
          resolved = safe_resolve(repo_root, path)
          reject("artifact path escapes project root: #{path}") if resolved.nil?
          File.read(resolved)
        end

        # Resolve a project-relative artifact path to its real location,
        # rejecting traversal and symlink escapes (an in-repo symlink must
        # not smuggle in an external file); returns nil when the path leaves
        # the root.
        def safe_resolve(repo_root, path)
          root = File.realpath(repo_root)
          candidate = File.expand_path(path, root)
          return nil unless candidate == root || candidate.start_with?(root + File::SEPARATOR)
          return nil unless File.exist?(candidate)

          resolved = File.realpath(candidate)
          return nil unless resolved == root || resolved.start_with?(root + File::SEPARATOR)

          resolved
        rescue Errno::ENOENT, Errno::EACCES
          nil
        end

        def reject(message)
          raise AttemptErrors::ReceiptRejected, message
        end

        def reject_unless(condition, message)
          reject(message) unless condition
        end
      end
    end
  end
end
