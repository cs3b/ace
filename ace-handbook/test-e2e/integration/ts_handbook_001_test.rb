# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "json"

class TSHANDBOOK001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-handbook")
  end

  def run_cmd(*args)
    Open3.capture3(@exe, *args, chdir: @root)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-handbook/, stdout + stderr)
    assert_match(/status|sync/, stdout + stderr)
  end

  def test_status_json_surface
    stdout, stderr, status = run_cmd("status", "--provider", "pi", "--format", "json")

    assert status.success?, stderr
    assert JSON.parse(stdout)
  end
end
