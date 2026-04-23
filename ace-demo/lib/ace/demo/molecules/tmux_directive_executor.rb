# frozen_string_literal: true

require "shellwords"

module Ace
  module Demo
    module Molecules
      class TmuxDirectiveExecutor
        def initialize(control_surface: nil, executor: nil, tmux: "tmux")
          @control_surface = control_surface
          @executor = executor || Ace::Tmux::Molecules::TmuxExecutor.new
          @tmux = tmux
        end

        def execute(command, env = nil)
          directive = command.fetch("tmux")
          action = directive.fetch("action")
          surface = control_surface_for(env: env)

          case action
          when "attach"
            session = directive.fetch("session")
            {shell_command: [tmux, "attach-session", "-t", session].map { |part| Shellwords.escape(part) }.join(" ")}
          when "detach"
            surface.detach_session(session: directive["session"])
            nil
          when "wait"
            surface.wait_for_condition(
              condition: directive.fetch("for"),
              session: directive["session"],
              window: directive["window"],
              pane: directive["pane"],
              pattern: directive["pattern"],
              timeout: directive.fetch("timeout", Ace::Tmux::Organisms::ControlSurface::DEFAULT_TIMEOUT)
            )
            nil
          when "send"
            if directive["command"]
              surface.send_command(
                session: directive["session"],
                window: directive["window"],
                pane: directive["pane"],
                command: directive["command"]
              )
            else
              surface.send_key(
                session: directive["session"],
                window: directive["window"],
                pane: directive["pane"],
                key: directive.fetch("key")
              )
            end
            nil
          else
            raise ArgumentError, "Unsupported tmux action '#{action}'"
          end
        rescue KeyError => e
          raise ArgumentError, "Invalid tmux directive: missing #{e.key}"
        rescue Ace::Tmux::Error => e
          raise Ace::Demo::Error, e.message
        end

        private

        attr_reader :control_surface, :executor, :tmux

        def control_surface_for(env:)
          return control_surface if control_surface

          resolver = Ace::Tmux::Molecules::RuntimeTargetResolver.new(
            executor: executor,
            tmux: tmux,
            env: env || ENV
          )
          Ace::Tmux::Organisms::ControlSurface.new(executor: executor, resolver: resolver, tmux: tmux)
        end
      end
    end
  end
end
