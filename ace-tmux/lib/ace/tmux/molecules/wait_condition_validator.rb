# frozen_string_literal: true

module Ace
  module Tmux
    module Molecules
      module WaitConditionValidator
        module_function

        ALLOWED = %w[agent output window-exists window-active pane-exists pane-exited].freeze

        def validate!(condition:, pattern:)
          normalized = condition.to_s.strip
          raise Ace::Tmux::ValidationError, "--for is required" if normalized.empty?
          raise Ace::Tmux::ValidationError, "Unsupported wait condition: #{condition}" unless ALLOWED.include?(normalized)

          if normalized == "output" && pattern.to_s.strip.empty?
            raise Ace::Tmux::ValidationError, "--pattern is required when waiting for output"
          end

          normalized
        end
      end
    end
  end
end
