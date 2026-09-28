# frozen_string_literal: true

module Ace
  module Runtime
    module Atoms
      # Shared window/tab naming policy, extracted from the established
      # tmux sanitizer so every runtime normalizes identically. The
      # ensure_window identity is (current session/workspace, sanitized
      # name); deterministic sanitization is what makes the idempotent
      # by-name lookup stable.
      module NameSanitizer
        FALLBACK = "window"

        module_function

        def call(value, fallback: FALLBACK)
          sanitized = sanitize(value)
          return sanitized unless sanitized.empty?

          fallback_result = sanitize(fallback)
          fallback_result.empty? ? FALLBACK : fallback_result
        end

        def sanitize(value)
          value.to_s
            .gsub(/[^A-Za-z0-9_-]+/, "-")
            .gsub(/-+/, "-")
            .gsub(/\A-|-+\z/, "")
        end
        private_class_method :sanitize
      end
    end
  end
end
