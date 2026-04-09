# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class TSTEST002IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-test-suite")
  end

  def test_suite_help_surface
    stdout, stderr, status = Open3.capture3(@exe, "--help", chdir: @root)

    assert status.success?, stderr
    assert_match(/ace-test-suite/, stdout + stderr)
  end
end
