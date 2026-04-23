# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        class Capture < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Capture recent output from a tmux pane

            Interactive CLI panes capture the visible bottom of the current screen.
            Generic shell panes capture a recent history tail.
          DESC

          example [
            "--pane %1",
            "--pane %8 --lines 20",
            "--session dev --window work --pane .1 --lines 10"
          ]

          option :session, type: :string, aliases: %w[-s], desc: "Target session name"
          option :window, type: :string, aliases: %w[-w], desc: "Target window name, index, or tmux window id (@2)"
          option :pane, type: :string, aliases: %w[-p], desc: "Target pane id (%8), full pane target (dev:work.1), or current-window pane shorthand (.1)"
          option :lines, type: :integer, aliases: %w[-n], default: 40, desc: "Number of recent lines to capture"

          def call(**options)
            output = Organisms::ControlSurface.new.capture_recent_output(**options.slice(:session, :window, :pane, :lines))
            puts output
          rescue Ace::Tmux::Error => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
