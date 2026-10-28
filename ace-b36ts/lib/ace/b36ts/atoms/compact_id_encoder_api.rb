# frozen_string_literal: true

# CRuby-only convenience surface for CompactIdEncoder.
#
# EXCLUDED from Spinel-compiled builds (build.sh strips this file and its
# require): the wrapper has no compiled callers, so its generic param
# poisons the compiler's Time-typed call chain with slot mismatches.

module Ace
  module B36ts
    module Atoms
      class CompactIdEncoder
        class << self
          def encode(time, year_zero: DEFAULT_YEAR_ZERO, alphabet: DEFAULT_ALPHABET)
            encode_with_format(time, format: :"2sec", year_zero: year_zero, alphabet: alphabet)
          end
        end
      end
    end
  end
end
