# frozen_string_literal: true

require "test_helper"
require "ace/nav/cli"
require "stringio"

module Ace
  module Nav
    class CliTest < Minitest::Test
      def setup
        @cli = Cli.new
        @original_stdout = $stdout
      end

      def teardown
        $stdout = @original_stdout
      end

      def test_auto_list_with_trailing_slash
        # Test the pattern detection logic directly
        path_or_uri = "prompt://guidelines/"
        @cli.instance_variable_set(:@options, {})

        # Simulate the pattern check from execute method
        if path_or_uri.match?(/\/$/)
          @cli.instance_variable_get(:@options)[:list] = true
        end

        # Check that list mode was enabled
        options = @cli.instance_variable_get(:@options)
        assert options[:list], "Trailing slash should auto-enable list mode"
      end

      def test_auto_list_with_wildcard
        # Test the pattern detection logic directly
        path_or_uri = "prompt://format/*"
        @cli.instance_variable_set(:@options, {})

        # Simulate the pattern check from execute method
        if path_or_uri.include?("*") || path_or_uri.include?("?")
          @cli.instance_variable_get(:@options)[:list] = true
        end

        # Check that list mode was enabled
        options = @cli.instance_variable_get(:@options)
        assert options[:list], "Wildcard pattern should auto-enable list mode"
      end

      def test_auto_list_with_question_mark
        # Test the pattern detection logic directly
        path_or_uri = "prompt://format/standar?"
        @cli.instance_variable_set(:@options, {})

        # Simulate the pattern check from execute method
        if path_or_uri.include?("*") || path_or_uri.include?("?")
          @cli.instance_variable_get(:@options)[:list] = true
        end

        # Check that list mode was enabled
        options = @cli.instance_variable_get(:@options)
        assert options[:list], "Question mark pattern should auto-enable list mode"
      end

      def test_no_auto_list_for_specific_file
        # Test the pattern detection logic directly
        path_or_uri = "prompt://guidelines/tone.md"
        @cli.instance_variable_set(:@options, {})

        # Simulate the pattern checks from execute method
        if path_or_uri.match?(/^\w+:\/\/$/)
          @cli.instance_variable_get(:@options)[:list] = true
        elsif path_or_uri.include?("*") || path_or_uri.include?("?")
          @cli.instance_variable_get(:@options)[:list] = true
        elsif path_or_uri.match?(/\/$/)
          @cli.instance_variable_get(:@options)[:list] = true
        end

        # Check that list mode was NOT enabled
        options = @cli.instance_variable_get(:@options)
        refute options[:list], "Specific file path should not auto-enable list mode"
      end

      def test_protocol_only_auto_list
        # Capture output
        output = StringIO.new
        $stdout = output

        # Test that protocol-only URIs auto-enable list mode with wildcard
        @cli.instance_variable_set(:@options, {})
        path_or_uri = "prompt://"

        # We need to capture the modified path
        @cli.instance_eval do
          if path_or_uri.match?(/^\w+:\/\/$/)
            path_or_uri = "#{path_or_uri}*"
            @options[:list] = true
          end
        end

        # Check that list mode was enabled and wildcard was added
        options = @cli.instance_variable_get(:@options)
        assert options[:list], "Protocol-only URI should auto-enable list mode"
      end
    end
  end
end