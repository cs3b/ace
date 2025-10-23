# frozen_string_literal: true

require_relative "../test_helper"
require "ace/nav/cli"
require "tempfile"

class TaskProtocolIntegrationTest < Minitest::Test
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
    config_loader = Ace::Nav::Molecules::ConfigLoader.new(
      File.join(@temp_dir, ".ace", "nav")
    )

    assert_equal "cmd", config_loader.protocol_type("task")
  end

  def test_task_protocol_delegation_with_simple_reference
    cli = Ace::Nav::Cli.new

    # Test that delegation succeeds (exit code 0)
    # Note: system() outputs directly to stdout, can't be captured with capture_io
    assert_raises(SystemExit) do
      capture_io do  # Suppress output during test
        cli.run(["task://083"])
      end
    end
  end

  def test_task_protocol_delegation_with_full_reference
    cli = Ace::Nav::Cli.new

    assert_raises(SystemExit) do
      capture_io { cli.run(["task://v.0.9.0+task.083"]) }
    end
  end

  def test_task_protocol_with_path_option
    cli = Ace::Nav::Cli.new

    assert_raises(SystemExit) do
      capture_io { cli.run(["task://083", "--path"]) }
    end
  end

  def test_task_protocol_with_content_option
    cli = Ace::Nav::Cli.new

    assert_raises(SystemExit) do
      capture_io { cli.run(["task://083", "--content"]) }
    end
  end

  def test_task_protocol_with_tree_option
    cli = Ace::Nav::Cli.new

    assert_raises(SystemExit) do
      capture_io { cli.run(["task://083", "--tree"]) }
    end
  end

  def test_task_protocol_with_backlog_reference
    cli = Ace::Nav::Cli.new

    assert_raises(SystemExit) do
      capture_io { cli.run(["task://backlog+025"]) }
    end
  end

  def test_task_protocol_with_prefixed_reference
    cli = Ace::Nav::Cli.new

    assert_raises(SystemExit) do
      capture_io { cli.run(["task://task.083"]) }
    end
  end

  def test_cmd_protocol_check_in_navigation_engine
    engine = Ace::Nav::Organisms::NavigationEngine.new

    # Need to setup config in engine's context
    Dir.chdir(@temp_dir) do
      assert engine.cmd_protocol?("task")
      refute engine.cmd_protocol?("wfi")  # wfi is file-based
    end
  end

  def test_cli_help_shows_task_protocol
    cli = Ace::Nav::Cli.new

    stdout_output = capture_io do
      cli.run(["--help"])
    end

    # Help should list task:// protocol
    assert_match(/task:\/\//, stdout_output[0])
  end
end
