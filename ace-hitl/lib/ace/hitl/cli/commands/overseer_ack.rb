# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # Host-broker acknowledgement of one relayed Overseer response.
        class OverseerAck < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "Acknowledge (remove) one relayed Overseer response"

          argument :id, required: true, desc: "Overseer response message id"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(id:, **options)
            emit(overseer.ack(id))
          rescue Lifecycle::Error => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
