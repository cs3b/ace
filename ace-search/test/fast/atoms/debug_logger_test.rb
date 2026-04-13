# frozen_string_literal: true

require "test_helper"
require "ace/search/atoms/debug_logger"
require "stringio"

module Ace
  module Search
    module Atoms
      class TestDebugLogger < AceSearchTestCase
        def setup
          # Reset state before each test
          DebugLogger.reset!
          @original_stderr = $stderr
        end

        def teardown
          # Restore original stderr
          $stderr = @original_stderr
          # Clear ENV to avoid affecting other tests
          ENV.delete("DEBUG")
          DebugLogger.reset!
        end

        # Test enabled? method

        def test_enabled_returns_false_when_debug_not_set
          ENV.delete("DEBUG")
          DebugLogger.reset!

          refute DebugLogger.enabled?, "Should be disabled when DEBUG env not set"
        end

        def test_enabled_returns_true_when_debug_is_1
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          assert DebugLogger.enabled?, "Should be enabled when DEBUG=1"
        end

        def test_enabled_returns_true_when_debug_is_true
          ENV["DEBUG"] = "true"
          DebugLogger.reset!

          assert DebugLogger.enabled?, "Should be enabled when DEBUG=true"
        end

        def test_enabled_returns_false_when_debug_is_false
          ENV["DEBUG"] = "false"
          DebugLogger.reset!

          refute DebugLogger.enabled?, "Should be disabled when DEBUG=false"
        end

        def test_enabled_returns_false_when_debug_is_0
          ENV["DEBUG"] = "0"
          DebugLogger.reset!

          refute DebugLogger.enabled?, "Should be disabled when DEBUG=0"
        end

        def test_enabled_caches_result
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          first_call = DebugLogger.enabled?
          ENV["DEBUG"] = "0"  # Change env
          second_call = DebugLogger.enabled?

          assert_equal first_call, second_call, "Should cache enabled state"
        end

        def test_reset_clears_cache
          ENV["DEBUG"] = "1"
          DebugLogger.reset!
          assert DebugLogger.enabled?

          ENV["DEBUG"] = "0"
          DebugLogger.reset!  # Reset cache
          refute DebugLogger.enabled?
        end

        # Test log method

        def test_log_outputs_nothing_when_disabled
          ENV.delete("DEBUG")
          DebugLogger.reset!

          $stderr = StringIO.new
          DebugLogger.log("test message")

          assert_empty $stderr.string, "Should not log when disabled"
        end

        def test_log_outputs_message_when_enabled
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          $stderr = StringIO.new
          DebugLogger.log("test message")

          assert_match(/DEBUG: test message/, $stderr.string)
        end

        def test_log_uses_custom_prefix
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          $stderr = StringIO.new
          DebugLogger.log("test message", prefix: "CUSTOM")

          assert_match(/CUSTOM: test message/, $stderr.string)
        end

        def test_log_handles_multiline_messages
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          $stderr = StringIO.new
          DebugLogger.log("line1\nline2\nline3")

          output = $stderr.string
          assert_match(/line1/, output)
          assert_match(/line2/, output)
          assert_match(/line3/, output)
        end

        # Test section method

        def test_section_outputs_nothing_when_disabled
          ENV.delete("DEBUG")
          DebugLogger.reset!

          $stderr = StringIO.new
          DebugLogger.section("Test Section") do
            DebugLogger.log("inside section")
          end

          assert_empty $stderr.string, "Should not output when disabled"
        end

        def test_section_outputs_title_with_separators_when_enabled
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          $stderr = StringIO.new
          DebugLogger.section("Test Section")

          output = $stderr.string
          assert_match(/={60}/, output, "Should have separator line")
          assert_match(/DEBUG: Test Section/, output, "Should have titled section")
        end

        def test_section_executes_block_when_enabled
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          $stderr = StringIO.new
          block_executed = false

          DebugLogger.section("Test Section") do
            block_executed = true
            DebugLogger.log("inside block")
          end

          assert block_executed, "Should execute block"
          assert_match(/inside block/, $stderr.string, "Should output block content")
        end

        def test_section_without_block_when_enabled
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          $stderr = StringIO.new
          DebugLogger.section("Test Section")

          output = $stderr.string
          assert_match(/Test Section/, output)
          # Should not raise error without block
        end

        def test_section_formats_output_correctly
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          $stderr = StringIO.new
          DebugLogger.section("RipgrepExecutor") do
            DebugLogger.log("  search_path = /project/root", prefix: "  ")
            DebugLogger.log("  command = rg pattern .", prefix: "  ")
          end

          output = $stderr.string
          lines = output.split("\n")

          assert_equal "=" * 60, lines[0], "First line should be separator"
          assert_match(/DEBUG: RipgrepExecutor/, lines[1])
          assert_match(/search_path/, output)
          assert_match(/command/, output)
          assert_equal "=" * 60, lines[-1], "Last line should be separator"
        end

        # Integration test

        def test_realistic_usage_pattern
          ENV["DEBUG"] = "1"
          DebugLogger.reset!

          $stderr = StringIO.new

          DebugLogger.section("SearchExecutor") do
            DebugLogger.log("options[:search_path] = \"/Users/test/project\"")
            DebugLogger.log("Current Dir.pwd = /Users/test/project/sub")
            DebugLogger.log("Command: rg --color=never pattern .")
          end

          output = $stderr.string

          assert_match(/SearchExecutor/, output)
          assert_match(%r{/Users/test/project}, output)
          assert_match(/Command: rg/, output)
          assert output.lines.count >= 5, "Should have multiple lines of output"
        end
      end
    end
  end
end
