# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/molecules/recent_commits_fetcher"

class RecentCommitsFetcherTest < AceGitTestCase
  def test_fetch_returns_commits_on_success
    log_output = <<~LOG
      a7404e9 feat(ace-git): Add PR activity awareness
      74e8f77 chore(task-140.10): mark as in-progress
      dd7c557 chore(retros): Document semantic collision
    LOG

    mock_result = {success: true, output: log_output}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "log", "-3", "--format=%h %s"]

    result = Ace::Git::Molecules::RecentCommitsFetcher.fetch(limit: 3, executor: mock_executor)

    assert result[:success]
    assert_equal 3, result[:commits].length
    assert_equal "a7404e9", result[:commits][0][:hash]
    assert_equal "feat(ace-git): Add PR activity awareness", result[:commits][0][:subject]
    mock_executor.verify
  end

  def test_fetch_respects_limit
    log_output = "a7404e9 Single commit\n"
    mock_result = {success: true, output: log_output}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "log", "-1", "--format=%h %s"]

    result = Ace::Git::Molecules::RecentCommitsFetcher.fetch(limit: 1, executor: mock_executor)

    assert result[:success]
    assert_equal 1, result[:commits].length
    mock_executor.verify
  end

  def test_fetch_returns_empty_when_limit_zero
    result = Ace::Git::Molecules::RecentCommitsFetcher.fetch(limit: 0)

    assert result[:success]
    assert_empty result[:commits]
  end

  def test_fetch_returns_empty_on_failure
    mock_result = {success: false, output: "", error: "fatal: not a git repository"}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "log", "-3", "--format=%h %s"]

    result = Ace::Git::Molecules::RecentCommitsFetcher.fetch(limit: 3, executor: mock_executor)

    refute result[:success]
    assert_empty result[:commits]
    assert_equal "fatal: not a git repository", result[:error]
    mock_executor.verify
  end

  def test_fetch_handles_empty_output
    mock_result = {success: true, output: ""}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "log", "-3", "--format=%h %s"]

    result = Ace::Git::Molecules::RecentCommitsFetcher.fetch(limit: 3, executor: mock_executor)

    assert result[:success]
    assert_empty result[:commits]
    mock_executor.verify
  end

  def test_fetch_handles_commit_with_spaces_in_subject
    log_output = "abc1234 fix: handle spaces in commit messages properly\n"
    mock_result = {success: true, output: log_output}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "log", "-1", "--format=%h %s"]

    result = Ace::Git::Molecules::RecentCommitsFetcher.fetch(limit: 1, executor: mock_executor)

    assert result[:success]
    assert_equal "abc1234", result[:commits][0][:hash]
    assert_equal "fix: handle spaces in commit messages properly", result[:commits][0][:subject]
    mock_executor.verify
  end

  def test_fetch_handles_exception
    mock_executor = Object.new
    def mock_executor.execute(*)
      raise StandardError, "unexpected error"
    end

    result = Ace::Git::Molecules::RecentCommitsFetcher.fetch(limit: 3, executor: mock_executor)

    refute result[:success]
    assert_empty result[:commits]
    assert_equal "unexpected error", result[:error]
  end
end
