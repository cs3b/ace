# frozen_string_literal: true

require_relative "../test_helper"

class TaskPusherTest < Minitest::Test
  def setup
    @pusher = Ace::Git::Worktree::Molecules::TaskPusher.new
  end

  def test_push_returns_success_on_successful_push
    # Mock successful push
    mock_result = {success: true, output: "Everything up-to-date", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "feature-branch") do
        result = @pusher.push(remote: "origin")
        assert result[:success]
        assert_equal "origin", result[:remote]
        assert_equal "feature-branch", result[:branch]
      end
    end
  end

  def test_push_returns_failure_on_failed_push
    # Mock failed push
    mock_result = {success: false, output: "", error: "rejected"}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "feature-branch") do
        result = @pusher.push(remote: "origin")
        refute result[:success]
      end
    end
  end

  def test_push_returns_failure_when_no_branch
    @pusher.stub(:current_branch, nil) do
      result = @pusher.push(remote: "origin")
      refute result[:success]
      assert_match(/branch/, result[:error])
    end
  end

  def test_push_uses_provided_branch
    mock_result = {success: true, output: "", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      result = @pusher.push(remote: "origin", branch: "custom-branch")
      assert result[:success]
      assert_equal "custom-branch", result[:branch]
    end
  end

  def test_push_uses_provided_remote
    mock_result = {success: true, output: "", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "main") do
        result = @pusher.push(remote: "upstream")
        assert result[:success]
        assert_equal "upstream", result[:remote]
      end
    end
  end

  def test_remote_exists_returns_true_when_remote_exists
    mock_result = {success: true, output: "git@github.com:user/repo.git", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      assert @pusher.remote_exists?("origin")
    end
  end

  def test_remote_exists_returns_false_when_remote_missing
    mock_result = {success: false, output: "", error: "No such remote"}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      refute @pusher.remote_exists?("nonexistent")
    end
  end

  def test_current_branch_returns_branch_name
    mock_result = {success: true, output: "feature-branch\n", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      assert_equal "feature-branch", @pusher.current_branch
    end
  end

  def test_current_branch_returns_nil_for_detached_head
    mock_result = {success: true, output: "", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      assert_nil @pusher.current_branch
    end
  end

  def test_has_upstream_returns_true_when_tracking
    mock_result = {success: true, output: "origin/main", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "main") do
        assert @pusher.has_upstream?
      end
    end
  end

  def test_has_upstream_returns_false_when_not_tracking
    mock_result = {success: false, output: "", error: "no upstream"}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "local-only") do
        refute @pusher.has_upstream?
      end
    end
  end

  def test_get_upstream_parses_remote_and_branch
    mock_result = {success: true, output: "origin/main\n", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "main") do
        upstream = @pusher.get_upstream
        assert_equal "origin", upstream[:remote]
        assert_equal "main", upstream[:branch]
      end
    end
  end

  def test_get_upstream_returns_nil_when_no_upstream
    mock_result = {success: false, output: "", error: "no upstream"}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "local-only") do
        assert_nil @pusher.get_upstream
      end
    end
  end

  def test_default_timeout_is_60_seconds
    assert_equal 60, Ace::Git::Worktree::Molecules::TaskPusher::DEFAULT_TIMEOUT
  end

  def test_custom_timeout_can_be_set
    pusher = Ace::Git::Worktree::Molecules::TaskPusher.new(timeout: 120)
    assert_equal 120, pusher.instance_variable_get(:@timeout)
  end

  # set_upstream tests

  def test_set_upstream_returns_success_when_tracking_set
    mock_result = {success: true, output: "Branch 'feature' set up to track 'origin/feature'.", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "feature") do
        result = @pusher.set_upstream(remote: "origin")
        assert result[:success]
        assert_equal "origin", result[:remote]
        assert_equal "feature", result[:branch]
      end
    end
  end

  def test_set_upstream_returns_failure_when_remote_branch_missing
    mock_result = {success: false, output: "", error: "error: the requested upstream branch 'origin/nonexistent' does not exist"}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "nonexistent") do
        result = @pusher.set_upstream(remote: "origin")
        refute result[:success]
        assert_match(/does not exist/, result[:error])
      end
    end
  end

  def test_set_upstream_returns_failure_when_no_branch
    @pusher.stub(:current_branch, nil) do
      result = @pusher.set_upstream(remote: "origin")
      refute result[:success]
      assert_match(/branch/, result[:error])
    end
  end

  def test_set_upstream_uses_provided_branch
    mock_result = {success: true, output: "", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      result = @pusher.set_upstream(branch: "custom-branch", remote: "origin")
      assert result[:success]
      assert_equal "custom-branch", result[:branch]
    end
  end

  def test_set_upstream_uses_provided_remote
    mock_result = {success: true, output: "", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "main") do
        result = @pusher.set_upstream(remote: "upstream")
        assert result[:success]
        assert_equal "upstream", result[:remote]
      end
    end
  end

  def test_set_upstream_defaults_to_origin_remote
    mock_result = {success: true, output: "", error: ""}

    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, mock_result) do
      @pusher.stub(:current_branch, "feature") do
        result = @pusher.set_upstream
        assert result[:success]
        assert_equal "origin", result[:remote]
      end
    end
  end
end
