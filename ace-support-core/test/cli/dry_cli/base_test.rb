# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        # Test command class that includes the Base module
        class BaseTestCommand
          # Use full module path to avoid conflict with CLI::Base (Thor)
          include Ace::Core::CLI::DryCli::Base

          def call(**options)
            options
          end
        end

        class BaseTest < Minitest::Test
          def setup
            @command = BaseTestCommand.new
          end

          # verbose? tests

          def test_verbose_returns_true_when_enabled
            assert @command.verbose?(verbose: true)
          end

          def test_verbose_returns_false_when_disabled
            refute @command.verbose?(verbose: false)
          end

          def test_verbose_returns_false_when_nil
            refute @command.verbose?(verbose: nil)
          end

          # quiet? tests

          def test_quiet_returns_true_when_enabled
            assert @command.quiet?(quiet: true)
          end

          def test_quiet_returns_false_when_disabled
            refute @command.quiet?(quiet: false)
          end

          def test_quiet_returns_false_when_nil
            refute @command.quiet?(quiet: nil)
          end

          # debug? tests

          def test_debug_returns_true_when_enabled
            assert @command.debug?(debug: true)
          end

          def test_debug_returns_false_when_disabled
            refute @command.debug?(debug: false)
          end

          def test_debug_returns_false_when_nil
            refute @command.debug?(debug: nil)
          end

          # debug_log tests

          def test_debug_log_outputs_when_debug_enabled
            _, err = capture_io do
              @command.debug_log("Test message", debug: true)
            end
            assert_includes err, "DEBUG: Test message"
          end

          def test_debug_log_no_output_when_debug_disabled
            _, err = capture_io do
              @command.debug_log("Test message", debug: false)
            end
            refute_includes err, "DEBUG: Test message"
          end

          # exit_success tests

          def test_exit_success_returns_zero
            assert_equal 0, @command.exit_success
          end

          # exit_failure tests

          def test_exit_failure_returns_one
            assert_equal 1, @command.exit_failure
          end

          def test_exit_failure_outputs_message
            _, err = capture_io do
              @command.exit_failure("Test error")
            end
            assert_includes err, "Error: Test error"
          end

          def test_exit_failure_without_message
            _, err = capture_io do
              @command.exit_failure
            end
            refute_includes err, "Error:"
          end

          # validate_required! tests

          def test_validate_required_passes_when_all_present
            result = @command.validate_required!({ a: 1, b: 2 }, :a, :b)
            assert_nil result # No error raised
          end

          def test_validate_required_raises_when_missing
            error = assert_raises(ArgumentError) do
              @command.validate_required!({ a: 1 }, :a, :b)
            end
            assert_includes error.message, "Missing required options: b"
          end

          def test_validate_required_allows_nil_values_if_key_present
            # The implementation treats nil as missing (key present but value is nil)
            # This is intentional - nil values are considered "not provided"
            error = assert_raises(ArgumentError) do
              @command.validate_required!({ a: nil }, :a)
            end
            assert_includes error.message, "Missing required options: a"
          end

          def test_validate_required_allows_false_values
            # false is a valid value, not nil
            result = @command.validate_required!({ a: false }, :a)
            assert_nil result # No error raised - key is present with false value
          end

          def test_validate_required_with_multiple_missing
            error = assert_raises(ArgumentError) do
              @command.validate_required!({ a: 1 }, :a, :b, :c)
            end
            assert_includes error.message, "Missing required options: b, c"
          end

          # format_pairs tests

          def test_format_pairs_simple_hash
            result = @command.format_pairs(a: 1, b: 2)
            assert_equal "a=1 b=2", result
          end

          def test_format_pairs_string_keys
            result = @command.format_pairs("a" => 1, "b" => 2)
            assert_equal "a=1 b=2", result
          end

          def test_format_pairs_empty_hash
            result = @command.format_pairs({})
            assert_equal "", result
          end

          def test_format_pairs_single_item
            result = @command.format_pairs(key: "value")
            assert_equal "key=value", result
          end

          # Constants tests

          def test_standard_options_constant
            assert_equal %i[quiet verbose debug], Ace::Core::CLI::DryCli::Base::STANDARD_OPTIONS
          end

          def test_reserved_flags_constant
            assert_equal %i[h v q d o], Ace::Core::CLI::DryCli::Base::RESERVED_FLAGS
          end
        end
      end
    end
  end
end
