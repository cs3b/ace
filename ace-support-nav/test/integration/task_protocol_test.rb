# frozen_string_literal: true

require "test_helper"
require "ace/support/nav/cli"
require "dry/cli"
require "tempfile"

class TaskProtocolIntegrationTest < Minitest::Test
  private def run_cli(args)
    Dry::CLI.new(Ace::Support::Nav::CLI).call(arguments: args)
  end

  def setup
    @temp_dir = create_temp_ace_directory
    setup_task_protocol_config
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    cleanup_temp_directory(@temp_dir)
  end

  def setup_task_protocol_config
    # Create task:// protocol configuration
    protocols_dir = File.join(@temp_dir, ".ace", "nav", "protocols")
    FileUtils.mkdir_p(protocols_dir)

    protocol_config = {
      "protocol" => "task",
      "type" => "cmd",
      "name" => "Task Navigation",
      "description" => "Navigate to tasks via ace-taskflow delegation",
      "enabled" => true,
      "command_template" => "echo task %{ref}",  # Use echo for testing
      "pass_through_options" => ["--path", "--content", "--tree"]
    }

    File.write(
      File.join(protocols_dir, "task.yml"),
      protocol_config.to_yaml
    )
  end

  def test_task_protocol_detected_as_cmd_type
    config_loader = Ace::Support::Nav::Molecules::ConfigLoader.new(
      File.join(@temp_dir, ".ace", "nav")
    )

    assert_equal "cmd", config_loader.protocol_type("task")
  end

  def test_task_protocol_delegation_with_simple_reference
    # Test that delegation succeeds (no exception = exit code 0)
    # Per ADR-023, success is represented by no exception raised
    capture_io do
      run_cli(["resolve", "task://083"])
    end
    # No exception raised = success
  end

  def test_task_protocol_delegation_with_full_reference
    capture_io do
      run_cli(["resolve", "task://v.0.9.0+task.083"])
    end
    # No exception raised = success
  end

  def test_task_protocol_with_path_option
    capture_io do
      run_cli(["resolve", "task://083", "--path"])
    end
    # No exception raised = success
  end

  def test_task_protocol_with_content_option
    capture_io do
      run_cli(["resolve", "task://083", "--content"])
    end
    # No exception raised = success
  end

  def test_task_protocol_with_tree_option
    capture_io do
      run_cli(["resolve", "task://083", "--tree"])
    end
    # No exception raised = success
  end

  def test_task_protocol_with_backlog_reference
    capture_io do
      run_cli(["resolve", "task://backlog+025"])
    end
    # No exception raised = success
  end

  def test_task_protocol_with_prefixed_reference
    capture_io do
      run_cli(["resolve", "task://task.083"])
    end
    # No exception raised = success
  end

  def test_cmd_protocol_check_in_navigation_engine
    engine = Ace::Support::Nav::Organisms::NavigationEngine.new

    # Need to setup config in engine's context
    Dir.chdir(@temp_dir) do
      assert engine.cmd_protocol?("task")
      refute engine.cmd_protocol?("wfi")  # wfi is file-based
    end
  end

  def test_resolve_cmd_to_path_returns_captured_output
    Tempfile.create("task_test") do |f|
      # Write content so the file exists on disk
      f.write("task file content")
      f.flush

      # Update the protocol config to echo the temp file path
      protocols_dir = File.join(@temp_dir, ".ace", "nav", "protocols")
      protocol_config = {
        "protocol" => "task",
        "type" => "cmd",
        "name" => "Task Navigation",
        "description" => "Navigate to tasks via ace-taskflow delegation",
        "enabled" => true,
        "command_template" => "echo #{f.path}",
        "pass_through_options" => ["--path", "--content", "--tree"]
      }
      File.write(File.join(protocols_dir, "task.yml"), protocol_config.to_yaml)

      Dir.chdir(@temp_dir) do
        engine = Ace::Support::Nav::Organisms::NavigationEngine.new
        result = engine.resolve_cmd_to_path("task://083")
        assert_equal f.path, result
      end
    end
  end

  def test_resolve_cmd_to_path_returns_nil_for_non_cmd_protocol
    Dir.chdir(@temp_dir) do
      engine = Ace::Support::Nav::Organisms::NavigationEngine.new
      result = engine.resolve_cmd_to_path("wfi://some/workflow")
      assert_nil result
    end
  end

  def test_resolve_cmd_to_path_returns_nil_on_command_failure
    # Set up a protocol that runs a failing command
    protocols_dir = File.join(@temp_dir, ".ace", "nav", "protocols")
    protocol_config = {
      "protocol" => "task",
      "type" => "cmd",
      "name" => "Task Navigation",
      "enabled" => true,
      "command_template" => "false"  # always exits with failure
    }
    File.write(File.join(protocols_dir, "task.yml"), protocol_config.to_yaml)

    Dir.chdir(@temp_dir) do
      engine = Ace::Support::Nav::Organisms::NavigationEngine.new
      result = engine.resolve_cmd_to_path("task://083")
      assert_nil result
    end
  end

  def test_cli_help_displays_successfully
    stdout_output = capture_io do
      run_cli(["--help"])
    end

    # Help should display dry-cli-standard format
    assert_match(/COMMANDS|Commands:|Usage:/, stdout_output[0])
  end
end
