# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # The standing-duty projection: pending + escalated (spec
        # 8wm.t.y21 §7).
        class Duty < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "Project pending and escalated HITL requests (host-broker operation)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            emit(Lifecycle::Duty.project(pending: lifecycle_client.pending, states: lifecycle_client.states))
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
