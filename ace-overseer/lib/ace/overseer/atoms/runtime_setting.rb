# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      # Normalizes the overseer `runtime:` config setting into a contract
      # runtime name. The shipped default is `auto`, which is an
      # overseer-level instruction to detect, never a contract runtime
      # name; it normalizes to nil so the selector falls through to
      # ACE_RUNTIME / detection.
      module RuntimeSetting
        module_function

        def normalize(value)
          normalized = value.to_s.strip
          normalized.empty? || normalized == "auto" ? nil : normalized
        end
      end
    end
  end
end
