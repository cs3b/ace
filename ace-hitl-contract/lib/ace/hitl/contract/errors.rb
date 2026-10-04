# frozen_string_literal: true

module Ace
  module Hitl
    module Providers
      # Error model for HITL provider adapters (spec 8wm.t.vrz §2).
      class Error < StandardError; end

      # The provider name is not in the registry.
      class UnknownProviderError < Error; end

      # The reverse address (herdr session + pane) is absent or invalid.
      # Ask fails closed before any event or transport state is created.
      class InvalidRefError < Error; end

      # The transport send failed (binary missing, non-zero exit,
      # unparseable output) after the local event may already exist.
      class ProviderUnavailableError < Error; end

      # The provider does not implement the requested operation.
      class UnsupportedOperationError < Error; end
    end
  end
end
