# frozen_string_literal: true

require "etc"

module Ace
  module Lab
    module Molecules
      # The lab-side HITL delivery authorization (spec 8wq.t.34i): which
      # authenticated transport may submit correlated answers for a
      # Captain, derived from the SAME trusted deployment document that
      # carries the service principals — read through the grant
      # resolver's verified traversal, never from the cascade. The peer
      # uid is a KERNEL fact resolved by the HITL boundary; this policy
      # never trusts a claimed name.
      class HitlAuthorizer
        # @param principals [Hash] authorization.principals from the
        #   trusted document (uid-string or username keys, per-project)
        # @param transport_uids [Array<Integer>] uids authorized to act
        #   as the configured transport
        # @param service_uid [Integer, nil] the trusted HITL service uid
        def initialize(principals: {}, transport_uids: [], service_uid: nil)
          @principals = principals || {}
          @transport_uids = Array(transport_uids)
          @service_uid = service_uid
        end

        # Build from the trusted deployment document at a fixed path
        # (same file the service policy resolves principals from).
        # @return [HitlAuthorizer]
        def self.from_trusted_document(path, loader = GrantResolver)
          document = loader.trusted_document(path)
          hitl = document["hitl"].is_a?(Hash) ? document["hitl"] : {}
          principals = document.dig("authorization", "principals")
          new(
            principals: principals.is_a?(Hash) ? principals : {},
            transport_uids: Array(hitl["transport_uids"]),
            service_uid: hitl["service_uid"]
          )
        end

        # @return [Integer, nil] the trusted HITL service identity
        def service_uid
          @service_uid.is_a?(Integer) ? @service_uid : nil
        end

        # The transport may submit a correlated answer from an authorized
        # Captain when its KERNEL-VERIFIED uid is a configured transport
        # AND the transport's principal is visible for the request's
        # project. Unknown identity is an error-shaped refusal, never
        # permission.
        def delivery_authorized?(uid:, project_id:)
          return false unless @transport_uids.include?(uid)

          policy = @principals[uid.to_s]
          return false unless policy.is_a?(Hash)

          projects = Array(policy["projects"]).map(&:to_s)
          projects.empty? || projects.include?(project_id.to_s)
        end
      end
    end
  end
end
