# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        class Detach < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Detach clients from a tmux session"

          option :session, type: :string, aliases: %w[-s], desc: "Target session name"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            session = Organisms::ControlSurface.new.detach_session(session: options[:session])
            puts "Detached session #{session}" unless options[:quiet]
          rescue Ace::Tmux::Error => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
