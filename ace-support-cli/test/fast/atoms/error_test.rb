# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Support
    module Cli
      class ErrorTest < Minitest::Test
        def test_inherits_from_standard_error
          error = Error.new("test")
          assert_kind_of StandardError, error
        end

        def test_stores_message
          error = Error.new("something went wrong")
          assert_equal "something went wrong", error.message
        end

        def test_default_exit_code_is_one
          error = Error.new("test")
          assert_equal 1, error.exit_code
        end

        def test_custom_exit_code
          error = Error.new("test", exit_code: 2)
          assert_equal 2, error.exit_code
        end

        def test_can_be_raised_and_rescued
          raised = assert_raises(Error) do
            raise Error.new("boom")
          end
          assert_equal "boom", raised.message
          assert_equal 1, raised.exit_code
        end

        def test_can_be_rescued_as_standard_error
          assert_raises(StandardError) do
            raise Error.new("boom")
          end
        end

        def test_to_s_prepends_error_prefix
          error = Error.new("something went wrong")
          assert_equal "Error: something went wrong", error.to_s
        end

        def test_message_remains_unchanged
          error = Error.new("test")
          assert_equal "test", error.message
        end
      end
    end
  end
end
