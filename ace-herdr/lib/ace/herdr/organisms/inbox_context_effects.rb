# frozen_string_literal: true

require_relative "../molecules/inbox_context_completion_client"

module Ace
  module Herdr
    module Organisms
      # Source effect methods on the same context owner and admission metadata.
      module InboxContextEffects
        SNAPSHOT_FIELDS = %w[event_id attempt_id payload_sha256 claim_generation state origin_target target binding].freeze

        private

        def source_inbox!(selected)
          raise ValidationError, "fixed context Inbox owner is unavailable" unless @inbox.is_a?(Inbox)
          @inbox
        end

        def immutable_effect(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable_effect(item)] }.freeze
          when Array then value.map { |item| immutable_effect(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
      end
    end
  end
end
