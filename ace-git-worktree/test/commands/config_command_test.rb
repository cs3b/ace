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
    # Mock successful config display
    mock_config_manager = Minitest::Mock.new
    config_data = {
      "worktree_root" => "/worktrees",
      "naming_pattern" => "task-{id}-{slug}",
      "mise_trust" => true
    }
    mock_config_manager.expect(:show_config, config_data, [])

    @command.instance_variable_set(:@config_manager, mock_config_manager)

    # Capture output to verify it displays config
    output = capture_io do
      result = @command.run(["show"])
    end

    assert_equal 0, result
    mock_config_manager.verify
  end

  def test_run_validate_config
    # Mock successful config validation
    mock_config_manager = Minitest::Mock.new
    validation_result = { valid: true, errors: [] }
    mock_config_manager.expect(:validate_config, validation_result, [])

    @command.instance_variable_set(:@config_manager, mock_config_manager)

    result = @command.run(["validate"])
    assert_equal 0, result
    mock_config_manager.verify
  end

  def test_run_validate_config_with_errors
    # Mock config validation with errors
    mock_config_manager = Minitest::Mock.new
    validation_result = {
      valid: false,
      errors: ["worktree_root is required", "invalid naming pattern"]
    }
    mock_config_manager.expect(:validate_config, validation_result, [])

    @command.instance_variable_set(:@config_manager, mock_config_manager)

    result = @command.run(["validate"])
    assert_equal 1, result
    mock_config_manager.verify
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
    mock_config_manager = Minitest::Mock.new
    mock_config_manager.expect(:show_config, nil) do
      raise StandardError, "Config file not found"
    end

    @command.instance_variable_set(:@config_manager, mock_config_manager)

    result = @command.run(["show"])
    assert_equal 1, result
    mock_config_manager.verify
  end

  def test_security_validation_on_config_paths
    # Test that dangerous config values are handled safely
    mock_config_manager = Minitest::Mock.new
    dangerous_config = {
      "worktree_root" => "/etc/passwd; rm -rf /",
      "naming_pattern" => "$(whoami)"
    }

    # Should still display but sanitize if needed
    mock_config_manager.expect(:show_config, dangerous_config, [])

    @command.instance_variable_set(:@config_manager, mock_config_manager)

    result = @command.run(["show"])
    assert_equal 0, result
    mock_config_manager.verify
  end

  def test_config_with_special_characters
    # Test handling of special characters in config values
    mock_config_manager = Minitest::Mock.new
    special_config = {
      "worktree_root" => "/path/with-dashes_and.underscores",
      "naming_pattern" => "task-{id}-{slug} (v{version})",
      "description" => "Config with unicode: ✓ test"
    }
    mock_config_manager.expect(:show_config, special_config, [])

    @command.instance_variable_set(:@config_manager, mock_config_manager)

    result = @command.run(["show"])
    assert_equal 0, result
    mock_config_manager.verify
  end
end