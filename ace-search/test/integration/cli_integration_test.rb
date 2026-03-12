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
        assert_match(/COMMANDS|Usage:/, stdout)
        assert_match(/search|Options:/, stdout)
        assert_empty stderr
      end

      def test_no_args_shows_help
        stdout, stderr, status = Open3.capture3(@exe_path)

        assert status.success?, "Command should show help without args"
        assert_match(/Usage:/, stdout + stderr)
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

      def test_count_output_flag
        skip_unless_rg_available

        stdout, _stderr, status = Open3.capture3(
          @exe_path, "test", "--count", "--max-results", "1",
          chdir: File.expand_path("../../..", __dir__)
        )

        assert status.success?, "Command should succeed"
        assert_match(/Found \d+ results/, stdout)
      end

      def test_invalid_option_shows_error
        stdout, stderr, status = Open3.capture3(@exe_path, "--invalid-option", "pattern")

        refute status.success?, "Command should fail with invalid option"
        # OptionParser prints to stdout, not stderr
        assert_match(/invalid option/i, stdout + stderr)
      end

      # Search path argument tests

      def test_explicit_current_directory_search_path
        skip_unless_rg_available

        # Run from project root with explicit "./" search path
        stdout, _stderr, status = Open3.capture3(
          @exe_path, "test", "./", "--max-results", "1",
          chdir: File.expand_path("../../..", __dir__)
        )

        assert status.success?, "Command should succeed with explicit current directory"
        assert_match(/Found \d+ results?/, stdout)
      end

      def test_explicit_subdirectory_search_path
        skip_unless_rg_available

        # Run with explicit subdirectory search path
        stdout, _stderr, status = Open3.capture3(
          @exe_path, "test", "test/", "--max-results", "1",
          chdir: File.expand_path("../../..", __dir__)
        )

        assert status.success?, "Command should succeed with explicit subdirectory"
        assert_match(/Found \d+ results?/, stdout)
      end

      def test_search_from_subdirectory_finds_project_wide_results
        skip_unless_rg_available

        # Run from a subdirectory without explicit path - should search project root
        # We'll use the test/ directory as our subdirectory
        test_dir = File.expand_path("../../..", __dir__)

        stdout, _stderr, status = Open3.capture3(
          @exe_path, "Ace::Search", "--max-results", "1",
          chdir: File.join(test_dir, "test")
        )

        assert status.success?, "Command should succeed from subdirectory"
        # Should find results from the entire project, not just test/
        assert_match(/Found \d+ results?/, stdout)
      end

      def test_env_variable_project_root_path
        skip_unless_rg_available

        # Set PROJECT_ROOT_PATH environment variable
        test_dir = File.expand_path("../../..", __dir__)

        stdout, _stderr, status = Open3.capture3(
          { "PROJECT_ROOT_PATH" => test_dir },
          @exe_path, "test", "--max-results", "1",
          chdir: Dir.tmpdir  # Run from unrelated directory
        )

        assert status.success?, "Command should succeed with PROJECT_ROOT_PATH"
        assert_match(/Found \d+ results?/, stdout)
      end

      def test_help_shows_updated_usage
        stdout, _stderr, status = Open3.capture3(@exe_path, "--help")

        assert status.success?, "Help command should succeed"
        assert_match(/PATTERN \[SEARCH_PATH\]/, stdout, "Help should show optional SEARCH_PATH argument")
      end

      def test_warns_on_nonexistent_explicit_path
        skip_unless_rg_available

        # Use a path that definitely doesn't exist
        nonexistent_path = "/nonexistent/path/#{rand(100000)}"

        stdout, stderr, status = Open3.capture3(
          @exe_path, "test", nonexistent_path
        )

        # Should warn but not fail (ripgrep will handle the error)
        assert_match(/Warning.*does not exist/, stderr, "Should warn about non-existent path")
        assert_match(/Resolved to/, stderr, "Should show expanded path")
        assert_match(/Ripgrep\/fd may return/, stderr, "Should explain consequences")
      end
    end
  end
end
