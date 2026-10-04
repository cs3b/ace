# frozen_string_literal: true

require "ace/hitl/contract"
require_relative "lab"

module Ace
  module Hitl
    # HITL provider adapters (spec 8wm.t.vrz): pluggable ask/delivery
    # transports behind one interface. Agent-facing ace-hitl paths resolve
    # adapters through this registry only — never a concrete transport.
    module Providers
      REGISTRY = {
        Lab::PROVIDER_NAME => -> { Lab.new }
      }.freeze

      module_function

      def available
        REGISTRY.keys.sort
      end

      def resolve(name)
        factory = REGISTRY[name.to_s]
        unless factory
          raise UnknownProviderError,
            "unknown HITL provider '#{name}' (available: #{available.join(', ')})"
        end

        factory.call
      end
    end
  end
end
