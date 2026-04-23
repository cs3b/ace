# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        class Attach < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Attach to a tmux session using shared target resolution"

          option :session, type: :string, aliases: %w[-s], desc: "Target session name"

          def call(**options)
            Organisms::ControlSurface.new.attach_session(session: options[:session])
          rescue Ace::Tmux::Error => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
