# frozen_string_literal: true

require "base64"
require "securerandom"

module Ace
  module Assign
    module Molecules
      # The shared opaque-reference primitive for fixed-effect records
      # (spec 8x3.t.xz9.4). The reference is receiver-issued at admission and
      # names the canonical Assign record; clients may persist and echo it
      # but must never parse it or derive paths from it. Creation is random
      # (not derived from binding values), so a reference cannot be guessed
      # from public request fields, and resolution always goes through the
      # canonical record — there is no receiver-local mapping.
      class FixedEffectReference
        PREFIX = "fmr1"
        PATTERN = /\Afmr1-[A-Za-z0-9_-]{40,86}\z/
        MAX_LENGTH = 256

        def self.create
          "#{PREFIX}-#{Base64.urlsafe_encode64(SecureRandom.random_bytes(32), padding: false)}"
        end

        def self.valid?(value)
          value.is_a?(String) && value.length.between?(1, MAX_LENGTH) && value.match?(PATTERN)
        end
      end
    end
  end
end
