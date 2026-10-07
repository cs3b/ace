# frozen_string_literal: true

require "json"
require "etc"
require "ace/assign"
require_relative "../atoms/protected_workspace_prune_input"

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

        def input_binding(bytes, expected_digest:, expected_target:, operation: nil)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, Atoms::ServiceInput::MAX_BYTES)
            raise ArgumentError, "structured service input exceeds its fixed limit"
          end
          input = if operation == "prune-preserved-workspace"
            Atoms::ProtectedWorkspacePruneInput.parse(bytes)
          else
            JSON.parse(bytes)
          end
          raise ArgumentError, "structured service input must be an object" unless input.is_a?(Hash)
          Atoms::ServiceInput.validate!(input)
          digest = Atoms::ServiceInput.digest(input)
          target = Atoms::ServiceInput.target(input)
          unless digest == expected_digest && target == expected_target
            raise SecurityError, "structured service input differs from the bound digest or target"
          end
          deep_freeze(input: input, input_digest: digest, target: target)
        rescue JSON::ParserError
          raise ArgumentError, "structured service input must be valid JSON"
        end

        def prepare!(binding, input_bytes:)
          input = input_binding(input_bytes, expected_digest: binding.fetch("input_digest"),
            expected_target: binding.fetch("target"), operation: binding.fetch("operation"))
          authorized = authorize!(binding)
          canonical = snapshot(binding).merge("executor_uid" => authorized.fetch(:operation).fetch("executor_uid"), "transport" => "unix")
          deep_freeze(authorized.merge(binding: canonical, input: input.fetch(:input)))
        end

        # Called again inside each claim/begin CAS retry using the immutable
        # binding and ephemeral parsed input, never a caller filesystem path.
        def authorize!(binding)
          uid = binding.fetch("caller_uid")
          document = visible_document!(project: binding.fetch("project_id"), uid: uid)
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
          deep_freeze(operation: snapshot(operation), policy_digest: digest,
            operation_digest: Ace::Assign::Atoms::EvidenceDigest.digest(operation))
        end

        def visible!(project:, uid:)
          visible_document!(project: project, uid: uid)
          true
        end

        def authorize_update!(existing, replacement, _pending)
          initial_effect = existing.nil? && %w[accepted uncertain].include?(replacement["state"])
          fresh_dispatch = existing && existing["dispatch_phase"] == "issued" && replacement["dispatch_phase"] == "dispatch_started"
          authorize!(replacement) if initial_effect || fresh_dispatch
          true
        end

        private

        def visible_document!(project:, uid:)
          raise SecurityError, "protected caller UID is invalid" unless uid.is_a?(Integer) && uid.positive?
          username = begin
            Etc.getpwuid(uid).name
          rescue ArgumentError
            nil
          end
          document = @document_loader.call
          identities = CallerAuthorizer.matchable_identities(username, uid)
          visibility = CallerAuthorizer.new(principals: document.fetch("principals", {}), identity: identities)
          raise SecurityError, "caller project grant has been revoked" unless visibility.authorized?(project)
          document
        end

        def snapshot(value)
          JSON.parse(JSON.generate(value))
        end

        def deep_freeze(value)
          case value
          when Hash then value.each { |key, item| deep_freeze(key); deep_freeze(item) }
          when Array then value.each { |item| deep_freeze(item) }
          end
          value.freeze
        end
      end
    end
  end
end
