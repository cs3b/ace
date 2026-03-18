# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/cli/commands/branch"

class BranchTest < AceGitTestCase
  def setup
    super
    @command = Ace::Git::CLI::Commands::Branch.new
  end

  def test_execute_returns_success_with_branch_info
    mock_info = {
      name: "main",
      detached: false,
      tracking: "origin/main",
      up_to_date: true,
      status_description: "up to date"
    }

    Ace::Git::Molecules::BranchReader.stub :full_info, mock_info do
      output = capture_io do
        result = @command.call
        assert_nil result
      end
      assert_match(/main/, output.first)
      assert_match(/origin\/main/, output.first)
    end
  end

  def test_execute_returns_success_with_detached_head
    mock_info = {
      name: "abc1234",
      detached: true,
      tracking: nil,
      up_to_date: true
    }

    Ace::Git::Molecules::BranchReader.stub :full_info, mock_info do
      output = capture_io do
        result = @command.call
        assert_nil result
      end
      assert_match(/abc1234/, output.first)
      assert_match(/detached HEAD/, output.first)
    end
  end

  def test_execute_returns_error_on_branch_info_failure
    mock_info = { error: "fatal: not a git repository" }

    Ace::Git::Molecules::BranchReader.stub :full_info, mock_info do
      error = assert_raises(Ace::Support::Cli::Error) do
        @command.call
      end
      assert_match(/not a git repository/, error.message)
    end
  end

  def test_execute_outputs_json_format
    mock_info = {
      name: "feature/test",
      detached: false,
      tracking: "origin/feature/test",
      up_to_date: false,
      ahead: 2,
      behind: 1,
      status_description: "ahead 2, behind 1"
    }

    Ace::Git::Molecules::BranchReader.stub :full_info, mock_info do
      output = capture_io do
        result = @command.call(format: "json")
        assert_nil result
      end
      json = JSON.parse(output.first)
      assert_equal "feature/test", json["name"]
      assert_equal false, json["detached"]
      assert_equal 2, json["ahead"]
    end
  end

  def test_execute_shows_tracking_status_when_not_up_to_date
    mock_info = {
      name: "feature/test",
      detached: false,
      tracking: "origin/feature/test",
      up_to_date: false,
      status_description: "ahead 3"
    }

    Ace::Git::Molecules::BranchReader.stub :full_info, mock_info do
      output = capture_io do
        result = @command.call
        assert_nil result
      end
      assert_match(/ahead 3/, output.first)
    end
  end

  def test_execute_handles_ace_git_error
    Ace::Git::Molecules::BranchReader.stub :full_info, ->{ raise Ace::Git::Error, "Something went wrong" } do
      error = assert_raises(Ace::Support::Cli::Error) do
        @command.call
      end
      assert_match(/Something went wrong/, error.message)
    end
  end
end
