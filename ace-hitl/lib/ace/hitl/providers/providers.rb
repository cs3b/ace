# frozen_string_literal: true

require_relative "errors"
require_relative "ref"
require_relative "lab"

module Ace
  module Hitl
    # HITL provider adapters (spec 8wm.t.vrz): pluggable ask/delivery
    # transports behind one interface. Agent-facing ace-hitl paths resolve
    # adapters through this registry only — never a concrete transport.
    module Providers
      # ask(question:, ...) result: local event id + relay request id.
      AskResult = Struct.new(:event_id, :request_id, keyword_init: true)

      # deliver(ref, answer) result; state is :delivered, :retryable
      # (safe to re-push identical content) or :failed.
      DeliverResult = Struct.new(:ref, :state, keyword_init: true)

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
