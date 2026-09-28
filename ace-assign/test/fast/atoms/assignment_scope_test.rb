# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Assign
    class AssignmentScopeTest < AceAssignTestCase
      def test_canonicalize_strips_and_accepts_step_numbers
        assert_equal "010", Atoms::AssignmentScope.canonicalize(" 010 ")
        assert_equal "010.01", Atoms::AssignmentScope.canonicalize("010.01")
        assert_equal "010.01.02", Atoms::AssignmentScope.canonicalize("010.01.02")
      end

      def test_canonicalize_rejects_blank_and_malformed_scopes
        ["", "   ", "abc", "010.", ".01", "010..01", "01a"].each do |bad|
          error = assert_raises(Ace::Assign::AttemptErrors::InvalidScope) do
            Atoms::AssignmentScope.canonicalize(bad)
          end
          assert_equal 5, error.exit_code
        end
      end

      def test_ownership_key_is_filesystem_safe_and_scope_canonical
        key = Atoms::AssignmentScope.ownership_key("8wr1ab", "010")

        assert_equal "8wr1ab-010.json", key
        assert_equal Atoms::AssignmentScope.ownership_key("8wr1ab", "010"),
          Atoms::AssignmentScope.ownership_key("8wr1ab", " 010 ")
      end

      def test_equality_compares_canonical_forms
        assert Atoms::AssignmentScope.equal?("010", " 010 ")
        refute Atoms::AssignmentScope.equal?("010", "020")
        refute Atoms::AssignmentScope.equal?("010", "bogus")
      end
    end
  end
end
