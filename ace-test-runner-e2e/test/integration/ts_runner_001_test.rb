# frozen_string_literal: true

require "open3"
require_relative "../test_helper"

class TsRunner001Test < Minitest::Test
  def test_ace_test_e2e_help_mentions_two_phase_layout
    stdout, stderr, status = Open3.capture3("ace-test-e2e", "--help")

    assert status.success?, stderr
    assert_includes stdout, "test/integration"
    assert_includes stdout, "test/e2e"
  end

  def test_ace_test_e2e_suite_help_is_available
    stdout, stderr, status = Open3.capture3("ace-test-e2e-suite", "--help")

    assert status.success?, stderr
    assert_includes stdout, "ace-test-e2e-suite"
  end
end
