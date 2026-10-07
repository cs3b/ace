# frozen_string_literal: true
require "json"
require_relative "delivery_parameters"
require_relative "pr_reference"
require_relative "../providers/evidence"

module Ace
  module Git
    module Atoms
      # Parse executor-owned evidence; authority supplies the original binding
      # and separately checks the reconstructed input's canonical digest.
      module ServiceMergeEvidence
        MAX_BYTES = 64 * 1024
        def self.validate(bytes, request_id:, input_digest:, target:, head:)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, MAX_BYTES) &&
              bytes.dup.force_encoding(Encoding::UTF_8).valid_encoding? && !bytes.include?("\0")
            raise ArgumentError, "merge evidence is invalid or oversized"
          end
          marker, payload = bytes.split("\n", 2)
          unless marker == "ace-service-attestation request:#{request_id} input:#{input_digest} outcome:succeeded"
            raise ArgumentError, "merge evidence original marker differs"
          end
          value = JSON.parse(payload.to_s, max_nesting: 16, create_additions: false,
            allow_duplicate_key: false, allow_comments: false, allow_nan: false)
          closed!(value, %w[server delivery method candidate_head receipt])
          delivery = DeliveryParameters.validate(value.fetch("delivery"))
          unless value["delivery"] == delivery && value["delivery"].keys.sort == %w[forge_default forge_server pr_provenance] &&
              %w[squash merge rebase].include?(value["method"]) && value["candidate_head"] == head
            raise ArgumentError, "merge evidence selection/method/head differs"
          end
          server, receipt = value.values_at("server", "receipt")
          closed!(server, %w[name provider url])
          closed!(receipt, %w[server_name operation pull_request idempotency])
          unless server["name"].is_a?(String) && server["name"].match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/) &&
              server["provider"].is_a?(String) && server["provider"].match?(/\A[a-zA-Z0-9_-]{1,128}\z/) &&
              receipt["server_name"] == server["name"] && receipt["operation"] == "merge"
            raise ArgumentError, "merge evidence provider receipt differs"
          end
          DeliveryParameters.validate_url!(server["url"])
          pr = receipt.fetch("pull_request")
          closed!(pr, ProviderPullRequest.members.map(&:to_s))
          provenance = delivery.fetch("pr_provenance")
          reference = target.is_a?(Hash) && PrReference.parse(target["resource"])
          unless reference && reference.repository_url && pr["number"].is_a?(Integer) && pr["number"].positive? &&
              pr["number"] == reference.number && pr["url"] == target["resource"] && pr["server_name"] == server["name"] &&
              pr["head_sha"] == head && head.is_a?(String) && head.match?(/\A[0-9a-f]{40}\z/) &&
              pr["state"] == "merged" && [true, false].include?(pr["draft"]) &&
              pr.except("number", "draft").values.all? { |value| value.nil? || value.is_a?(String) } &&
              pr["merge_commit_sha"].is_a?(String) && pr["merge_commit_sha"].match?(/\A[0-9a-f]{40}\z/) &&
              pr["head_ref"] == provenance["head_ref"] && pr["base_ref"] == provenance["base_ref"] &&
              ServerUrl.match?(reference.repository_url, provenance["base_repository_url"]) &&
              ServerUrl.match?(server["url"], provenance["base_repository_url"]) &&
              ServerUrl.match?(pr["head_repository_url"], provenance["head_repository_url"]) &&
              ServerUrl.match?(pr["base_repository_url"], provenance["base_repository_url"]) &&
              (!delivery["forge_server"] || delivery["forge_server"] == server["name"])
            raise ArgumentError, "merge evidence PR identity or outcome differs"
          end
          {input: {"target" => target, "delivery" => delivery, "method" => value.fetch("method")},
            pr: pr, server: server}
        rescue JSON::ParserError, KeyError, TypeError
          raise ArgumentError, "merge evidence is malformed"
        end

        def self.closed!(value, fields)
          raise ArgumentError, "merge evidence fields differ" unless value.is_a?(Hash) && value.keys.sort == fields.sort
        end
        private_class_method :closed!
      end
    end
  end
end
