# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/git/worktree/molecules/bootstrap_executor"

class BootstrapExecutorTest < Minitest::Test
  def setup
    setup_temp_dir
  end

  def teardown
    teardown_temp_dir
  end

  def test_no_bootstrap_flag_returns_skipped
    executor = Ace::Git::Worktree::Molecules::BootstrapExecutor.new(
      project_root: @temp_dir,
      no_bootstrap: true
    )
    res = executor.run
    assert_equal "bootstrap", res[:phase]
    assert_equal "skipped", res[:status]
  end

  def test_unconfigured_command_returns_not_configured
    executor = Ace::Git::Worktree::Molecules::BootstrapExecutor.new(
      project_root: @temp_dir,
      bootstrap_config: {}
    )
    res = executor.run
    assert_equal "not_configured", res[:status]
  end

  def test_successful_command_returns_succeeded
    executor = Ace::Git::Worktree::Molecules::BootstrapExecutor.new(
      project_root: @temp_dir,
      bootstrap_config: {"command" => "echo hello", "timeout" => 10, "policy" => "required"}
    )
    res = executor.run
    assert_equal "succeeded", res[:status]
    assert_equal 0, res[:exit_code]
    assert_match(/hello/, res[:output])
  end

  def test_failing_required_command_returns_required_failed
    executor = Ace::Git::Worktree::Molecules::BootstrapExecutor.new(
      project_root: @temp_dir,
      bootstrap_config: {"command" => "exit 1", "timeout" => 10, "policy" => "required"}
    )
    res = executor.run
    assert_equal "required_failed", res[:status]
    assert_equal 1, res[:exit_code]
  end

  def test_failing_advisory_command_returns_advisory_failed
    executor = Ace::Git::Worktree::Molecules::BootstrapExecutor.new(
      project_root: @temp_dir,
      bootstrap_config: {"command" => "exit 1", "timeout" => 10, "policy" => "advisory"}
    )
    res = executor.run
    assert_equal "advisory_failed", res[:status]
  end
end
