# frozen_string_literal: true

require_relative "../../test_helper"
require "open3"

class SuiteExecutableTest < Minitest::Test
  def test_suite_executable_routes_to_dry_cli
    root_bin = File.expand_path("../../../../bin/ace-test-e2e-suite", __dir__)
    stdout, stderr, status = Open3.capture3("ruby", root_bin, "--help")

    assert status.success?, "Expected --help to succeed, got: #{stderr}"
    output = "#{stdout}\n#{stderr}"
    assert_includes output, "Run E2E test suite across all packages"
    refute_includes output, "Commands:", "Single-command CLI should not show subcommand list"
  end
end
