# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # Host-broker drain view of the Overseer response outbox.
        class OverseerPending < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "List queued Overseer responses (host-broker operation)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            emit(overseer.pending)
          rescue Lifecycle::Error => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
