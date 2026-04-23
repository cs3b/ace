# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        class Wait < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Wait for a bounded tmux condition

            Use --lines to control the pane tail observed by output and agent waits.
          DESC

          example [
            "--pane %1 --for output --pattern 'Task context:' --lines 80",
            "--pane %8 --for agent",
            "--session dev --for window-active --window work-fs",
            "--pane %1 --for pane-exited"
          ]

          option :for, type: :string, aliases: %w[-f], desc: "Condition: agent|output|window-exists|window-active|pane-exists|pane-exited"
          option :session, type: :string, aliases: %w[-s], desc: "Target session name"
          option :window, type: :string, aliases: %w[-w], desc: "Target window name, index, or tmux window id (@2)"
          option :pane, type: :string, aliases: %w[-p], desc: "Target pane id (%8), full pane target (dev:work.1), or current-window pane shorthand (.1)"
          option :pattern, type: :string, desc: "Pattern to match when waiting for output"
          option :lines, type: :integer, aliases: %w[-n], default: Organisms::ControlSurface::DEFAULT_LINES, desc: "Number of lines to observe for output and agent waits"
          option :timeout, type: :string, aliases: %w[-t], default: "10.0", desc: "Timeout in seconds"
          option :interval, type: :string, aliases: %w[-i], default: "0.2", desc: "Polling interval in seconds"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            Organisms::ControlSurface.new.wait_for_condition(
              condition: options[:for],
              session: options[:session],
              window: options[:window],
              pane: options[:pane],
              pattern: options[:pattern],
              lines: options[:lines],
              timeout: Float(options[:timeout]),
              interval: Float(options[:interval])
            )
            puts "Condition met: #{options[:for]}" unless options[:quiet]
          rescue Ace::Tmux::Error => e
            raise Ace::Support::Cli::Error, e.message
          rescue ArgumentError
            raise Ace::Support::Cli::Error, "--timeout and --interval must be numeric"
          end
        end
      end
    end
  end
end
