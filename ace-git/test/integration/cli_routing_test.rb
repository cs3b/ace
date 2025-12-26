# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/cli"

class CliRoutingTest < AceGitTestCase
  def setup
    super
    # We need to stub out the actual command execution for CLI routing tests
    @mock_diff_result = Ace::Git::Models::DiffResult.new(
      content: "mock diff",
      files: [],
      stats: {}
    )
    @mock_context = Ace::Git::Models::RepoStatus.new(
      branch: "main",
      repository_type: :normal,
      repository_state: :clean
    )
    @mock_branch_info = {
      name: "main",
      detached: false,
      tracking: "origin/main",
      up_to_date: true
    }
  end

  # --- Command Routing Tests ---

  def test_cli_routes_diff_command
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, @mock_diff_result do
        output = capture_io do
          Ace::Git::CLI.start(["diff"])
        end
        assert_match(/mock diff/, output.first)
      end
    end
  end

  def test_cli_routes_status_command
    Ace::Git::Organisms::RepoStatusLoader.stub :load, @mock_context do
      output = capture_io do
        Ace::Git::CLI.start(["status"])
      end
      assert_match(/main/, output.first)
    end
  end

  def test_cli_routes_branch_command
    Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
      output = capture_io do
        Ace::Git::CLI.start(["branch"])
      end
      assert_match(/main/, output.first)
    end
  end

  def test_cli_routes_pr_command_with_number
    mock_result = {
      success: true,
      metadata: { "number" => 42, "title" => "Test", "state" => "OPEN" }
    }

    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, mock_result do
        output = capture_io do
          Ace::Git::CLI.start(["pr", "42"])
        end
        # Compact format: # PR #42: Test [OPEN]
        assert_match(/PR #42/, output.first)
      end
    end
  end

  def test_cli_routes_version_command
    output = capture_io do
      Ace::Git::CLI.start(["version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  def test_cli_routes_version_with_short_flag
    output = capture_io do
      Ace::Git::CLI.start(["-v"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  def test_cli_routes_version_with_long_flag
    output = capture_io do
      Ace::Git::CLI.start(["--version"])
    end
    assert_match(/\d+\.\d+\.\d+/, output.first)
  end

  # --- Magic Range Routing Tests ---

  def test_cli_routes_range_with_double_dots_to_diff
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, @mock_diff_result do
        output = capture_io do
          Ace::Git::CLI.start(["HEAD~1..HEAD"])
        end
        assert_match(/mock diff/, output.first)
      end
    end
  end

  def test_cli_routes_range_with_triple_dots_to_diff
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, @mock_diff_result do
        output = capture_io do
          Ace::Git::CLI.start(["origin/main...HEAD"])
        end
        assert_match(/mock diff/, output.first)
      end
    end
  end

  def test_cli_routes_tilde_ref_to_diff
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, @mock_diff_result do
        output = capture_io do
          Ace::Git::CLI.start(["HEAD~5"])
        end
        assert_match(/mock diff/, output.first)
      end
    end
  end

  def test_cli_routes_caret_ref_to_diff
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, @mock_diff_result do
        output = capture_io do
          Ace::Git::CLI.start(["HEAD^2"])
        end
        assert_match(/mock diff/, output.first)
      end
    end
  end

  def test_cli_routes_head_to_diff
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, @mock_diff_result do
        output = capture_io do
          Ace::Git::CLI.start(["HEAD"])
        end
        assert_match(/mock diff/, output.first)
      end
    end
  end

  def test_cli_routes_reflog_syntax_to_diff
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, @mock_diff_result do
        output = capture_io do
          Ace::Git::CLI.start(["HEAD@{1}..HEAD"])
        end
        assert_match(/mock diff/, output.first)
      end
    end
  end

  # --- Default Task Tests ---

  def test_cli_uses_diff_as_default_task
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, @mock_diff_result do
        # No arguments should invoke diff
        output = capture_io do
          Ace::Git::CLI.start([])
        end
        assert_match(/mock diff/, output.first)
      end
    end
  end

  # --- Format Option Tests ---

  def test_cli_passes_format_option_to_diff
    Ace::Git::Atoms::CommandExecutor.stub :in_git_repo?, true do
      captured_format = nil
      Ace::Git::Organisms::DiffOrchestrator.stub :generate, ->(opts) {
        captured_format = opts[:format] || opts["format"]
        @mock_diff_result
      } do
        capture_io do
          Ace::Git::CLI.start(["diff", "--format", "summary"])
        end
      end
      # Thor may pass format as symbol or string, so check the string value
      assert_equal "summary", captured_format.to_s
    end
  end

  def test_cli_passes_json_format_to_status
    Ace::Git::Organisms::RepoStatusLoader.stub :load, @mock_context do
      output = capture_io do
        Ace::Git::CLI.start(["status", "--format", "json"])
      end
      json = JSON.parse(output.first)
      assert_equal "main", json["branch"]
    end
  end

  def test_cli_passes_json_format_to_branch
    Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
      output = capture_io do
        Ace::Git::CLI.start(["branch", "--format", "json"])
      end
      json = JSON.parse(output.first)
      assert_equal "main", json["name"]
    end
  end

  # --- Magic Routing False Positive Prevention Tests ---
  # These tests ensure that common git command patterns are NOT
  # accidentally routed to diff via magic range detection.
  # Thor raises errors for unknown commands, which is the expected behavior -
  # these words should NOT match the magic git range patterns.

  # Note: 'status' is a valid command
  # See test_cli_routes_status_command above

  def test_cli_does_not_route_log_to_diff
    # "log" should NOT be caught by magic routing
    assert_raises(NoMethodError) do
      capture_io do
        Ace::Git::CLI.start(["log"])
      end
    end
  end

  def test_cli_does_not_route_show_to_diff
    # "show" should NOT be caught by magic routing
    assert_raises(NoMethodError) do
      capture_io do
        Ace::Git::CLI.start(["show"])
      end
    end
  end

  def test_cli_does_not_route_commit_to_diff
    # "commit" should NOT be caught by magic routing
    assert_raises(NoMethodError) do
      capture_io do
        Ace::Git::CLI.start(["commit"])
      end
    end
  end

  def test_cli_does_not_route_help_to_diff
    output = capture_io do
      Ace::Git::CLI.start(["help"])
    end
    # Should show help, not diff
    refute_match(/mock diff/, output.first)
    # Help should mention available commands
    assert_match(/diff|context|branch|pr/i, output.first)
  end

  def test_cli_help_flag_not_routed_as_range
    # --help should show help, not be treated as a git range
    output = capture_io do
      Ace::Git::CLI.start(["--help"])
    end
    # Should show help, not diff
    refute_match(/mock diff/, output.first)
    # Help should mention available commands
    assert_match(/diff|context|branch|pr/i, output.first)
  end

  def test_cli_short_help_flag_not_routed_as_range
    # -h should show help, not be treated as a git range
    output = capture_io do
      Ace::Git::CLI.start(["-h"])
    end
    # Should show help, not diff
    refute_match(/mock diff/, output.first)
    # Help should mention available commands
    assert_match(/diff|context|branch|pr/i, output.first)
  end
end
