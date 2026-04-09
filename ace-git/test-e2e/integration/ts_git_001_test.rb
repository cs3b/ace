# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class TSGIT001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-git")
  end

  def run_cmd(*args)
    Open3.capture3(@exe, *args, chdir: @root)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-git/, stdout + stderr)
    assert_match(/diff|version/, stdout + stderr)
  end

  def test_version_surface
    stdout, stderr, status = run_cmd("version")

    assert status.success?, stderr
    assert_match(/ace-git \d+\.\d+\.\d+/, stdout)
  end
end
