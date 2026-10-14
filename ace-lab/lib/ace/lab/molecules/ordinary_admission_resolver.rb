# frozen_string_literal: true

require "time"
require_relative "service_policy"

module Ace
  module Lab
    module Molecules
      # The scoped ordinary-merge decision/admission resolver (spec 8x3.t.xz9.4,
      # execution clauses). The deployment-owned YAML authorization file remains
      # the sole source of truth; this resolver only makes the exact root
      # authorizations natively executable inside the receiver: one per-request
      # authorization selector resolves to a typed decision within the closed
      # refusal-code family — or it refuses. Scoping rules:
      #
      # - only `operation: merge` decisions of the ordinary shape resolve;
      #   anything else (missing reference, shape mismatch, non-merge
      #   operation, any binding mismatch, expiry) is a typed
      #   `ordinary_merge_authorization_invalid` decision;
      # - exact binding match on every closed key; there are NO wildcards,
      #   defaults, prefix grants or broad grants of any kind — a decision
      #   authorizes exactly one bound request and nothing else;
      # - expiry bounds the decision itself.
      class OrdinaryAdmissionResolver
        BINDING_KEYS = ServicePolicy::ORDINARY_BINDING_KEYS.freeze
        DECISION_KEYS = ServicePolicy::ORDINARY_AUTHORIZATION_KEYS.freeze
        OPERATION = "merge"

        Decision = Struct.new(:authorized?, :decision, :code, :message, keyword_init: true)

        def initialize(policy_document)
          unless policy_document.is_a?(Hash) && policy_document["authorizations"].is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError,
              "trusted policy document must contain an authorizations mapping"
          end
          @authorizations = policy_document.fetch("authorizations")
        end

        # Resolve one authorization selector against the exact ordinary merge
        # request binding. Returns a typed Decision; `authorized?` is true only
        # for an exact, unexpired, ordinary-merge-shaped match.
        def decide(reference, binding)
          unless reference.is_a?(String) && reference.match?(ServicePolicy::ID)
            return refuse("invalid authorization reference")
          end
          unless binding.is_a?(Hash) && binding.fetch("operation", nil) == OPERATION
            return refuse("only the ordinary merge operation is resolvable")
          end
          decision = @authorizations[reference]
          return refuse("authorization reference is unresolved") unless decision.is_a?(Hash)
          unless DECISION_KEYS.all? { |key| decision.key?(key) }
            return refuse("authorization reference is not an ordinary merge decision")
          end
          unless decision.fetch("operation") == OPERATION
            return refuse("authorization does not cover the ordinary merge operation")
          end
          mismatch = BINDING_KEYS.find { |key| decision.fetch(key) != binding.fetch(key, nil) }
          return refuse("authorization does not match the exact ordinary merge request") if mismatch
          begin
            expired = Time.iso8601(decision.fetch("expires_at").to_s) <= Time.now.utc
          rescue ArgumentError
            return refuse("authorization decision has an invalid expiry")
          end
          return refuse("authorization has expired") if expired
          Decision.new(authorized?: true, decision: decision, code: nil, message: nil)
        end

        private

        def refuse(message)
          Decision.new(authorized?: false, decision: nil,
            code: "ordinary_merge_authorization_invalid", message: message)
        end
      end
    end
  end
end
