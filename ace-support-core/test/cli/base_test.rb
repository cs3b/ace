# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Core
    module CLI
      class BaseTestCommand
        include Ace::Core::CLI::Base

        def call(**options)
          options
        end
      end

      class BaseTest < Minitest::Test
        def setup
          @command = BaseTestCommand.new
        end

        def test_verbose_returns_true_when_enabled
          assert @command.verbose?(verbose: true)
        end

        def test_quiet_returns_true_when_enabled
          assert @command.quiet?(quiet: true)
        end

        def test_debug_returns_true_when_enabled
          assert @command.debug?(debug: true)
        end

        def test_help_returns_true_for_help_or_h
          assert @command.help?(help: true)
          assert @command.help?(h: true)
        end

        def test_debug_log_outputs_when_debug_enabled
          _, err = capture_io { @command.debug_log("Test message", debug: true) }
          assert_includes err, "DEBUG: Test message"
        end

        def test_raise_cli_error_raises_cli_error
          error = assert_raises(Ace::Core::CLI::Error) do
            @command.raise_cli_error("Test error", exit_code: 2)
          end
          assert_equal "Test error", error.message
          assert_equal 2, error.exit_code
        end

        def test_validate_required_raises_when_missing
          error = assert_raises(ArgumentError) do
            @command.validate_required!({ a: 1 }, :a, :b)
          end
          assert_includes error.message, "Missing required options: b"
        end

        def test_format_pairs
          assert_equal "a=1 b=2", @command.format_pairs(a: 1, b: 2)
        end

        def test_standard_options_constant
          assert_equal %i[quiet verbose debug], Ace::Core::CLI::Base::STANDARD_OPTIONS
        end

        def test_reserved_flags_constant
          assert_equal %i[h v q d o], Ace::Core::CLI::Base::RESERVED_FLAGS
        end

        def test_old_require_path_loads_compatibility_alias
          require "ace/core/cli/dry_cli/base"
          assert_equal Ace::Core::CLI::Base, Ace::Core::CLI::Base
        end
      end
    end
  end
end
