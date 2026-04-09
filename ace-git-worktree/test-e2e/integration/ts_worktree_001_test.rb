# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class TSWORKTREE001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-git-worktree")
  end

  def run_cmd(*args)
    Open3.capture3(@exe, *args, chdir: @root)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-git-worktree/, stdout + stderr)
    assert_match(/create|list|remove/, stdout + stderr)
  end

  def test_list_and_dry_run_create
    stdout, stderr, status = run_cmd("list")
    assert status.success?, stderr

    stdout, stderr, status = run_cmd("create", "bugfix/test-fix", "--path", ".ace-wt/bugfix-test-fix", "--dry-run")
    assert status.success?, stderr
    assert_match(/bugfix\/test-fix|bugfix-test-fix/, stdout + stderr)
  end
end
