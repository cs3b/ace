# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/cli/commands/status"

class StatusTest < AceGitTestCase
  def setup
    super
    @command = Ace::Git::CLI::Commands::Status.new
  end

  def test_execute_returns_success_with_context
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "main",
      repository_type: :normal,
      repository_state: :clean
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.call(format: nil)
        assert_nil result
      end
      # Should output markdown by default
      assert_match(/main/, output.first)
    end
  end

  def test_execute_returns_error_when_not_git_repo
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: nil,
      repository_type: :not_git
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      error = assert_raises(Ace::Support::Cli::Error) do
        @command.call(format: nil)
      end
      assert_match(/Not in a git repository/, error.message)
    end
  end

  def test_execute_outputs_json_format
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :dirty
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.call(format: "json")
        assert_nil result
      end
      json = JSON.parse(output.first)
      assert_equal "feature/test", json["branch"]
      assert_equal "normal", json["repository_type"]
    end
  end

  def test_execute_outputs_markdown_format
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "develop",
      repository_type: :worktree,
      repository_state: :clean
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.call(format: "markdown")
        assert_nil result
      end
      # Markdown output should contain formatted info
      refute_empty output.first
    end
  end

  def test_execute_handles_ace_git_error
    Ace::Git::Organisms::RepoStatusLoader.stub :load, ->(_opts) { raise Ace::Git::Error, "Context loading failed" } do
      error = assert_raises(Ace::Support::Cli::Error) do
        @command.call(format: nil)
      end
      assert_match(/Context loading failed/, error.message)
    end
  end

  def test_execute_with_diff_option_and_pr
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/pr-test",
      repository_type: :normal,
      repository_state: :clean,
      pr_metadata: {"number" => 123, "title" => "Test PR"}
    )

    mock_diff_result = {success: true, diff: "+added line\n-removed line"}

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_diff, mock_diff_result do
        output = capture_io do
          result = @command.call(format: nil, with_diff: true)
          assert_nil result
        end
        assert_match(/PR Diff/, output.first)
        assert_match(/\+added line/, output.first)
      end
    end
  end

  def test_execute_with_diff_option_silently_handles_diff_error
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/pr-test",
      repository_type: :normal,
      repository_state: :clean,
      pr_metadata: {"number" => 123, "title" => "Test PR"}
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_diff, ->(_pr) { raise Ace::Git::Error, "Diff failed" } do
        output = capture_io do
          result = @command.call(format: nil, with_diff: true)
          # Should still succeed - diff errors are silently skipped
          assert_nil result
        end
        # Should NOT contain error message
        refute_match(/Diff failed/, output.join)
      end
    end
  end

  def test_execute_with_no_pr_flag_skips_pr_lookups
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :clean
      # No pr_metadata or pr_activity
    )

    captured_options = nil
    Ace::Git::Organisms::RepoStatusLoader.stub :load, ->(opts) {
      captured_options = opts
      mock_context
    } do
      capture_io do
        result = @command.call(format: nil, no_pr: true)
        assert_nil result
      end

      # Verify that include_pr and include_pr_activity are false
      refute captured_options[:include_pr]
      refute captured_options[:include_pr_activity]
    end
  end

  def test_execute_without_no_pr_flag_includes_pr_lookups
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :clean
    )

    captured_options = nil
    Ace::Git::Organisms::RepoStatusLoader.stub :load, ->(opts) {
      captured_options = opts
      mock_context
    } do
      capture_io do
        @command.call(format: nil, no_pr: false)
      end

      # Verify that include_pr and include_pr_activity are true
      assert captured_options[:include_pr]
      assert captured_options[:include_pr_activity]
    end
  end

  def test_execute_includes_pr_activity_in_output
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :clean,
      pr_activity: {
        merged: [{"number" => 84, "title" => "Merged PR"}],
        open: [{"number" => 85, "title" => "Open PR", "author" => {"login" => "dev"}}]
      }
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.call(format: nil)
        assert_nil result
      end

      assert_match(/## PR Activity/, output.first)
      assert_match(/#84 Merged PR/, output.first)
      assert_match(/#85 Open PR \(@dev\)/, output.first)
    end
  end

  def test_execute_includes_pr_activity_in_json_output
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :clean,
      pr_activity: {
        merged: [{"number" => 84}],
        open: []
      }
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.call(format: "json")
        assert_nil result
      end

      json = JSON.parse(output.first)
      assert json.key?("pr_activity")
      assert json.key?("has_pr_activity")
      assert json["has_pr_activity"]
    end
  end

  def test_execute_passes_commits_limit_to_loader
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :clean
    )

    captured_options = nil
    Ace::Git::Organisms::RepoStatusLoader.stub :load, ->(opts) {
      captured_options = opts
      mock_context
    } do
      capture_io do
        @command.call(format: nil, commits: 5)
      end

      assert_equal 5, captured_options[:commits_limit]
      assert captured_options[:include_commits]
    end
  end

  def test_execute_disables_commits_when_limit_zero
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :clean
    )

    captured_options = nil
    Ace::Git::Organisms::RepoStatusLoader.stub :load, ->(opts) {
      captured_options = opts
      mock_context
    } do
      capture_io do
        @command.call(format: nil, commits: 0)
      end

      refute captured_options[:include_commits]
    end
  end

  def test_execute_includes_git_status_in_position
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :clean,
      git_status_sb: "## feature/test...origin/feature/test\n M file.rb"
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.call(format: nil)
        assert_nil result
      end

      assert_match(/## Position/, output.first)
      assert_match(/## feature\/test\.\.\.origin\/feature\/test/, output.first)
      assert_match(/M file\.rb/, output.first)
    end
  end

  def test_execute_includes_recent_commits_in_output
    mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :clean,
      recent_commits: [
        {hash: "a7404e9", subject: "feat: Add feature"}
      ]
    )

    Ace::Git::Organisms::RepoStatusLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.call(format: nil)
        assert_nil result
      end

      assert_match(/## Recent Commits/, output.first)
      assert_match(/a7404e9 feat: Add feature/, output.first)
    end
  end
end
