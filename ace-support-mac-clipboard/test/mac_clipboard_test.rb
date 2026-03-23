# frozen_string_literal: true

require "test_helper"

# Only run tests on macOS
if RUBY_PLATFORM.include?("darwin")
  class Ace::TestMacClipboard < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Ace::Support::MacClipboard::VERSION
    end

    def test_module_structure_exists
      # Should be able to access the module structure
      assert_kind_of Module, Ace::Support
      assert_kind_of Module, Ace::Support::MacClipboard
    end

    def test_error_class_exists
      # Should have an Error class
      assert_kind_of Class, Ace::Support::MacClipboard::Error
      assert Ace::Support::MacClipboard::Error.ancestors.include?(StandardError)
    end

    def test_required_components_load
      # Test that all required components can be loaded
      assert_respond_to Ace::Support::MacClipboard, :constants
    end

    def test_module_has_expected_structure
      # Should have the expected constants based on the require statements
      constants = Ace::Support::MacClipboard.constants

      # VERSION should be present
      assert_includes constants, :VERSION

      # Component classes should be present
      assert_includes constants, :ContentType, "ContentType class should be loaded"
      assert_includes constants, :Reader, "Reader class should be loaded"
      assert_includes constants, :ContentParser, "ContentParser class should be loaded"
    end
  end
end
