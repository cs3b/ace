# frozen_string_literal: true

require_relative "hermes/version"
require_relative "hermes/errors"
require_relative "hermes/atoms/hermes_tokens"
require_relative "hermes/molecules/hermes_contract"
require_relative "hermes/molecules/hermes_formats"
require_relative "hermes/molecules/hermes_message"
require_relative "hermes/molecules/hermes_atomic_writer"
require_relative "hermes/molecules/hermes_quarantine"
require_relative "hermes/molecules/hermes_retry_policy"
require_relative "hermes/molecules/hermes_notifications"
require_relative "hermes/molecules/hermes_channels"
require_relative "hermes/organisms/hermes_box"

module Ace
  module Hitl
    # Folder-as-interface HITL transport plugin (spec 8wm.t.vs1): the
    # shared folder between lab and hermes IS the transport. A message is
    # a file, the address is <machine>/<folder>/<id>, delivery is push,
    # and ACK is the deletion of the file after delivery. The plugin owns
    # the channel registry, the notification texts, and the message
    # formats (ace.hitl.hermes.message/v1).
    module Hermes
    end
  end
end
