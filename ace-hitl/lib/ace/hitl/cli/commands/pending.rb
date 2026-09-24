# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # Host-broker listing of answerable relay requests; never purges
        # or cancels anything (W651).
        class Pending < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "List answerable HITL relay requests (host-broker operation)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            emit(lifecycle_store.pending)
          rescue Lifecycle::Error => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
