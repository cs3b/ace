# frozen_string_literal: true

require "test_helper"
require "ace/git/molecules/branch_reader"

class BranchReaderTest < AceGitTestCase
  def test_current_branch_delegates_to_executor
    executor = Object.new
    def executor.current_branch
      "feature/test-branch"
    end

    result = Ace::Git::Molecules::BranchReader.current_branch(executor: executor)
    assert_equal "feature/test-branch", result
  end

  def test_current_branch_returns_nil_when_executor_returns_nil
    executor = Object.new
    def executor.current_branch
      nil
    end

    result = Ace::Git::Molecules::BranchReader.current_branch(executor: executor)
    assert_nil result
  end

  def test_detached_returns_true_when_abbrev_ref_is_head
    executor = Object.new
    def executor.execute(*_args)
      {success: true, output: "HEAD\n"}
    end

    result = Ace::Git::Molecules::BranchReader.detached?(executor: executor)
    assert result, "Should return true when in detached HEAD state"
  end

  def test_detached_returns_false_when_on_branch
    executor = Object.new
    def executor.execute(*_args)
      {success: true, output: "main\n"}
    end

    result = Ace::Git::Molecules::BranchReader.detached?(executor: executor)
    refute result, "Should return false when on a branch"
  end

  def test_detached_returns_false_on_failure
    executor = Object.new
    def executor.execute(*_args)
      {success: false, output: "", error: "not a git repo"}
    end

    result = Ace::Git::Molecules::BranchReader.detached?(executor: executor)
    refute result, "Should return false on failure"
  end

  def test_tracking_branch_delegates_to_executor
    executor = Object.new
    def executor.tracking_branch
      "origin/feature/test-branch"
    end

    result = Ace::Git::Molecules::BranchReader.tracking_branch(executor: executor)
    assert_equal "origin/feature/test-branch", result
  end

  def test_tracking_status_returns_ahead_behind_counts
    executor = Object.new
    def executor.execute(*_args)
      {success: true, output: "3\t5\n"}  # behind\tahead format
    end

    result = Ace::Git::Molecules::BranchReader.tracking_status(executor: executor)
    assert_equal 5, result[:ahead]
    assert_equal 3, result[:behind]
  end

  def test_tracking_status_returns_zeros_on_failure
    executor = Object.new
    def executor.execute(*_args)
      {success: false, output: "", error: "no upstream"}
    end

    result = Ace::Git::Molecules::BranchReader.tracking_status(executor: executor)
    assert_equal 0, result[:ahead]
    assert_equal 0, result[:behind]
    assert result[:error]
  end

  def test_full_info_returns_complete_branch_info
    executor = Object.new
    def executor.current_branch
      "main"
    end

    def executor.execute(cmd, *args)
      if args.include?("--abbrev-ref")
        {success: true, output: "main\n"}
      elsif args.include?("--left-right")
        {success: true, output: "0\t0\n"}
      else
        {success: false, output: ""}
      end
    end

    def executor.tracking_branch
      "origin/main"
    end

    result = Ace::Git::Molecules::BranchReader.full_info(executor: executor)

    assert_equal "main", result[:name]
    assert_equal false, result[:detached]
    assert_equal "origin/main", result[:tracking]
    assert_equal 0, result[:ahead]
    assert_equal 0, result[:behind]
    assert result[:up_to_date]
    assert_equal "up to date", result[:status_description]
  end

  def test_full_info_returns_error_when_not_in_git_repo
    executor = Object.new
    def executor.current_branch
      nil  # Not in git repo
    end

    result = Ace::Git::Molecules::BranchReader.full_info(executor: executor)
    assert result[:error]
    assert_match(/Not in git repository/, result[:error])
  end

  def test_full_info_detects_detached_head
    executor = Object.new
    def executor.current_branch
      "abc123def456"  # SHA when detached
    end

    def executor.execute(cmd, *args)
      if args.include?("--abbrev-ref")
        {success: true, output: "HEAD\n"}  # Detached HEAD
      elsif args.include?("--left-right")
        {success: true, output: "0\t0\n"}
      else
        {success: false, output: ""}
      end
    end

    def executor.tracking_branch
      nil
    end

    result = Ace::Git::Molecules::BranchReader.full_info(executor: executor)

    assert_equal "abc123def456", result[:name], "Should return SHA for name when detached"
    assert_equal true, result[:detached]
  end

  def test_format_status_up_to_date
    result = Ace::Git::Molecules::BranchReader.format_status(0, 0)
    assert_equal "up to date", result
  end

  def test_format_status_ahead_only
    result = Ace::Git::Molecules::BranchReader.format_status(3, 0)
    assert_equal "3 ahead", result
  end

  def test_format_status_behind_only
    result = Ace::Git::Molecules::BranchReader.format_status(0, 5)
    assert_equal "5 behind", result
  end

  def test_format_status_both_ahead_and_behind
    result = Ace::Git::Molecules::BranchReader.format_status(2, 4)
    assert_equal "2 ahead, 4 behind", result
  end
end
