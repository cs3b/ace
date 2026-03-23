# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Simple ANSI color helpers for terminal output.
        # Automatically skips color codes when stdout is not a TTY.
        module AnsiColors
          RED = "\e[31m"
          GREEN = "\e[32m"
          YELLOW = "\e[33m"
          CYAN = "\e[36m"
          DIM = "\e[2m"
          BOLD = "\e[1m"
          RESET = "\e[0m"

          # Wrap text in ANSI color codes.
          # Returns plain text when stdout is not a TTY.
          # @param text [String] Text to colorize
          # @param color_code [String] ANSI escape code (e.g. AnsiColors::GREEN)
          # @return [String]
          def self.colorize(text, color_code)
            return text unless tty?

            "#{color_code}#{text}#{RESET}"
          end

          # @return [Boolean] Whether stdout is a TTY
          def self.tty?
            $stdout.tty?
          end
        end
      end
    end
  end
end
