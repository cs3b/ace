# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Handbook
    class HandbookTest < TestCase
      def test_version_defined
        assert_kind_of String, Ace::Handbook::VERSION
        refute_empty Ace::Handbook::VERSION
      end
    end
  end
end
