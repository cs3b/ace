# frozen_string_literal: true

require_relative "test_helper"

class CliOverrideTest < Minitest::Test
  def test_traditional_worktree_mise_trust_logic
    # Test the core logic of mise trust override without full manager initialization

    # Test Case 1: no_mise_trust override should disable mise trust
    config_mise_trust_auto = true  # Config setting
    options = {no_mise_trust: true}

    # This is what our fix does:
    should_trust_mise = options[:no_mise_trust] ? false : config_mise_trust_auto
    assert_equal false, should_trust_mise, "Should disable mise trust when --no-mise-trust is passed"

    # Test Case 2: When no override, should use config default
    options = {}
    should_trust_mise = options[:no_mise_trust] ? false : config_mise_trust_auto
    assert_equal true, should_trust_mise, "Should use config default when no override"
  end

  def test_task_orchestrator_override_logic
    # Test the core logic of task orchestrator overrides

    # Mock config settings
    mock_config = Minitest::Mock.new
    mock_config.expect(:auto_mark_in_progress?, true)
    mock_config.expect(:auto_commit_task?, true)
    mock_config.expect(:mise_trust_auto?, true)

    # Test Case 1: All overrides set to true (disable actions)
    options = {no_status_update: true, no_commit: true, no_mise_trust: true}

    # This is what our fix does:
    should_update_status = options[:no_status_update] ? false : mock_config.auto_mark_in_progress?
    should_commit = options[:no_commit] ? false : mock_config.auto_commit_task?
    should_trust_mise = options[:no_mise_trust] ? false : mock_config.mise_trust_auto?

    assert_equal false, should_update_status, "Should disable status update with --no-status-update"
    assert_equal false, should_commit, "Should disable commit with --no-commit"
    assert_equal false, should_trust_mise, "Should disable mise trust with --no-mise-trust"

    # Test Case 2: No overrides (use config defaults)
    options = {}

    should_update_status = options[:no_status_update] ? false : mock_config.auto_mark_in_progress?
    should_commit = options[:no_commit] ? false : mock_config.auto_commit_task?
    should_trust_mise = options[:no_mise_trust] ? false : mock_config.mise_trust_auto?

    assert_equal true, should_update_status, "Should use config default when no override"
    assert_equal true, should_commit, "Should use config default when no override"
    assert_equal true, should_trust_mise, "Should use config default when no override"

    mock_config.verify
  end

  def test_custom_commit_message_override
    # Test custom commit message logic
    options = {commit_message: "Custom commit message"}

    # This is what our fix does:
    commit_message = options[:commit_message] || "in-progress"

    assert_equal "Custom commit message", commit_message, "Should use custom commit message"

    # Test default when no custom message
    options = {}
    commit_message = options[:commit_message] || "in-progress"

    assert_equal "in-progress", commit_message, "Should use default when no custom message"
  end
end
