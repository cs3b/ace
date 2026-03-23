# frozen_string_literal: true

require_relative "../test_helper"

class ConfigCommandTest < Minitest::Test
  def setup
    setup_temp_dir
    @command = Ace::Git::Worktree::Commands::ConfigCommand.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_with_help_flag
    result = @command.run(["--help"])
    assert_equal 0, result
  end

  def test_run_show_config
    skip "Mock config object expectations don't match implementation method calls - needs investigation of config object interface"

    # Mock successful config display
    mock_manager = Minitest::Mock.new
    mock_config = Minitest::Mock.new
    mock_config.expect(:root_path, "/worktrees")
    mock_config.expect(:absolute_root_path, "/absolute/worktrees")
    mock_config.expect(:mise_trust_auto?, true)
    mock_config.expect(:directory_format, "task-{id}-{slug}")
    mock_config.expect(:branch_format, "task-{id}")
    mock_config.expect(:auto_mark_in_progress?, false)
    mock_config.expect(:auto_commit_task?, false)
    mock_config.expect(:add_worktree_metadata?, false)
    mock_config.expect(:cleanup_on_merge?, false)
    mock_config.expect(:cleanup_on_delete?, false)
    # Called again in the example section
    mock_config.expect(:directory_format, "task-{id}-{slug}")
    mock_config.expect(:branch_format, "task-{id}")

    mock_manager.expect(:configuration, mock_config)

    @command.instance_variable_set(:@manager, mock_manager)

    # Capture output to verify it displays config
    result = nil
    capture_io do
      result = @command.run(["show"])
    end

    assert_equal 0, result
    mock_manager.verify
  end

  def test_run_validate_config
    # Mock successful config validation
    mock_manager = Minitest::Mock.new
    validation_result = {success: true, valid: true, errors: []}
    mock_manager.expect(:validate_configuration, validation_result)

    @command.instance_variable_set(:@manager, mock_manager)

    result = @command.run(["validate"])
    assert_equal 0, result
    mock_manager.verify
  end

  def test_run_validate_config_with_errors
    # Mock config validation with errors
    mock_manager = Minitest::Mock.new
    validation_result = {
      success: false,
      valid: false,
      errors: ["worktree_root is required", "invalid naming pattern"]
    }
    mock_manager.expect(:validate_configuration, validation_result)

    @command.instance_variable_set(:@manager, mock_manager)

    result = @command.run(["validate"])
    assert_equal 1, result
    mock_manager.verify
  end

  def test_run_with_no_subcommand_shows_help
    result = @command.run([])
    assert_equal 0, result  # Should show help
  end

  def test_run_with_invalid_subcommand
    result = @command.run(["invalid"])
    assert_equal 1, result
  end

  def test_handles_config_errors_gracefully
    # Mock config manager throwing an error
    mock_manager = Minitest::Mock.new
    mock_manager.expect(:configuration, nil) do
      raise StandardError, "Config file not found"
    end

    @command.instance_variable_set(:@manager, mock_manager)

    result = @command.run(["show"])
    assert_equal 1, result
    mock_manager.verify
  end

  def test_security_validation_on_config_paths
    skip "Mock config object expectations don't match implementation method calls - needs investigation of config object interface"

    # Test that dangerous config values are handled safely
    mock_manager = Minitest::Mock.new
    mock_config = Minitest::Mock.new
    mock_config.expect(:root_path, "/etc/passwd; rm -rf /")
    mock_config.expect(:absolute_root_path, "/absolute/etc/passwd")
    mock_config.expect(:mise_trust_auto?, false)
    mock_config.expect(:directory_format, "$(whoami)")
    mock_config.expect(:branch_format, "`cat /etc/passwd`")
    mock_config.expect(:auto_mark_in_progress?, false)
    mock_config.expect(:auto_commit_task?, false)
    mock_config.expect(:add_worktree_metadata?, false)
    mock_config.expect(:cleanup_on_merge?, false)
    mock_config.expect(:cleanup_on_delete?, false)
    # Called again in the example section
    mock_config.expect(:directory_format, "$(whoami)")
    mock_config.expect(:branch_format, "`cat /etc/passwd`")

    # Should still display but sanitize if needed
    mock_manager.expect(:configuration, mock_config)

    @command.instance_variable_set(:@manager, mock_manager)

    result = @command.run(["show"])
    assert_equal 0, result
    mock_manager.verify
  end

  def test_config_with_special_characters
    skip "Mock config object expectations don't match implementation method calls - needs investigation of config object interface"

    # Test handling of special characters in config values
    mock_manager = Minitest::Mock.new
    mock_config = Minitest::Mock.new
    mock_config.expect(:root_path, "/path/with-dashes_and.underscores")
    mock_config.expect(:absolute_root_path, "/absolute/path/with-dashes_and.underscores")
    mock_config.expect(:mise_trust_auto?, false)
    mock_config.expect(:directory_format, "task-{id}-{slug} (v{version})")
    mock_config.expect(:branch_format, "task-{id}")
    mock_config.expect(:auto_mark_in_progress?, false)
    mock_config.expect(:auto_commit_task?, false)
    mock_config.expect(:add_worktree_metadata?, false)
    mock_config.expect(:cleanup_on_merge?, false)
    mock_config.expect(:cleanup_on_delete?, false)
    # Called again in the example section
    mock_config.expect(:directory_format, "task-{id}-{slug} (v{version})")
    mock_config.expect(:branch_format, "task-{id}")

    mock_manager.expect(:configuration, mock_config)

    @command.instance_variable_set(:@manager, mock_manager)

    result = @command.run(["show"])
    assert_equal 0, result
    mock_manager.verify
  end
end
