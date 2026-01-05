# frozen_string_literal: true

require "test_helper"
require "ace/nav/cli"
require "stringio"

module Ace
  module Nav
    class CliTest < Minitest::Test
      def setup
        @cli = CLI.new
        @original_stdout = $stdout
      end

      def teardown
        $stdout = @original_stdout
      end

      def test_auto_list_with_trailing_slash
        # Test the pattern detection logic
        assert @cli.magic_wildcard_pattern?("prompt://guidelines/"),
               "Trailing slash should trigger wildcard pattern"
      end

      def test_auto_list_with_wildcard
        # Test the pattern detection logic
        assert @cli.magic_wildcard_pattern?("prompt://format/*"),
               "Wildcard pattern should trigger wildcard pattern"
      end

      def test_auto_list_with_question_mark
        # Test the pattern detection logic
        assert @cli.magic_wildcard_pattern?("prompt://format/standar?"),
               "Question mark pattern should trigger wildcard pattern"
      end

      def test_no_auto_list_for_specific_file
        # Test the pattern detection logic
        refute @cli.magic_wildcard_pattern?("prompt://guidelines/tone.md"),
               "Specific file path should not trigger wildcard pattern"
      end

      def test_protocol_only_auto_list
        # Test the pattern detection logic
        assert @cli.magic_wildcard_pattern?("prompt://"),
               "Protocol-only URI should trigger wildcard pattern"
      end
    end
  end
end
