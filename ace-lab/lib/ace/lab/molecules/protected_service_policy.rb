# frozen_string_literal: true

require "json"
require "etc"
require "ace/assign"

module Ace
  module Lab
    module Molecules
      # The receiver and authority share the existing input/policy owners.
      # Only composition supplies collaborators; no wire-selected policy,
      # executable, input path or caller identity is accepted here.
      class ProtectedServicePolicy
        def initialize(proposal_resolver:, document_loader: nil)
          @proposal_resolver = proposal_resolver
          @document_loader = document_loader || -> { GrantResolver.trusted_document(Ace::Lab.authorization_path) }
        end

        def input_binding(bytes, expected_digest:, expected_target:)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, Atoms::ServiceInput::MAX_BYTES)
            raise ArgumentError, "structured service input exceeds its fixed limit"
          end
          input = JSON.parse(bytes)
          raise ArgumentError, "structured service input must be an object" unless input.is_a?(Hash)
          Atoms::ServiceInput.validate!(input)
          digest = Atoms::ServiceInput.digest(input)
          target = Atoms::ServiceInput.target(input)
          unless digest == expected_digest && target == expected_target
            raise SecurityError, "structured service input differs from the bound digest or target"
          end
          {input: input, input_digest: digest, target: target}
        rescue JSON::ParserError
          raise ArgumentError, "structured service input must be valid JSON"
        end

        def prepare!(binding, input_bytes:)
          input = input_binding(input_bytes, expected_digest: binding.fetch("input_digest"), expected_target: binding.fetch("target"))
          authorized = authorize!(binding)
          canonical = binding.merge("executor_uid" => authorized.fetch(:operation).fetch("executor_uid"), "transport" => "unix")
          authorized.merge(binding: canonical, input: input.fetch(:input))
        end

        # Called again inside each claim/begin CAS retry using the immutable
        # binding and ephemeral parsed input, never a caller filesystem path.
        def authorize!(binding)
          uid = binding.fetch("caller_uid")
          raise SecurityError, "protected caller UID is invalid" unless uid.is_a?(Integer) && uid.positive?
          username = begin
            Etc.getpwuid(uid).name
          rescue ArgumentError
            nil
          end
          document = @document_loader.call
          identities = CallerAuthorizer.matchable_identities(username, uid)
          visibility = CallerAuthorizer.new(principals: document.fetch("principals", {}), identity: identities)
          raise SecurityError, "caller project grant has been revoked" unless visibility.authorized?(binding.fetch("project_id"))
          resolver = ->(reference, exact) { @proposal_resolver.call(binding.fetch("project_id"), reference, exact) }
          policy = ServicePolicy.new(document, resolver)
          operation = policy.operation!(binding.fetch("operation"), project: binding.fetch("project_id"), service_id: binding.fetch("service_id"))
          unless operation.fetch("transport", "local") == "local"
            raise Ace::Lab::InvalidConfigurationError, "protected receiver requires a fixed local handler operation"
          end
          unless operation.fetch("executor_uid").positive? && operation.fetch("executor_uid") != uid
            raise SecurityError, "protected executor must be a separate nonroot account"
          end
          if binding.key?("executor_uid") && binding["executor_uid"] != operation.fetch("executor_uid")
            raise SecurityError, "configured executor differs from the recorded claim"
          end
          decision = policy.authorize!(binding.fetch("authorization"), binding)
          digest = Ace::Assign::Atoms::EvidenceDigest.digest("operation" => operation, "authorization" => decision,
            "caller_uid" => uid, "project_id" => binding.fetch("project_id"))
          if binding.key?("policy_digest") && binding["policy_digest"] != digest
            raise SecurityError, "service policy changed after claim"
          end
          {operation: operation, policy_digest: digest}
        end
      end
    end
  end
end
