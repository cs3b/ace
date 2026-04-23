# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        class Send < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          DEFAULT_CAPTURE_LINES = 40
          DEFAULT_CAPTURE_WAIT = 2.0

          desc <<~DESC.strip
            Send submitted commands, raw text, or named keys to a tmux pane

            Bare --wait defaults to the interactive agent condition.
            Bare --capture prints a post-send pane tail using default line and wait values.
          DESC

          example [
            "--pane %1 --cmd 'bundle exec rake test'",
            "--pane %8 --cmd 'Reply with exactly: pong' --wait --capture 20",
            "--pane %1 --msg 'echo ready' --key Enter",
            "--pane %1 --cmd 'echo done' --wait output --pattern done --capture 20"
          ]

          option :session, type: :string, aliases: %w[-s], desc: "Target session name"
          option :window, type: :string, aliases: %w[-w], desc: "Target window name, index, or tmux window id (@2)"
          option :pane, type: :string, aliases: %w[-p], desc: "Target pane id (%8), full pane target (dev:work.1), or current-window pane shorthand (.1)"
          option :cmd, type: :string, aliases: %w[-c], desc: "Command text to send and submit with Enter"
          option :msg, type: :string, aliases: %w[-m], repeat: true, desc: "Literal text chunk to send without Enter"
          option :key, type: :string, aliases: %w[-k], repeat: true, desc: "Named key to send (for example Enter, C-c)"
          option :capture, type: :string, default: false, optional_value: true, desc: "Capture pane output after send as [lines[:wait]]; bare --capture defaults to 40 lines"
          option :wait, type: :string, default: false, optional_value: true, desc: "Wait after send as [agent|output|window-exists|window-active|pane-exists|pane-exited]; bare --wait defaults to agent"
          option :pattern, type: :string, desc: "Pattern to match when waiting for output"
          option :timeout, type: :string, aliases: %w[-t], default: Organisms::ControlSurface::DEFAULT_TIMEOUT.to_s, desc: "Wait timeout in seconds when --wait is used"
          option :interval, type: :string, aliases: %w[-i], default: Organisms::ControlSurface::DEFAULT_INTERVAL.to_s, desc: "Wait polling interval in seconds when --wait is used"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            control = Organisms::ControlSurface.new
            cmd = normalized_cmd(options)
            messages = normalized_messages(options)
            keys = normalized_keys(options)
            wait_condition = normalized_wait_condition(options.fetch(:wait, false))

            validate_payloads!(cmd: cmd, messages: messages, keys: keys)
            validate_wait_condition!(wait_condition: wait_condition, pattern: options[:pattern]) if wait_condition

            capture_spec = parse_capture_spec(
              options.fetch(:capture, false),
              default_wait: wait_condition ? 0.0 : DEFAULT_CAPTURE_WAIT
            )
            wait_lines = capture_spec ? capture_spec[:lines] : DEFAULT_CAPTURE_LINES
            baseline_output = wait_baseline_for(control, options, wait_condition, lines: wait_lines)

            control.send_sequence(**target_options(options), command: cmd, messages: messages, keys: keys)

            if wait_condition
              control.wait_for_condition(
                **target_options(options),
                condition: wait_condition,
                pattern: options[:pattern],
                timeout: Float(options.fetch(:timeout, Organisms::ControlSurface::DEFAULT_TIMEOUT.to_s)),
                interval: Float(options.fetch(:interval, Organisms::ControlSurface::DEFAULT_INTERVAL.to_s)),
                lines: wait_lines,
                baseline_output: baseline_output,
                require_change: wait_condition == "agent"
              )
            end

            if capture_spec
              sleep(capture_spec[:wait]) if capture_spec[:wait].positive?
              output = control.capture_recent_output(**target_options(options), lines: capture_spec[:lines])
              puts output
            elsif !options[:quiet]
              puts success_message(cmd: cmd, messages: messages, keys: keys, wait_condition: wait_condition)
            end
          rescue Ace::Tmux::Error => e
            raise Ace::Support::Cli::Error, e.message
          rescue ArgumentError
            raise Ace::Support::Cli::Error, "--timeout and --interval must be numeric"
          end

          private

          def target_options(options)
            options.slice(:session, :window, :pane)
          end

          def normalized_cmd(options)
            value = options[:cmd].to_s
            return nil if value.strip.empty?

            value
          end

          def normalized_messages(options)
            Array(options[:msg]).map(&:to_s)
          end

          def normalized_keys(options)
            Array(options[:key]).map(&:to_s).reject { |value| value.strip.empty? }
          end

          def validate_payloads!(cmd:, messages:, keys:)
            raise Ace::Support::Cli::Error, "Provide at least one of --cmd, --msg, or --key" if cmd.nil? && messages.empty? && keys.empty?
            raise Ace::Support::Cli::Error, "Use either --cmd or --msg, not both" if cmd && !messages.empty?
          end

          def parse_capture_spec(raw, default_wait: DEFAULT_CAPTURE_WAIT)
            return nil if raw == false
            return { lines: DEFAULT_CAPTURE_LINES, wait: default_wait } if raw.nil? || raw == true || raw.to_s.strip.empty?

            value = raw.to_s.strip
            parts = value.split(":", 2)

            lines = Integer(parts[0])
            wait = parts[1] ? Float(parts[1]) : default_wait
            raise ArgumentError if lines <= 0 || wait.negative?

            { lines: lines, wait: wait }
          rescue ArgumentError
            raise Ace::Support::Cli::Error, "Invalid --capture value '#{raw}'. Use [lines[:wait]] such as 40 or 40:2"
          end

          def normalized_wait_condition(raw)
            return nil if raw == false
            return "agent" if raw.nil? || raw == true || raw.to_s.strip.empty?

            raw.to_s.strip
          end

          def validate_wait_condition!(wait_condition:, pattern:)
            Molecules::WaitConditionValidator.validate!(condition: wait_condition, pattern: pattern)
          rescue Ace::Tmux::ValidationError => e
            raise Ace::Support::Cli::Error, e.message
          end

          def wait_baseline_for(control, options, wait_condition, lines:)
            return nil unless %w[agent output].include?(wait_condition)

            control.capture_recent_output(**target_options(options), lines: lines)
          end

          def success_message(cmd:, messages:, keys:, wait_condition:)
            message =
              if cmd
                "Sent command"
              elsif !messages.empty? && !keys.empty?
                "Sent #{messages.length} message#{messages.length == 1 ? '' : 's'} and #{keys.length} key#{keys.length == 1 ? '' : 's'}"
              elsif !messages.empty?
                "Sent #{messages.length} message#{messages.length == 1 ? '' : 's'}"
              else
                "Sent #{keys.length} key#{keys.length == 1 ? '' : 's'}"
              end

            return message unless wait_condition

            "#{message} and waited for #{wait_condition}"
          end
        end
      end
    end
  end
end
