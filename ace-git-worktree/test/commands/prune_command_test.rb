# frozen_string_literal: true

require_relative "../test_helper"

class PruneCommandTest < Minitest::Test
  def setup
    setup_temp_dir
    @command = Ace::Git::Worktree::Commands::PruneCommand.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_with_help_flag
    result = @command.run(["--help"])
    assert_equal 0, result
  end

  def test_run_prunes_worktrees
    # Mock successful worktree pruning
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:prune, {success: true})

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run([])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_dry_run_flag
    # Mock successful dry run pruning
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:prune, {success: true})

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--dry-run"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_force_flag
    # Mock successful force pruning
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:prune, {success: true})

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--force"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_verbose_flag
    # Mock successful verbose pruning
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:prune, {success: true})

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run(["--verbose"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_handles_prune_errors_gracefully
    # Mock worktree manager throwing an error
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:prune, nil) do
      raise StandardError, "Git command failed"
    end

    @command.instance_variable_set(:@manager, mock_worktree_manager)

    result = @command.run([])
    assert_equal 1, result
    mock_worktree_manager.verify
  end

  def test_argument_combinations
    # Test multiple flag combinations
    flag_combinations = [
      ["--dry-run", "--verbose"],
      ["--force", "--verbose"],
      ["--dry-run", "--force"],
      ["--dry-run", "--force", "--verbose"]
    ]

    flag_combinations.each do |flags|
      mock_worktree_manager = Minitest::Mock.new
      mock_worktree_manager.expect(:prune, {success: true})

      @command.instance_variable_set(:@manager, mock_worktree_manager)

      result = @command.run(flags)
      assert_equal 0, result, "Should accept flag combination: #{flags.join(" ")}"
      mock_worktree_manager.verify
    end
  end

  def test_invalid_arguments
    # Test that invalid arguments are rejected
    invalid_args = [
      ["invalid-argument"],
      ["--invalid-flag"],
      ["/some/path"],  # prune doesn't take paths
      ["081"]  # prune doesn't take task IDs
    ]

    invalid_args.each do |args|
      result = @command.run(args)
      assert_equal 1, result, "Should reject invalid arguments: #{args}"
    end
  end
end
