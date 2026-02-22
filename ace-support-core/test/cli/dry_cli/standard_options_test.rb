# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        class StandardOptionsTest < Minitest::Test
          def test_quiet_desc_constant
            assert_equal "Suppress non-essential output", StandardOptions::QUIET_DESC
          end

          def test_verbose_desc_constant
            assert_equal "Show verbose output", StandardOptions::VERBOSE_DESC
          end

          def test_debug_desc_constant
            assert_equal "Show debug output", StandardOptions::DEBUG_DESC
          end

          def test_help_desc_constant
            assert_equal "Show this help", StandardOptions::HELP_DESC
          end

          def test_constants_are_frozen_strings
            assert StandardOptions::QUIET_DESC.frozen?
            assert StandardOptions::VERBOSE_DESC.frozen?
            assert StandardOptions::DEBUG_DESC.frozen?
            assert StandardOptions::HELP_DESC.frozen?
          end
        end
      end
    end
  end
end
