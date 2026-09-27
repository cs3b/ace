# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # Requester-side answer consumption. A positive timeout bounds
        # ONLY the local wait and never cancels the request (W651);
        # without it the wait is indefinite (spec 8wm.t.y21 §3).
        class Consume < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "Wait for and consume the answer of one own HITL relay request"

          argument :id, required: true, desc: "HITL relay request id"

          option :timeout, type: :integer, desc: "Local wait bound in seconds; 0 (default) waits indefinitely"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(id:, **options)
            emit(lifecycle_store.consume(id, timeout: options[:timeout] || 0))
          rescue Lifecycle::Error => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
