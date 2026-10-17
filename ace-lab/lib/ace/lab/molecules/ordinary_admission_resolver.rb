# frozen_string_literal: true

require "time"
require_relative "ordinary_merge_policy"

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
      #
      # Per-request refresh (spec 8x3.t.xz9.5 integration handoff): a
      # long-lived receiver would otherwise decide every sequential candidate
      # against its boot-time snapshot of the authorization document. When a
      # trusted path is installed, every decision re-reads the document
      # through the trusted loader and resolves against the FRESH grants —
      # a root-revoked or expired decision fails closed at the next request
      # without any receiver restart. The refresh is scoped: it reloads and
      # re-validates the exact-request grant only; it never broadens
      # authorization beyond the resolved reference.
      class OrdinaryAdmissionResolver
        BINDING_KEYS = OrdinaryMergePolicy::ORDINARY_BINDING_KEYS.freeze
        DECISION_KEYS = OrdinaryMergePolicy::ORDINARY_AUTHORIZATION_KEYS.freeze
        OPERATION = "merge"

        Decision = Struct.new(:authorized?, :decision, :code, :message, keyword_init: true)

        # @param policy_document [Hash] boot-time trusted document (the
        #   configuration digest is derived from it once, upstream)
        # @param path [String, nil] trusted policy path to re-read per decision
        # @param loader [Proc, nil] trusted reader (default: GrantResolver);
        #   the only override point, for non-privileged test documents
        def initialize(policy_document, path: nil, loader: nil, proposal_resolver: nil, caller_uid: nil)
          unless policy_document.is_a?(Hash) && policy_document["authorizations"].is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError,
              "trusted policy document must contain an authorizations mapping"
          end
          @authorizations = policy_document.fetch("authorizations")
          @configuration_digest = OrdinaryMergePolicy.configuration_digest(policy_document)
          @path = path
          @proposal_resolver = proposal_resolver
          @caller_uid = caller_uid
          @loader = loader || ->(trusted_path) { GrantResolver.trusted_document(trusted_path) }
          freeze
        end

        # Resolve one authorization selector against the exact ordinary merge
        # request binding. Returns a typed Decision; `authorized?` is true only
        # for an exact, unexpired, ordinary-merge-shaped match.
        def decide(reference, binding)
          authorizations = current_authorizations
          unless reference.is_a?(String) && reference.match?(OrdinaryMergePolicy::ID)
            return refuse("invalid authorization reference")
          end
          unless binding.is_a?(Hash) && binding.fetch("operation", nil) == OPERATION
            return refuse("only the ordinary merge operation is resolvable")
          end
          if reference.start_with?("proposal-")
            return refuse("canonical proposal authority is unavailable") unless @proposal_resolver && @caller_uid.is_a?(Integer)
            begin
              decision = @proposal_resolver.call(reference, binding.slice(
                "operation", "project_id", "assignment_id", "attempt_id", "input_digest", "candidate_head").merge(
                  "target" => {"resource" => binding.fetch("pr_url"), "artifact_digest" => nil},
                  "caller_uid" => @caller_uid))
              return Decision.new(authorized?: true, decision: decision, code: nil, message: nil)
            rescue Ace::Assign::Error
              return refuse("canonical proposal does not authorize this exact ordinary merge")
            end
          end
          decision = authorizations[reference]
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

        # The authorizations mapping the CURRENT decision resolves against:
        # the boot snapshot when no trusted path is installed, otherwise the
        # freshly re-read document. A failed trusted re-read fails closed
        # (InvalidConfigurationError — the unavailable family), never falls
        # back to the stale snapshot.
        def current_authorizations
          return @authorizations unless @path
          document = @loader.call(@path)
          unless document.is_a?(Hash) && document["authorizations"].is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError,
              "invalid lab configuration: trusted authorization refresh at #{@path} " \
              "did not yield an authorizations mapping"
          end
          unless OrdinaryMergePolicy.configuration_digest(document) == @configuration_digest
            raise Ace::Lab::InvalidConfigurationError,
              "ordinary receiver configuration changed; restart with the installed configuration"
          end
          document.fetch("authorizations")
        end

        def refuse(message)
          Decision.new(authorized?: false, decision: nil,
            code: "ordinary_merge_authorization_invalid", message: message)
        end
      end
    end
  end
end
