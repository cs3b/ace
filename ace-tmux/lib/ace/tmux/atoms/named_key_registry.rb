# frozen_string_literal: true

module Ace
  module Tmux
    module Atoms
      module NamedKeyRegistry
        module_function

        KEYS = {
          "enter" => "Enter",
          "tab" => "Tab",
          "space" => "Space",
          "escape" => "Escape",
          "esc" => "Escape",
          "up" => "Up",
          "down" => "Down",
          "left" => "Left",
          "right" => "Right",
          "c-c" => "C-c"
        }.freeze

        def normalize(key)
          value = key.to_s.strip
          raise Ace::Tmux::ValidationError, "Named key is required" if value.empty?

          normalized = KEYS[value.downcase]
          raise Ace::Tmux::ValidationError, "Unsupported named key: #{key}" unless normalized

          normalized
        end
      end
    end
  end
end
