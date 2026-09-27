# frozen_string_literal: true

module Ace
  module Hitl
    module Hermes
      # Error model for the folder-as-interface plugin (spec 8wm.t.vs1 §9).
      class Error < StandardError; end

      # The shared folder or a configuration value violates the folder
      # contract (missing folder, non-directory, world-writable folder,
      # invalid channel/token values).
      class ContractError < Error; end

      # The plugin was invoked as root; writing without root is a pinned
      # contract property and is refused fail closed.
      class RootUserError < Error; end

      # The target message file already exists; publish retries with a
      # fresh id (bounded) instead of overwriting.
      class CollisionError < Error; end

      # The message declares a schema version this plugin does not support
      # (only ace.hitl.hermes.message/v1); fail closed, quarantine upstream.
      class UnknownFormatError < Error; end

      # The message envelope violates schema ace.hitl.hermes.message/v1
      # (bad filename/id pairing, missing or extra fields, bad sender,
      # bad timestamp, empty body, wrong encoding or size).
      class InvalidMessageError < Error; end

      # The channel name is not in the registry.
      class UnknownChannelError < Error; end
    end
  end
end
