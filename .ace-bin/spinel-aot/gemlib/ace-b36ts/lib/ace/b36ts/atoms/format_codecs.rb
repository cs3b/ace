# frozen_string_literal: true

# Codec methods moved inline into CompactIdEncoder's singleton class:
# Spinel neither models `class << self; include Module` at run time nor
# keeps argument types across constant-receiver dispatch, so cross-module
# mixin calls broke. Bare same-class calls stay static. This module shell
# remains only as a load-time stub (b36ts.rb requires it).
module Ace
  module B36ts
    module Atoms
      module FormatCodecs
      end
    end
  end
end
