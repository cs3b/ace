# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Core
    module CLI
      class StandardOptionsTest < Minitest::Test
        def test_option_description_constants
          assert_equal "Suppress non-essential output", StandardOptions::QUIET_DESC
          assert_equal "Show verbose output", StandardOptions::VERBOSE_DESC
          assert_equal "Show debug output", StandardOptions::DEBUG_DESC
          assert_equal "Show this help", StandardOptions::HELP_DESC
        end
      end
    end
  end
end
