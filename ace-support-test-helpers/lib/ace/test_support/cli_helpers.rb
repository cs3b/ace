# frozen_string_literal: true

module Ace
  module TestSupport
    # CLI test helpers for ace-support-cli based CLIs
    #
    # This module provides reusable patterns for testing CLI commands
    # during the Thor to ace-support-cli migration (Task 179).
    #
    # @example Usage in test file
    #   require 'ace/test_support'
    #
    #   class CliRoutingTest < Minitest::Test
    #     include Ace::TestSupport::CliHelpers
    #
    #     def test_routes_to_version
    #       result = invoke_cli(MyGem::CLI, ["--version"])
    #       assert_match(/\d+\.\d+\.\d+/, result[:stdout])
    #     end
    #   end
    module CliHelpers
      # Invoke a ace-support-cli CLI and capture output
      #
      # This helper provides a consistent pattern for testing CLI routing
      # and command execution. It wraps CLI.start with capture_io to
      # capture stdout/stderr.
      #
      # @param cli_class [Class] The CLI module/class with a .start method
      # @param args [Array<String>] Command line arguments
      # @return [Hash] Result hash with :stdout, :stderr, :result keys
      #
      # @example Basic usage
      #   result = invoke_cli(Ace::Search::CLI, ["version"])
      #   assert_match(/\d+\.\d+/, result[:stdout])
      #
      # @example Testing with options
      #   result = invoke_cli(Ace::Search::CLI, ["search", "TODO", "--max-results", "10"])
      #   assert_equal 0, result[:result]
      #
      # @note ace-support-cli calls exit(0) for --help, so we catch SystemExit.
      #   Commands raise Ace::Support::Cli::Error for controlled failures
      #   (exception-based exit code pattern per ADR-023).
      def invoke_cli(cli_class, args)
        stdout, stderr = capture_io do
          @_cli_result = cli_class.start(args)
        rescue SystemExit => e
          @_cli_result = e.status
        rescue Ace::Support::Cli::Error => e
          warn e.message
          @_cli_result = e.exit_code
        end

        {
          stdout: stdout,
          stderr: stderr,
          result: @_cli_result
        }
      end

      # Invoke CLI and return only stdout (convenience method)
      #
      # @param cli_class [Class] The CLI module/class with a .start method
      # @param args [Array<String>] Command line arguments
      # @return [String] Standard output
      #
      # @example
      #   output = invoke_cli_stdout(Ace::Search::CLI, ["version"])
      #   assert_match(/\d+\.\d+/, output)
      def invoke_cli_stdout(cli_class, args)
        invoke_cli(cli_class, args)[:stdout]
      end

      # Assert CLI returns success (exit code 0)
      #
      # @param cli_class [Class] The CLI module/class with a .start method
      # @param args [Array<String>] Command line arguments
      # @param message [String, nil] Optional assertion message
      #
      # @example
      #   assert_cli_success(Ace::Search::CLI, ["version"])
      def assert_cli_success(cli_class, args, message = nil)
        result = invoke_cli(cli_class, args)
        assert_equal 0, result[:result],
          message || "Expected CLI to return 0, got #{result[:result]}. stderr: #{result[:stderr]}"
      end

      # Assert CLI output matches pattern
      #
      # @param cli_class [Class] The CLI module/class with a .start method
      # @param args [Array<String>] Command line arguments
      # @param pattern [Regexp, String] Pattern to match against stdout
      # @param message [String, nil] Optional assertion message
      #
      # @example
      #   assert_cli_output_matches(Ace::Search::CLI, ["version"], /\d+\.\d+/)
      def assert_cli_output_matches(cli_class, args, pattern, message = nil)
        result = invoke_cli(cli_class, args)
        assert_match pattern, result[:stdout],
          message || "Expected stdout to match #{pattern.inspect}"
      end
    end
  end
end
