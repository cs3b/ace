# frozen_string_literal: true

require_relative "../test_helper"

class PrFetcherTest < Minitest::Test
  def setup
    @fetcher = Ace::Git::Worktree::Molecules::PrFetcher.new
  end

  def test_fetch_with_valid_pr_number
    pr_json = {
      "number" => 26,
      "title" => "Add authentication feature",
      "headRefName" => "feature/auth",
      "baseRefName" => "main",
      "isCrossRepository" => false,
      "headRepositoryOwner" => { "login" => "user" }
    }.to_json

    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    @fetcher.stub(:gh_available?, true) do
      Open3.stub(:capture3, [pr_json, "", mock_status]) do
        pr = @fetcher.fetch(26)

        refute_nil pr
        assert_equal 26, pr[:number]
        assert_equal "Add authentication feature", pr[:title]
        assert_equal "feature/auth", pr[:head_branch]
        assert_equal "main", pr[:base_branch]
        assert_equal false, pr[:is_cross_repository]
        assert_equal "user", pr[:head_repository_owner]
      end
    end
  end

  def test_fetch_with_string_pr_number
    pr_json = {
      "number" => 26,
      "title" => "Test PR",
      "headRefName" => "test",
      "baseRefName" => "main"
    }.to_json

    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    @fetcher.stub(:gh_available?, true) do
      Open3.stub(:capture3, [pr_json, "", mock_status]) do
        pr = @fetcher.fetch("26")
        refute_nil pr
        assert_equal 26, pr[:number]
      end
    end
  end

  def test_fetch_with_fork_pr
    pr_json = {
      "number" => 50,
      "title" => "External contribution",
      "headRefName" => "fix/bug",
      "baseRefName" => "main",
      "isCrossRepository" => true,
      "headRepositoryOwner" => { "login" => "external-contributor" }
    }.to_json

    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    @fetcher.stub(:gh_available?, true) do
      Open3.stub(:capture3, [pr_json, "", mock_status]) do
        pr = @fetcher.fetch(50)

        refute_nil pr
        assert_equal true, pr[:is_cross_repository]
        assert_equal "external-contributor", pr[:head_repository_owner]
      end
    end
  end

  def test_fetch_with_invalid_pr_numbers
    invalid_numbers = [0, -1, "abc", "1.5", "", "  ", nil]

    invalid_numbers.each do |invalid_num|
      @fetcher.stub(:gh_available?, true) do
        pr = @fetcher.fetch(invalid_num)
        assert_nil pr, "Should reject invalid PR number: #{invalid_num.inspect}"
      end
    end
  end

  def test_fetch_with_very_large_pr_number
    # Should reject unreasonably large PR numbers
    @fetcher.stub(:gh_available?, true) do
      pr = @fetcher.fetch(9999999)
      assert_nil pr
    end
  end

  def test_gh_available_when_installed
    @fetcher.stub(:system, true) do
      assert @fetcher.gh_available?
    end
  end

  def test_gh_available_when_not_installed
    @fetcher.stub(:system, false) do
      refute @fetcher.gh_available?
    end
  end

  def test_verify_gh_available_succeeds_when_installed
    @fetcher.stub(:gh_available?, true) do
      # Should not raise
      @fetcher.verify_gh_available!
    end
  end

  def test_verify_gh_available_raises_when_not_installed
    @fetcher.stub(:gh_available?, false) do
      error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::GhNotAvailableError) do
        @fetcher.verify_gh_available!
      end

      assert_match(/gh CLI is required/, error.message)
      assert_match(/brew install gh/, error.message)
    end
  end

  def test_fetch_raises_when_gh_not_available
    @fetcher.stub(:gh_available?, false) do
      error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::GhNotAvailableError) do
        @fetcher.fetch(26)
      end

      assert_match(/gh CLI is required/, error.message)
    end
  end

  def test_fetch_raises_when_pr_not_found
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { false }

    stderr_output = "could not resolve to a PullRequest"

    @fetcher.stub(:gh_available?, true) do
      @fetcher.stub(:get_repository_name, "test-org/test-repo") do
        Open3.stub(:capture3, ["", stderr_output, mock_status]) do
          error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::PrNotFoundError) do
            @fetcher.fetch(999)
          end

          assert_match(/PR #999 not found in test-org\/test-repo/, error.message)
        end
      end
    end
  end

  def test_fetch_raises_when_not_authenticated
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { false }

    stderr_output = "authentication required"

    @fetcher.stub(:gh_available?, true) do
      Open3.stub(:capture3, ["", stderr_output, mock_status]) do
        error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::NetworkError) do
          @fetcher.fetch(26)
        end

        assert_match(/not authenticated/, error.message)
        assert_match(/gh auth login/, error.message)
      end
    end
  end

  def test_fetch_raises_on_network_error
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { false }

    stderr_output = "network connection failed"

    @fetcher.stub(:gh_available?, true) do
      Open3.stub(:capture3, ["", stderr_output, mock_status]) do
        error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::NetworkError) do
          @fetcher.fetch(26)
        end

        assert_match(/Network error/, error.message)
      end
    end
  end

  def test_fetch_raises_on_invalid_json
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    invalid_json = "not valid json{["

    @fetcher.stub(:gh_available?, true) do
      Open3.stub(:capture3, [invalid_json, "", mock_status]) do
        error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::NetworkError) do
          @fetcher.fetch(26)
        end

        assert_match(/Failed to parse/, error.message)
      end
    end
  end

  def test_fetch_raises_on_missing_required_fields
    # JSON missing required fields
    incomplete_json = {
      "number" => 26,
      "title" => "Test"
      # Missing headRefName and baseRefName
    }.to_json

    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    @fetcher.stub(:gh_available?, true) do
      Open3.stub(:capture3, [incomplete_json, "", mock_status]) do
        error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::NetworkError) do
          @fetcher.fetch(26)
        end

        assert_match(/Invalid PR data/, error.message)
        assert_match(/missing fields/, error.message)
      end
    end
  end

  def test_gh_not_available_message
    message = @fetcher.gh_not_available_message

    assert_match(/gh CLI is required/, message)
    assert_match(/brew install gh/, message)
    assert_match(/gh auth login/, message)
  end

  def test_fetch_with_timeout
    # Test that timeout is respected
    @fetcher.stub(:gh_available?, true) do
      @fetcher.stub(:execute_with_timeout, proc { raise Timeout::Error }) do
        error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::NetworkError) do
          @fetcher.fetch(26)
        end

        assert_match(/timed out/, error.message)
      end
    end
  end

  def test_get_repository_name_success
    # Test successful repository name retrieval
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    Open3.stub(:capture3, ["test-owner/test-repo\n", "", mock_status]) do
      repo_name = @fetcher.send(:get_repository_name)
      assert_equal "test-owner/test-repo", repo_name
    end
  end

  def test_get_repository_name_failure
    # Test when repository name cannot be determined
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { false }

    Open3.stub(:capture3, ["", "error", mock_status]) do
      repo_name = @fetcher.send(:get_repository_name)
      assert_nil repo_name
    end
  end

  def test_get_repository_name_caching
    # Test that repository name is cached
    call_count = 0
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    Open3.stub(:capture3, proc {
      call_count += 1
      ["test-repo\n", "", mock_status]
    }) do
      # First call should fetch
      @fetcher.send(:get_repository_name)
      # Second call should use cache
      @fetcher.send(:get_repository_name)

      assert_equal 1, call_count, "Repository name should be cached after first call"
    end
  end

  def test_error_message_with_repository_context
    # Test that error messages include repository context
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { false }

    stderr_output = "could not resolve to a PullRequest"

    @fetcher.stub(:gh_available?, true) do
      @fetcher.stub(:get_repository_name, "owner/repo") do
        Open3.stub(:capture3, ["", stderr_output, mock_status]) do
          error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::PrNotFoundError) do
            @fetcher.fetch(123)
          end

          assert_match(/in owner\/repo/, error.message)
        end
      end
    end
  end

  def test_error_message_without_repository_context
    # Test fallback when repository name is unavailable
    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { false }

    stderr_output = "could not resolve to a PullRequest"

    @fetcher.stub(:gh_available?, true) do
      @fetcher.stub(:get_repository_name, nil) do
        Open3.stub(:capture3, ["", stderr_output, mock_status]) do
          error = assert_raises(Ace::Git::Worktree::Molecules::PrFetcher::PrNotFoundError) do
            @fetcher.fetch(123)
          end

          assert_match(/in this repository/, error.message)
        end
      end
    end
  end
end
