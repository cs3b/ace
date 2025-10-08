# frozen_string_literal: true

require "test_helper"
require "open3"

module Ace
  module Search
    class TestCLIIntegration < AceSearchTestCase
      def setup
        @exe_path = File.expand_path("../../../exe/ace-search", __dir__)
        skip "executable not found" unless File.exist?(@exe_path)
      end

      def test_version_flag
        stdout, stderr, status = Open3.capture3(@exe_path, "--version")

        assert status.success?, "Command should succeed"
        assert_match(/ace-search \d+\.\d+\.\d+/, stdout)
        assert_empty stderr
      end

      def test_help_flag
        stdout, stderr, status = Open3.capture3(@exe_path, "--help")

        assert status.success?, "Command should succeed"
        assert_match(/Usage:/, stdout)
        assert_match(/Options:/, stdout)
        assert_empty stderr
      end

      def test_missing_pattern_shows_error
        stdout, stderr, status = Open3.capture3(@exe_path)

        refute status.success?, "Command should fail without pattern"
        assert_match(/No search pattern provided/, stdout + stderr)
      end

      def test_content_search_with_max_results
        skip_unless_rg_available

        stdout, _stderr, status = Open3.capture3(
          @exe_path, "test", "--max-results", "3",
          chdir: File.expand_path("../../..", __dir__)
        )

        assert status.success?, "Command should succeed"
        assert_match(/Found \d+ results/, stdout)
      end

      def test_file_search_mode
        skip_unless_fd_available

        stdout, _stderr, status = Open3.capture3(
          @exe_path, "test", "--files", "--max-results", "3",
          chdir: File.expand_path("../../..", __dir__)
        )

        assert status.success?, "Command should succeed"
        assert_match(/mode: file/, stdout)
      end

      def test_json_output_format
        skip_unless_rg_available

        stdout, _stderr, status = Open3.capture3(
          @exe_path, "test", "--json", "--max-results", "2",
          chdir: File.expand_path("../../..", __dir__)
        )

        assert status.success?, "Command should succeed"
        json = JSON.parse(stdout)
        assert json.key?("count")
        assert json.key?("results")
        assert json["results"].is_a?(Array)
      end

      def test_case_insensitive_search
        skip_unless_rg_available

        stdout, _stderr, status = Open3.capture3(
          @exe_path, "TODO", "-i", "--max-results", "1",
          chdir: File.expand_path("../../..", __dir__)
        )

        assert status.success?, "Command should succeed"
      end

      def test_invalid_option_shows_error
        stdout, stderr, status = Open3.capture3(@exe_path, "--invalid-option", "pattern")

        refute status.success?, "Command should fail with invalid option"
        # OptionParser prints to stdout, not stderr
        assert_match(/invalid option/i, stdout + stderr)
      end
    end
  end
end
