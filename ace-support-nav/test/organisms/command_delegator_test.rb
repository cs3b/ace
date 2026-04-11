# frozen_string_literal: true

require "test_helper"
require "ace/support/nav/organisms/command_delegator"
require "ace/support/nav/molecules/config_loader"
require "ostruct"

class CommandDelegatorTest < Minitest::Test
  def setup
    @temp_dir = create_temp_ace_directory
    setup_test_protocol_config
    @config_loader = create_test_config_loader(@temp_dir)
    @delegator = Ace::Support::Nav::Organisms::CommandDelegator.new(config_loader: @config_loader)
  end

  def teardown
    cleanup_temp_directory(@temp_dir)
  end

  def setup_test_protocol_config
    protocols_dir = File.join(@temp_dir, ".ace", "protocols")
    FileUtils.mkdir_p(protocols_dir)

    # Create cmd-type protocol config
    protocol_config = {
      "protocol" => "test-cmd",
      "type" => "cmd",
      "name" => "Test Command",
      "command_template" => "echo %{ref}",
      "pass_through_options" => ["--path", "--content"]
    }

    File.write(
      File.join(protocols_dir, "test-cmd.yml"),
      protocol_config.to_yaml
    )
  end

  def test_parse_uri_extracts_protocol_and_reference
    protocol, reference = @delegator.send(:parse_uri, "test-cmd://my-resource")

    assert_equal "test-cmd", protocol
    assert_equal "my-resource", reference
  end

  def test_parse_uri_handles_empty_reference
    protocol, reference = @delegator.send(:parse_uri, "test-cmd://")

    assert_equal "test-cmd", protocol
    assert_equal "", reference
  end

  def test_parse_uri_raises_on_invalid_format
    error = assert_raises(ArgumentError) do
      @delegator.send(:parse_uri, "invalid-uri-format")
    end

    assert_match(/Invalid URI format/, error.message)
  end

  def test_build_command_substitutes_reference
    template = "ace-task %{ref}"
    reference = "083"
    options = {}
    config = {"pass_through_options" => []}

    command_parts = @delegator.send(:build_command, template, reference, options, config)

    assert_equal ["ace-task", "083"], command_parts
  end

  def test_build_command_adds_pass_through_options
    template = "ace-task %{ref}"
    reference = "083"
    options = {path: true, content: true}
    config = {"pass_through_options" => ["--path", "--content"]}

    command_parts = @delegator.send(:build_command, template, reference, options, config)

    assert_includes command_parts, "--path"
    assert_includes command_parts, "--content"
  end

  def test_build_command_filters_non_pass_through_options
    template = "ace-task %{ref}"
    reference = "083"
    options = {path: true, verbose: true}
    config = {"pass_through_options" => ["--path"]}

    command_parts = @delegator.send(:build_command, template, reference, options, config)

    assert_includes command_parts, "--path"
    refute_includes command_parts, "--verbose"
  end

  def test_build_command_handles_options_with_values
    template = "ace-task %{ref}"
    reference = "083"
    options = {format: "json"}
    config = {"pass_through_options" => ["--format"]}

    command_parts = @delegator.send(:build_command, template, reference, options, config)

    assert_includes command_parts, "--format"
    assert_includes command_parts, "json"
  end

  def test_delegate_raises_on_non_cmd_protocol
    # Create a file-type protocol
    protocol_config = {
      "protocol" => "file-proto",
      "type" => "file",
      "extensions" => [".md"]
    }

    protocols_dir = File.join(@temp_dir, ".ace", "protocols")
    File.write(
      File.join(protocols_dir, "file-proto.yml"),
      protocol_config.to_yaml
    )

    error = assert_raises(ArgumentError) do
      @delegator.delegate("file-proto://resource", {})
    end

    assert_match(/not a cmd-type protocol/, error.message)
  end

  def test_delegate_raises_on_missing_command_template
    # Create cmd protocol without command_template
    protocol_config = {
      "protocol" => "incomplete",
      "type" => "cmd"
    }

    protocols_dir = File.join(@temp_dir, ".ace", "protocols")
    File.write(
      File.join(protocols_dir, "incomplete.yml"),
      protocol_config.to_yaml
    )

    error = assert_raises(ArgumentError) do
      @delegator.delegate("incomplete://resource", {})
    end

    assert_match(/missing command_template/, error.message)
  end

  def test_execute_command_returns_zero_on_success
    # Mock system call to return true
    delegator = Ace::Support::Nav::Organisms::CommandDelegator.new(config_loader: @config_loader)

    def delegator.system(*args)
      true
    end

    exit_code = delegator.send(:execute_command, ["true"])

    assert_equal 0, exit_code
  end

  def test_execute_command_returns_one_on_failure
    # Use a real command that fails to test exit code handling
    # 'false' command exists on all Unix systems and returns exit code 1
    delegator = Ace::Support::Nav::Organisms::CommandDelegator.new(config_loader: @config_loader)

    exit_code = delegator.send(:execute_command, ["false"])

    assert_equal 1, exit_code
  end

  def test_execute_command_returns_one_when_command_not_found
    # Mock system call to return nil (command not found)
    delegator = Ace::Support::Nav::Organisms::CommandDelegator.new(config_loader: @config_loader)

    def delegator.system(*args)
      nil
    end

    stderr_output = capture_io do
      exit_code = delegator.send(:execute_command, ["nonexistent-command"])
      assert_equal 1, exit_code
    end

    assert_match(/Command not found/, stderr_output[1])
  end

  def test_delegate_with_real_echo_command
    # Test with a real command that exists on all systems
    protocol_config = {
      "protocol" => "echo-test",
      "type" => "cmd",
      "command_template" => "echo %{ref}",
      "pass_through_options" => []
    }

    protocols_dir = File.join(@temp_dir, ".ace", "protocols")
    File.write(
      File.join(protocols_dir, "echo-test.yml"),
      protocol_config.to_yaml
    )

    # Reload config loader to pick up new protocol
    @config_loader = create_test_config_loader(@temp_dir)
    delegator = Ace::Support::Nav::Organisms::CommandDelegator.new(config_loader: @config_loader)

    # The echo command will output to STDOUT, which we can't easily capture
    # since system() inherits file descriptors. Just verify it succeeds.
    exit_code = delegator.delegate("echo-test://hello-world", {})
    assert_equal 0, exit_code
  end
end
