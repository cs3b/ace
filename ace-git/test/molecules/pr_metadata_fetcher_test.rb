# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/molecules/pr_metadata_fetcher"

class PrMetadataFetcherTest < AceGitTestCase
  def test_gh_installed_returns_true_when_gh_available
    Ace::Git::Atoms::CommandExecutor.stub :execute, { success: true, output: "gh version 2.0.0" } do
      assert Ace::Git::Molecules::PrMetadataFetcher.gh_installed?
    end
  end

  def test_gh_installed_returns_false_when_gh_not_found
    Ace::Git::Atoms::CommandExecutor.stub :execute, { success: false, output: "" } do
      refute Ace::Git::Molecules::PrMetadataFetcher.gh_installed?
    end
  end

  def test_gh_authenticated_returns_true_when_logged_in
    Ace::Git::Atoms::CommandExecutor.stub :execute, { success: true, output: "Logged in" } do
      assert Ace::Git::Molecules::PrMetadataFetcher.gh_authenticated?
    end
  end

  def test_gh_authenticated_returns_false_when_not_logged_in
    Ace::Git::Atoms::CommandExecutor.stub :execute, { success: false, output: "" } do
      refute Ace::Git::Molecules::PrMetadataFetcher.gh_authenticated?
    end
  end

  def test_fetch_diff_returns_diff_content_on_success
    mock_output = { success: true, output: "+added line\n-removed line", error: "", exit_code: 0 }

    Open3.stub :capture3, ["#{mock_output[:output]}", "", stub_status(true)] do
      result = Ace::Git::Molecules::PrMetadataFetcher.fetch_diff("42", timeout: 5)
      assert result[:success]
      assert_match(/added line/, result[:diff])
    end
  end

  def test_fetch_diff_raises_on_invalid_identifier
    assert_raises(ArgumentError) do
      Ace::Git::Molecules::PrMetadataFetcher.fetch_diff("not-a-pr", timeout: 5)
    end
  end

  def test_fetch_diff_raises_pr_not_found_error
    Open3.stub :capture3, ["", "Could not resolve to a PullRequest", stub_status(false)] do
      assert_raises(Ace::Git::PrNotFoundError) do
        Ace::Git::Molecules::PrMetadataFetcher.fetch_diff("99999", timeout: 5)
      end
    end
  end

  def test_fetch_diff_raises_auth_error
    Open3.stub :capture3, ["", "not logged in", stub_status(false)] do
      assert_raises(Ace::Git::GhAuthenticationError) do
        Ace::Git::Molecules::PrMetadataFetcher.fetch_diff("42", timeout: 5)
      end
    end
  end

  def test_fetch_metadata_returns_parsed_json
    mock_json = { "number" => 42, "title" => "Test PR", "state" => "OPEN" }.to_json

    Open3.stub :capture3, [mock_json, "", stub_status(true)] do
      result = Ace::Git::Molecules::PrMetadataFetcher.fetch_metadata("42", timeout: 5)
      assert result[:success]
      assert_equal 42, result[:metadata]["number"]
      assert_equal "Test PR", result[:metadata]["title"]
    end
  end

  def test_fetch_metadata_raises_on_invalid_identifier
    assert_raises(ArgumentError) do
      Ace::Git::Molecules::PrMetadataFetcher.fetch_metadata("invalid", timeout: 5)
    end
  end

  def test_fetch_metadata_handles_json_parse_error
    Open3.stub :capture3, ["not valid json", "", stub_status(true)] do
      result = Ace::Git::Molecules::PrMetadataFetcher.fetch_metadata("42", timeout: 5)
      refute result[:success]
      assert_match(/Failed to parse PR metadata/, result[:error])
    end
  end

  def test_fetch_pr_returns_both_diff_and_metadata
    mock_diff = "+added\n-removed"
    mock_json = { "number" => 42, "title" => "Test PR" }.to_json

    call_count = 0
    Open3.stub :capture3, ->(*_args) {
      call_count += 1
      if call_count == 1
        [mock_diff, "", stub_status(true)]
      else
        [mock_json, "", stub_status(true)]
      end
    } do
      result = Ace::Git::Molecules::PrMetadataFetcher.fetch_pr("42", timeout: 5)
      assert result[:success]
      assert_match(/added/, result[:diff])
      assert_equal 42, result[:metadata]["number"]
    end
  end

  def test_find_pr_for_branch_returns_number_string
    mock_json = { "number" => 123 }.to_json

    Open3.stub :capture3, [mock_json, "", stub_status(true)] do
      result = Ace::Git::Molecules::PrMetadataFetcher.find_pr_for_branch(timeout: 5)
      assert_equal "123", result
    end
  end

  def test_find_pr_for_branch_returns_nil_when_no_pr
    Open3.stub :capture3, ["", "no PR", stub_status(false)] do
      result = Ace::Git::Molecules::PrMetadataFetcher.find_pr_for_branch(timeout: 5)
      assert_nil result
    end
  end

  def test_find_pr_for_branch_returns_nil_on_json_error
    Open3.stub :capture3, ["not json", "", stub_status(true)] do
      result = Ace::Git::Molecules::PrMetadataFetcher.find_pr_for_branch(timeout: 5)
      assert_nil result
    end
  end

  def test_fetch_diff_includes_repo_in_source_label
    mock_output = "+diff"

    Open3.stub :capture3, [mock_output, "", stub_status(true)] do
      result = Ace::Git::Molecules::PrMetadataFetcher.fetch_diff("owner/repo#42", timeout: 5)
      assert result[:success]
      assert_match(/owner\/repo/, result[:source])
    end
  end

  def test_timeout_raises_timeout_error
    Open3.stub :capture3, ->(*_args) { sleep 10 } do
      assert_raises(Ace::Git::TimeoutError) do
        Timeout.stub :timeout, ->(timeout, &block) { raise Timeout::Error } do
          Ace::Git::Molecules::PrMetadataFetcher.fetch_diff("42", timeout: 1)
        end
      end
    end
  end

  private

  def stub_status(success)
    status = Object.new
    status.define_singleton_method(:success?) { success }
    status.define_singleton_method(:exitstatus) { success ? 0 : 1 }
    status
  end
end
