# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"

module Ace
  module Hitl
    module CLI
      module Commands
        # The Root Overseer's bounded, type-tagged response through the
        # reverse address (spec 8wm.t.y21 §6). The response is read from
        # stdin.
        class OverseerSend < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand

          desc "Queue a bounded, type-tagged Overseer response (stdin)"

          option :"reply-to", type: :string, desc: "Source message id this response answers"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            emit(overseer.send_response(
              reply_to: options[:"reply-to"] || "",
              reader: LifecycleCommand::STDIN_READER
            ))
          rescue Lifecycle::Error => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
