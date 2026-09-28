# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Runtime
    module CLI
      module Commands
        # The neutral callback passthrough (Fork Callback Rule). Resolves
        # the configured runtime and delegates to runtime.send with the
        # normative send-matrix semantics: ordered delivery on plain
        # panes, single self-submitting prompt shapes on agent panes.
        # Rejected input fails before any transport call.
        class Send < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Send a submitted command, text chunks, or named keys to a pane via the resolved terminal runtime

            Runtime resolution: --runtime > ACE_RUNTIME > configured runtime > auto-detection
            (tmux wins when both environments are live). Rejected sends make no transport call.
          DESC

          example [
            "--pane %1 --cmd 'bundle exec rake test'",
            "--pane %1 --msg 'Reply with exactly: pong' --key Enter",
            "--runtime herdr --pane w1:p1 --msg 'hello'",
            "--pane %1 --key C-c"
          ]

          option :runtime, type: :string, desc: "Terminal runtime name (tmux, herdr); overrides ACE_RUNTIME, config, and detection"
          option :pane, type: :string, required: true, desc: "Target pane handle as exposed by the runtime (opaque, adapter-owned)"
          option :cmd, type: :string, aliases: %w[-c], desc: "Command text to submit once (declare before any --key)"
          option :msg, type: :string, aliases: %w[-m], repeat: true, desc: "Literal text chunk to deliver without implicit submission"
          option :key, type: :string, aliases: %w[-k], repeat: true, desc: "Named key to deliver (for example Enter, C-c)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(**options)
            command, items = build_request(options)
            selector = Molecules::RuntimeSelector.new(config: Ace::Runtime.config)
            runtime = selector.resolve(explicit: options[:runtime])
            result = runtime.send(pane: options[:pane], command: command, items: items)

            report(selector.selected_name, command, items, result) unless quiet?(options)
          rescue Ace::Runtime::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          # The callback CLI builds direct-API items as all supplied
          # messages followed by all supplied keys; direct Ruby callers
          # use send(items:) when they need arbitrary interleaving.
          def build_request(options)
            reject_leading_keys!

            command = normalize_cmd(options[:cmd])
            items = Array(options[:msg]).map { |text| {message: text} } +
              Array(options[:key]).map { |name| {key: name} }

            if command.nil? && items.empty?
              raise Ace::Support::Cli::Error, "provide at least one of --cmd, --msg, or --key"
            end

            [command, items]
          end

          # Leading keys (--key Esc --cmd run) are a normative usage
          # error: --cmd must be declared before every key.
          def reject_leading_keys!
            cmd_index = first_flag_index(%w[--cmd -c])
            key_indices = flag_indices(%w[--key -k])
            return if cmd_index.nil? || key_indices.empty? || key_indices.min > cmd_index

            raise Ace::Support::Cli::Error,
              "--key before --cmd is a usage error: --cmd must be declared before every key"
          end

          def flag_indices(flags)
            ARGV.each_index.select do |index|
              token = ARGV[index]
              flags.any? { |flag| token == flag || token.start_with?("#{flag}=") }
            end
          end

          def first_flag_index(flags)
            list = flag_indices(flags)
            list.empty? ? nil : list.min
          end

          def normalize_cmd(value)
            text = value.to_s
            return nil if text.strip.empty?

            text
          end

          def report(runtime_name, command, items, result)
            parts = []
            parts << "command" if command
            message_count = items.count { |item| item.key?(:message) }
            key_count = items.count { |item| item.key?(:key) }
            parts << pluralize(message_count, "message") if message_count.positive?
            parts << pluralize(key_count, "key") if key_count.positive?

            line = "Sent via #{runtime_name}: #{parts.join(' + ')}"
            line += " (dropped trailing Enter for agent pane)" if result&.dropped_trailing_enter

            puts line
          end

          def pluralize(count, noun)
            "#{count} #{noun}#{count == 1 ? '' : 's'}"
          end
        end
      end
    end
  end
end
