# frozen_string_literal: true

module Ace
  module Runtime
    module Atoms
      # Pure environment detection. Reads the provided env only: no
      # adapter loads, no transport calls, no other side effects.
      # tmux wins when both environments are live (existing default,
      # documented in README).
      module Detector
        module_function

        def detect(env: ENV)
          return :tmux if tmux_live?(env)
          return :herdr if herdr_live?(env)

          nil
        end

        def tmux_live?(env)
          nonblank?(env["TMUX"]) || nonblank?(env["ACE_TMUX_SESSION"])
        end

        def herdr_live?(env)
          nonblank?(env["HERDR_SESSION"]) && nonblank?(env["HERDR_PANE"])
        end

        def nonblank?(value)
          !value.to_s.strip.empty?
        end
      end
    end
  end
end
