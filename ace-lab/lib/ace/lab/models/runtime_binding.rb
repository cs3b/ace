# frozen_string_literal: true

module Ace
  module Lab
    module Models
      # Immutable runtime binding of an agent or service (spec 8wq.t.1w4).
      # Carries configured identity facts only — never probes a runtime.
      # Freshness (active state + exact instance/attestation identity match)
      # is classified by Atoms::BindingFreshness.
      class RuntimeBinding
        KINDS = %w[runtime service].freeze

        attr_reader :kind, :state, :instance_id, :attested_instance_id

        def initialize(kind:, state: nil, instance_id: nil, attested_instance_id: nil)
          @kind = kind
          @state = state
          @instance_id = instance_id
          @attested_instance_id = attested_instance_id
          freeze
        end

        def self.from_h(hash)
          new(
            kind: hash["kind"],
            state: hash["state"],
            instance_id: hash["instance_id"],
            attested_instance_id: hash["attested_instance_id"]
          )
        end

        def to_h
          {
            "kind" => kind, "state" => state,
            "instance_id" => instance_id, "attested_instance_id" => attested_instance_id
          }
        end
      end
    end
  end
end
