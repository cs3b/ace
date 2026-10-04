# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # Operator/broker answering of one relay request (the "respond"
        # surface). The answer is read from stdin; the effect callback,
        # if declared, executes after the relay (spec 8wm.t.y21 §3, §5).
        class Deliver < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "Deliver an answer (stdin) to a pending HITL relay request"

          argument :id, required: true, desc: "HITL relay request id"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(id:, **options)
            answer = $stdin.read(Lifecycle::Store::MAX_ANSWER_BYTES + 1).to_s
            emit(lifecycle_client.deliver(id, answer))
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
