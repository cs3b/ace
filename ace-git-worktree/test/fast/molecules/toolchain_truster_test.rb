# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/git/worktree/molecules/toolchain_truster"

class ToolchainTrusterTest < Minitest::Test
  def setup
    setup_temp_dir
    @truster = Ace::Git::Worktree::Molecules::ToolchainTruster.new(project_root: @temp_dir)
  end

  def teardown
    teardown_temp_dir
  end

  def test_no_tracked_configs_returns_not_applicable
    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, {success: true, output: "lib/foo.rb\nREADME.md\n"}) do
      res = @truster.verify_and_trust
      assert_equal "toolchain_trust", res[:phase]
      assert_equal "not_applicable", res[:status]
      assert_equal [], res[:tracked_files]
    end
  end

  def test_discovers_tracked_mise_toml
    git_output = "lib/foo.rb\n.mise.toml\nconfig/mise.toml\n"
    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, {success: true, output: git_output}) do
      tracked = @truster.discover_tracked_configs
      assert_includes tracked, ".mise.toml"
      assert_includes tracked, "config/mise.toml"
    end
  end

  def test_required_policy_fails_when_mise_missing_or_failed
    git_output = ".mise.toml\n"
    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, {success: true, output: git_output}) do
      truster = Ace::Git::Worktree::Molecules::ToolchainTruster.new(project_root: @temp_dir, policy: "required")
      # Stub Open3 to simulate missing mise or failure
      Open3.stub(:capture3, ["", "command not found", ProcessStatusMock.new(false)]) do
        res = truster.verify_and_trust
        assert_equal "required_failed", res[:status]
      end
    end
  end

  def test_advisory_policy_returns_advisory_failed_when_trust_fails
    git_output = ".mise.toml\n"
    Ace::Git::Worktree::Atoms::GitCommand.stub(:execute, {success: true, output: git_output}) do
      truster = Ace::Git::Worktree::Molecules::ToolchainTruster.new(project_root: @temp_dir, policy: "advisory")
      Open3.stub(:capture3, ["", "error", ProcessStatusMock.new(false)]) do
        res = truster.verify_and_trust
        assert_equal "advisory_failed", res[:status]
      end
    end
  end
end

class ProcessStatusMock
  def initialize(success)
    @success = success
  end

  def success?
    @success
  end
end
