# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Atoms
        class HermesTokensTest < AceHermesTestCase
          def test_accepts_contract_shaped_tokens
            ["a", "Z9", "inbox-1", "lab01.node:x_y", ("k" * 64)].each do |token|
              assert HermesTokens.valid?(token), "expected #{token} to be valid"
            end
          end

          def test_rejects_traversal_dots_empties_and_oversize
            ["", "  ", ".hidden", "-lead", "_lead", ":lead", "a/b", "../x",
              "a b", "x\ny", ("k" * 65), nil, 42, :sym].each do |token|
              refute HermesTokens.valid?(token), "expected #{token.inspect} to be invalid"
            end
          end

          def test_validate_strips_and_returns_token
            assert_equal "inbox-1", HermesTokens.validate!(" inbox-1 ", "channel name")
          end

          def test_validate_fails_closed_naming_label_and_rule
            error = assert_raises(ContractError) do
              HermesTokens.validate!("../etc", "message id")
            end
            assert_match(/hermes message id/, error.message)
            assert_match(/no leading dot/, error.message)
          end
        end
      end
    end
  end
end
