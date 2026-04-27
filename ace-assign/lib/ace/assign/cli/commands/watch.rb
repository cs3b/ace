# frozen_string_literal: true

require_relative "watch_runtime"

module Ace
  module Assign
    module CLI
      module Commands
        # Inspect watcher scope state and report deterministic stop/failure boundaries.
        class Watch < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          DEFAULT_POLL_INTERVAL = 300

          desc "Watch assignment or subtree continuation state"

          option :assignment, desc: "Target specific assignment ID"
          option :root, desc: "Watch a specific fork subtree root (e.g., 010.01)"
          option :poll_interval, type: :integer, desc: "Polling interval in seconds"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(launcher: nil, sleeper: nil, pid_probe: nil, tmux_runner: nil)
            super()
            @launcher = launcher
            @sleeper = sleeper || ->(seconds) { sleep(seconds) }
            @pid_probe = pid_probe || method(:pid_alive?)
            @tmux_runner = tmux_runner || Molecules::TmuxControlSurfaceRunner.new
          end

          def call(**options)
            poll_interval = normalize_poll_interval(options[:poll_interval])
            target = resolve_assignment_target(options)
            runtime.call(
              target: target,
              explicit_root: options[:root],
              poll_interval: poll_interval,
              quiet: options[:quiet]
            )
          end

          private

          attr_reader :launcher, :sleeper, :pid_probe, :tmux_runner

          def normalize_poll_interval(raw)
            value = raw.nil? ? DEFAULT_POLL_INTERVAL : raw
            interval = Integer(value)
            raise Error, "Poll interval must be a positive integer." unless interval.positive?

            interval
          rescue ArgumentError, TypeError
            raise Error, "Poll interval must be a positive integer."
          end

          def pid_alive?(pid)
            Process.kill(0, pid.to_i)
            true
          rescue Errno::EPERM
            true
          rescue Errno::ESRCH, RangeError, TypeError
            false
          end

          def runtime
            @runtime ||= WatchRuntime.new(
              launcher: launcher,
              sleeper: sleeper,
              pid_probe: pid_probe,
              tmux_runner: tmux_runner
            )
          end
        end
      end
    end
  end
end
