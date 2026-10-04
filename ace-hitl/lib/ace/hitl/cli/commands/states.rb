# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # Host-broker listing of all public lifecycle projections.
        class States < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "List public HITL lifecycle projections (transport operation)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            emit(lifecycle_client.states)
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
