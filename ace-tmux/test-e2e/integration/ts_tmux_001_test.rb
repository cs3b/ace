# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class TSTMUX001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-tmux")
  end

  def run_cmd(*args)
    Open3.capture3(@exe, *args, chdir: @root)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-tmux/, stdout + stderr)
    assert_match(/start|window|list/, stdout + stderr)
  end

  def test_list_sessions_surface
    stdout, stderr, status = run_cmd("list", "sessions")

    assert status.success?, stderr
    assert_match(/session|preset|no sessions/i, stdout + stderr)
  end
end
