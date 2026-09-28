# frozen_string_literal: true

module Ace
  module Lab
    module Atoms
      # Pure freshness classification for a runtime binding (spec 8wq.t.1w4).
      # A binding is fresh only when it is explicitly active AND the configured
      # instance identity exactly matches its attestation. Absent, inactive,
      # or mismatched identities classify as stale — never guessed fresh.
      module BindingFreshness
        FRESH = "fresh"
        STALE = "stale"

        class << self
          # @param binding [Ace::Lab::Models::RuntimeBinding, nil]
          # @return [String] FRESH or STALE
          def classify(binding)
            return STALE if binding.nil?
            return STALE unless binding.state == "active"
            return STALE if binding.instance_id.nil? || binding.instance_id.empty?
            return STALE unless binding.instance_id == binding.attested_instance_id

            FRESH
          end

          def fresh?(binding)
            classify(binding) == FRESH
          end
        end
      end
    end
  end
end
