# frozen_string_literal: true

module Ace
  module Tmux
    module Atoms
      # Normalizes ACE-managed tmux window names to avoid target parsing ambiguity.
      module WindowNameSanitizer
        module_function

        def call(value, fallback: "window")
          sanitized = sanitize(value)
          sanitized.empty? ? sanitize(fallback).then { |name| name.empty? ? "window" : name } : sanitized
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
