# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/commands/context_command"

class ContextCommandTest < AceGitTestCase
  def setup
    super
    @command = Ace::Git::Commands::ContextCommand.new
  end

  def test_execute_returns_success_with_context
    mock_context = Ace::Git::Models::RepoContext.new(
      branch: "main",
      repository_type: :normal,
      repository_state: :clean
    )

    Ace::Git::Organisms::RepoContextLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.execute(format: nil)
        assert_equal 0, result
      end
      # Should output markdown by default
      assert_match(/main/, output.first)
    end
  end

  def test_execute_returns_error_when_not_git_repo
    mock_context = Ace::Git::Models::RepoContext.new(
      branch: nil,
      repository_type: :not_git
    )

    Ace::Git::Organisms::RepoContextLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.execute(format: nil)
        assert_equal 1, result
      end
      assert_match(/Not in a git repository/, output.last)
    end
  end

  def test_execute_outputs_json_format
    mock_context = Ace::Git::Models::RepoContext.new(
      branch: "feature/test",
      repository_type: :normal,
      repository_state: :dirty
    )

    Ace::Git::Organisms::RepoContextLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.execute(format: "json")
        assert_equal 0, result
      end
      json = JSON.parse(output.first)
      assert_equal "feature/test", json["branch"]
      assert_equal "normal", json["repository_type"]
    end
  end

  def test_execute_outputs_markdown_format
    mock_context = Ace::Git::Models::RepoContext.new(
      branch: "develop",
      repository_type: :worktree,
      repository_state: :clean
    )

    Ace::Git::Organisms::RepoContextLoader.stub :load, mock_context do
      output = capture_io do
        result = @command.execute(format: "markdown")
        assert_equal 0, result
      end
      # Markdown output should contain formatted info
      refute_empty output.first
    end
  end

  def test_execute_handles_ace_git_error
    Ace::Git::Organisms::RepoContextLoader.stub :load, ->(_opts){ raise Ace::Git::Error, "Context loading failed" } do
      output = capture_io do
        result = @command.execute(format: nil)
        assert_equal 1, result
      end
      assert_match(/Context loading failed/, output.last)
    end
  end

  def test_execute_with_diff_option_and_pr
    mock_context = Ace::Git::Models::RepoContext.new(
      branch: "feature/pr-test",
      repository_type: :normal,
      repository_state: :clean,
      pr_metadata: { "number" => 123, "title" => "Test PR" }
    )

    mock_diff_result = { success: true, diff: "+added line\n-removed line" }

    Ace::Git::Organisms::RepoContextLoader.stub :load, mock_context do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_diff, mock_diff_result do
        output = capture_io do
          result = @command.execute(format: nil, with_diff: true)
          assert_equal 0, result
        end
        assert_match(/PR Diff/, output.first)
        assert_match(/\+added line/, output.first)
      end
    end
  end

  def test_execute_with_diff_option_silently_handles_diff_error
    mock_context = Ace::Git::Models::RepoContext.new(
      branch: "feature/pr-test",
      repository_type: :normal,
      repository_state: :clean,
      pr_metadata: { "number" => 123, "title" => "Test PR" }
    )

    Ace::Git::Organisms::RepoContextLoader.stub :load, mock_context do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_diff, ->(_pr){ raise Ace::Git::Error, "Diff failed" } do
        output = capture_io do
          result = @command.execute(format: nil, with_diff: true)
          # Should still succeed - diff errors are silently skipped
          assert_equal 0, result
        end
        # Should NOT contain error message
        refute_match(/Diff failed/, output.join)
      end
    end
  end
end
