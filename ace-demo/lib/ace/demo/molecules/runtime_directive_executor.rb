# frozen_string_literal: true

require "ace/runtime"
require "ace/tmux"
require "shellwords"

module Ace
  module Demo
    module Molecules
      # Executes demo terminal directives through the runtime contract.
      # wait/send resolve via the selected runtime adapter; attach/detach
      # stay tmux-local human-facing operations (k86.0 validation default).
      # The YAML envelope key remains "tmux" for tape compatibility of the
      # directive shape itself; wait/send never touch tmux APIs directly.
      class RuntimeDirectiveExecutor
        LIFECYCLE_CONDITIONS = Ace::Runtime::Atoms::SendContract::LIFECYCLE_CONDITIONS
        WINDOW_CONDITIONS = %w[window-exists window-active].freeze
        DEFAULT_TIMEOUT = 10.0

        def initialize(runtime: nil, env: ENV, tmux_executor: nil)
          @runtime_override = runtime
          @env = env || ENV
          @tmux_executor = tmux_executor
        end

        def execute(command, env = nil)
          directive_env = env || @env
          directive = command.fetch("tmux")
          action = directive.fetch("action")

          case action
          when "attach"
            ensure_tmux_local!(directive, directive_env, action)
            session = directive.fetch("session")
            {shell_command: [tmux_binary, "attach-session", "-t", session].map { |part| Shellwords.escape(part) }.join(" ")}
          when "detach"
            ensure_tmux_local!(directive, directive_env, action)
            session = directive.fetch("session")
            tmux_executor.run([tmux_binary, "detach-client", "-s", session])
            nil
          when "wait"
            wait_directive(directive, directive_env)
            nil
          when "send"
            send_directive(directive, directive_env)
            nil
          else
            raise ArgumentError, "Unsupported tmux action '#{action}'"
          end
        rescue KeyError => e
          raise ArgumentError, "Invalid tmux directive: missing #{e.key}"
        rescue Ace::Runtime::Error => e
          raise Ace::Demo::Error, e.message
        end

        private

        private

        attr_reader :env, :runtime_override

        # The adapter resolves per execute() call: the per-directive
        # `runtime:` key and the caller environment are selection inputs,
        # so a memoized adapter could route a later directive to the
        # wrong runtime.
        def adapter(directive, directive_env)
          Ace::Runtime::Molecules::RuntimeSelector.new(
            config: Ace::Runtime.config,
            env: directive_env
          ).resolve(explicit: directive_runtime(directive))
        end

        def wait_directive(directive, directive_env)
          condition = directive.fetch("for")
          unless LIFECYCLE_CONDITIONS.include?(condition)
            raise ArgumentError, "wait condition must be one of: #{LIFECYCLE_CONDITIONS.join(', ')}"
          end

          target = if WINDOW_CONDITIONS.include?(condition)
            required_target(directive, "window")
          else
            required_target(directive, "pane")
          end
          adapter(directive, directive_env).wait_lifecycle(
            condition: condition,
            target: target,
            timeout: directive.fetch("timeout", DEFAULT_TIMEOUT)
          )
        end

        def send_directive(directive, directive_env)
          pane = required_target(directive, "pane")
          runtime_adapter = adapter(directive, directive_env)
          if directive["command"]
            runtime_adapter.send_command(pane: pane, command: directive["command"])
          else
            runtime_adapter.send_keys(pane: pane, keys: [directive.fetch("key")])
          end
        end

        def required_target(directive, kind)
          target = directive[kind].to_s.strip
          raise ArgumentError, "Invalid tmux directive: missing #{kind}" if target.empty?

          target
        end

        # Selection precedence mirrors the contract selector: per-directive
        # runtime > executor runtime > ACE_RUNTIME > configured runtime >
        # detection. The name form is needed separately for the tmux-local
        # guard, which must not resolve an adapter at all.
        def selected_runtime_name(directive, directive_env)
          directive_runtime(directive) ||
            directive_env["ACE_RUNTIME"] ||
            Ace::Runtime.config["runtime"] ||
            Ace::Runtime.detect(env: directive_env)&.to_s ||
            ""
        end

        def directive_runtime(directive)
          explicit = (directive["runtime"] || runtime_override).to_s.strip
          explicit.empty? ? nil : explicit
        end

        def ensure_tmux_local!(directive, directive_env, action)
          selected = selected_runtime_name(directive, directive_env)
          return if selected.empty? || selected == "tmux"

          raise Ace::Demo::Error, "#{action} is tmux-local and unsupported under the '#{selected}' runtime"
        end

        def tmux_executor
          @tmux_executor_instance ||= @tmux_executor || Ace::Tmux::Molecules::TmuxExecutor.new
        end

        def tmux_binary
          "tmux"
        end
      end
    end
  end
end
