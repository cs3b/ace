# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "json"

class TSWORKTREE002IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-git-worktree")
  end

  def run_cmd(*args)
    Open3.capture3(@exe, *args, chdir: @root)
  end

  def test_task_aware_list_views
    stdout, stderr, status = run_cmd("list", "--task-associated")
    assert status.success?, stderr

    stdout, stderr, status = run_cmd("list", "--show-tasks", "--format", "json")
    assert status.success?, stderr
    assert_kind_of(Array, JSON.parse(stdout))
  end
end
