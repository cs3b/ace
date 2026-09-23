# frozen_string_literal: true

module Ace
  module Hitl
    module Hermes
      module Atoms
        # Token validation for every value that becomes part of a file
        # name or an address (spec 8wm.t.vs1 §2): ids, senders, channel
        # names, machine names. Path-traversal safe: no separators, no
        # leading dot, bounded length.
        module HermesTokens
          PATTERN = /\A[A-Za-z0-9][A-Za-z0-9._:-]{0,63}\z/.freeze

          module_function

          def valid?(value)
            value.is_a?(String) && value.match?(PATTERN)
          end

          # Fail closed: raises ContractError naming the label and the rule.
          def validate!(value, label)
            token = value.is_a?(String) ? value.strip : value
            return token if valid?(token)

            raise ContractError,
              "hermes #{label} must match #{PATTERN.inspect} " \
              "(1..64 chars; letters, digits, '.', '_', ':', '-'; " \
              "no leading dot; got #{value.inspect})"
          end
        end
      end
    end
  end
end
