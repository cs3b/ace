# frozen_string_literal: true

require "test_helper"
require "ace/git/molecules/git_status_fetcher"

class GitStatusFetcherTest < AceGitTestCase
  def test_fetch_status_sb_returns_output_on_success
    mock_result = {success: true, output: "## main...origin/main\n M file.rb\n"}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "-c", "color.status=false", "status", "-sb"]

    result = Ace::Git::Molecules::GitStatusFetcher.fetch_status_sb(executor: mock_executor)

    assert result[:success]
    assert_equal "## main...origin/main\n M file.rb", result[:output]
    mock_executor.verify
  end

  def test_fetch_status_sb_returns_empty_on_failure
    mock_result = {success: false, output: "", error: "not a git repo"}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "-c", "color.status=false", "status", "-sb"]

    result = Ace::Git::Molecules::GitStatusFetcher.fetch_status_sb(executor: mock_executor)

    refute result[:success]
    assert_equal "", result[:output]
    assert_equal "not a git repo", result[:error]
    mock_executor.verify
  end

  def test_fetch_status_sb_handles_clean_repo
    mock_result = {success: true, output: "## main...origin/main\n"}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "-c", "color.status=false", "status", "-sb"]

    result = Ace::Git::Molecules::GitStatusFetcher.fetch_status_sb(executor: mock_executor)

    assert result[:success]
    assert_equal "## main...origin/main", result[:output]
    mock_executor.verify
  end

  def test_fetch_status_sb_handles_multiple_changed_files
    status_output = <<~STATUS
      ## feature...origin/feature [ahead 2]
       M lib/file1.rb
       M lib/file2.rb
      ?? new_file.rb
    STATUS

    mock_result = {success: true, output: status_output}

    mock_executor = Minitest::Mock.new
    mock_executor.expect :execute, mock_result, ["git", "-c", "color.status=false", "status", "-sb"]

    result = Ace::Git::Molecules::GitStatusFetcher.fetch_status_sb(executor: mock_executor)

    assert result[:success]
    assert_includes result[:output], "## feature...origin/feature [ahead 2]"
    assert_includes result[:output], " M lib/file1.rb"
    assert_includes result[:output], "?? new_file.rb"
    mock_executor.verify
  end

  def test_fetch_status_sb_handles_exception
    mock_executor = Object.new
    def mock_executor.execute(*)
      raise StandardError, "unexpected error"
    end

    result = Ace::Git::Molecules::GitStatusFetcher.fetch_status_sb(executor: mock_executor)

    refute result[:success]
    assert_equal "", result[:output]
    assert_equal "unexpected error", result[:error]
  end
end
