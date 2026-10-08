# frozen_string_literal: true
require "json"
require_relative "service_pr_input"
require_relative "../providers"
require_relative "../server_registry"

module Ace
  module Git
    module Atoms
      module ServicePrEvidence
        def self.validate(bytes, operation:, request_id:, input_digest:, target:, head:)
          unless ServicePrInput::DRAFT_OPERATIONS.include?(operation) || operation == "ready"
            raise ArgumentError, "unsupported PR evidence operation"
          end
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, 64 * 1024) &&
              bytes.dup.force_encoding(Encoding::UTF_8).valid_encoding? && !bytes.include?("\0")
            raise ArgumentError, "PR evidence is invalid or oversized"
          end
          marker, payload = bytes.split("\n", 2)
          unless marker == "ace-service-attestation request:#{request_id} input:#{input_digest} outcome:succeeded"
            raise ArgumentError, "PR evidence original marker differs"
          end
          value = JSON.parse(payload.to_s, max_nesting: 16, create_additions: false,
            allow_duplicate_key: false, allow_comments: false, allow_nan: false)
          closed!(value, %w[server operation input candidate_head receipt])
          input = ServicePrInput.validate(value.fetch("input"), operation: operation)
          unless value["operation"] == operation && value["candidate_head"] == head && input["target"] == target
            raise ArgumentError, "PR evidence operation/input/head differs"
          end
          server, receipt = value.values_at("server", "receipt")
          closed!(server, %w[name provider url])
          closed!(receipt, %w[server_name operation pull_request idempotency])
          pr = receipt.fetch("pull_request")
          closed!(pr, ProviderPullRequest.members.map(&:to_s))
          delivery = input.fetch("delivery")
          provenance = delivery.fetch("pr_provenance")
          reference = PrReference.parse(pr["url"])
          unless server["name"].is_a?(String) && server["provider"].is_a?(String) && server["url"].is_a?(String)
            raise ArgumentError, "PR evidence provider identity is malformed"
          end
          selected = ResolvedServer.new(name: server["name"], provider: server["provider"], url: server["url"])
          expected_title = Providers.for(selected).class.pull_request_title(title: input["title"], draft: true) if ServicePrInput::DRAFT_OPERATIONS.include?(operation)
          unless reference && reference.repository_url && pr["number"] == reference.number &&
              pr["number"].is_a?(Integer) && pr["number"].positive? &&
              server["name"].is_a?(String) && server["name"].match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/) &&
              server["provider"].is_a?(String) && server["provider"].match?(/\A[a-zA-Z0-9_-]{1,128}\z/) &&
              receipt["server_name"] == server["name"] && receipt["operation"] == operation &&
              pr["server_name"] == server["name"] && pr["head_sha"] == head &&
              head.is_a?(String) && head.match?(/\A[0-9a-f]{40}\z/) && pr["state"] == "open" &&
              pr["draft"] == ServicePrInput::DRAFT_OPERATIONS.include?(operation) &&
              pr.except("number", "draft").values.all? { |item| item.nil? || item.is_a?(String) } &&
              (operation == "create" ? %w[created existing].include?(receipt["idempotency"]) : receipt["idempotency"].nil?) &&
              pr["head_ref"] == provenance["head_ref"] && pr["base_ref"] == provenance["base_ref"] &&
              ServerUrl.match?(reference.repository_url, provenance["base_repository_url"]) &&
              ServerUrl.match?(server["url"], provenance["base_repository_url"]) &&
              ServerUrl.match?(pr["head_repository_url"], provenance["head_repository_url"]) &&
              ServerUrl.match?(pr["base_repository_url"], provenance["base_repository_url"]) &&
              (!delivery["forge_server"] || delivery["forge_server"] == server["name"]) &&
              (operation == "create" || pr["url"] == target["resource"]) &&
              (operation == "ready" || pr["title"] == expected_title && pr["body"] == input["body"])
            raise ArgumentError, "PR evidence selected identity or outcome differs"
          end
          DeliveryParameters.validate_url!(server["url"])
          {input: input, pr: pr, server: server}
        rescue JSON::ParserError, KeyError, TypeError, Ace::Git::Error
          raise ArgumentError, "PR evidence is malformed"
        end

        def self.closed!(value, fields)
          raise ArgumentError, "PR evidence fields differ" unless value.is_a?(Hash) && value.keys.sort == fields.sort
        end
        private_class_method :closed!
      end
    end
  end
end
