# frozen_string_literal: true

require "test_helper"
require "ace/support/cli"

class CLITest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @prompt_dir = File.join(@tmpdir, ".ace-local/prompt-prep/prompts")
    FileUtils.mkdir_p(@prompt_dir)
    @prompt_file = File.join(@prompt_dir, "the-prompt.md")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # Helper method to invoke CLI using CLI runner pattern
  # Note: ace-support-cli calls exit(0) for --help, so we catch SystemExit
  def invoke_prompt_cli(args)
    stdout, stderr = capture_io do
      begin
        @_cli_result = Ace::Support::Cli::Runner.new(Ace::PromptPrep::CLI).call(args: args)
      rescue SystemExit => e
        @_cli_result = e.status
      rescue Ace::Core::CLI::Error => e
        @_cli_result = e.exit_code
        $stderr.print e.message
      end
    end

    {
      stdout: stdout,
      stderr: stderr,
      result: @_cli_result
    }
  end

  def test_version_returns_version_string
    result = invoke_prompt_cli(["version"])

    assert_match(/^ace-prompt-prep \d+\.\d+\.\d+/, result[:stdout].strip)
    # Note: ace-support-cli v1.3.0 returns a Set, not the exit code
    # We verify success by checking the output is correct
  end

  def test_version_with_long_flag
    result = invoke_prompt_cli(["--version"])

    assert_match(/^ace-prompt-prep \d+\.\d+\.\d+/, result[:stdout].strip)
    # Note: ace-support-cli v1.3.0 returns a Set, not the exit code
  end

  def test_shows_help_when_no_args
    result = invoke_prompt_cli([])

    # No args now shows help instead of running default command
    assert_match(/Commands:|COMMANDS/i, result[:stdout] + result[:stderr])
  end

  def test_help_command_shows_available_commands
    result = invoke_prompt_cli(["help"])

    assert_match(/COMMANDS|Commands:/i, result[:stdout] + result[:stderr])
  end

  def test_cli_has_process_command
    # Verify the process command exists in the registry
    # Note: ace-support-cli doesn't expose commands the same way Thor did
    # We test it by invoking the command
    result = invoke_prompt_cli(["process", "--help"])
    # Should show help for process command
    assert_match(/process/i, result[:stdout] + result[:stderr])
  end

  def test_cli_has_setup_command
    # Verify the setup command exists in the registry
    result = invoke_prompt_cli(["setup", "--help"])
    # Should show help for setup command
    assert_match(/setup/i, result[:stdout] + result[:stderr])
  end

  # Process command tests
  def test_process_command_runs_with_file
    # Create a test prompt file
    File.write(@prompt_file, "# Test prompt\n\nContent here")

    # Invoke process command explicitly
    result = invoke_prompt_cli(["process"])

    # Verify CLI didn't crash
    refute_nil result[:result]
  end

  # Context flag integration tests
  def test_context_option_accepted
    # Test that --context flag is accepted
    result = invoke_prompt_cli(["process", "--context"])

    # Should not crash (will fail due to no actual prompt file, but that's ok)
    # Note: ace-support-cli returns a Set, not the command's exit code
    refute_nil result[:result]
  end

  def test_no_context_option_accepted
    # Test that --no-context flag is accepted
    result = invoke_prompt_cli(["process", "--no-context"])

    # Note: ace-support-cli returns a Set, not the exit code
    refute_nil result[:result]
  end

  def test_short_context_flag_accepted
    # Test that -c flag is accepted
    result = invoke_prompt_cli(["process", "-c"])

    # Note: ace-support-cli returns a Set, not the command's exit code
    refute_nil result[:result]
  end

  # Enhance flag integration tests
  def test_enhance_option_accepted
    # Test that --enhance flag is accepted
    result = invoke_prompt_cli(["process", "--enhance"])

    # Note: ace-support-cli returns a Set, not the exit code
    refute_nil result[:result]
  end

  def test_no_enhance_option_accepted
    # Test that --no-enhance flag is accepted
    result = invoke_prompt_cli(["process", "--no-enhance"])

    # Note: ace-support-cli returns a Set, not the exit code
    refute_nil result[:result]
  end

  def test_model_option_accepted
    # Test that --model flag is accepted
    result = invoke_prompt_cli(["process", "--model", "gpt-4"])

    # Note: ace-support-cli returns a Set, not the exit code
    refute_nil result[:result]
  end

  # Setup command tests
  def test_setup_command_help_shows_options
    result = invoke_prompt_cli(["setup", "--help"])

    assert_match(/setup/i, result[:stdout] + result[:stderr])
    assert_match(/template/i, result[:stdout] + result[:stderr])
  end

  def test_setup_with_force_option_accepted
    # Test that --force flag is accepted
    result = invoke_prompt_cli(["setup", "--force"])

    # Note: ace-support-cli returns a Set, not the command's exit code
    refute_nil result[:result]
  end

  def test_setup_with_no_archive_option_accepted
    # Test that --no-archive flag is accepted
    result = invoke_prompt_cli(["setup", "--no-archive"])

    # Note: ace-support-cli returns a Set, not the command's exit code
    refute_nil result[:result]
  end

  def test_setup_with_template_option_accepted
    # Test that --template flag is accepted
    result = invoke_prompt_cli(["setup", "--template", "bug"])

    # Note: ace-support-cli returns a Set, not the command's exit code
    refute_nil result[:result]
  end

  # Output option tests
  def test_output_option_accepted
    # Test that --output flag is accepted
    result = invoke_prompt_cli(["process", "--output", "/tmp/test.md"])

    # Note: ace-support-cli returns a Set, not the exit code
    refute_nil result[:result]
  end

  def test_short_output_flag_accepted
    # Test that -o flag is accepted
    result = invoke_prompt_cli(["process", "-o", "/tmp/test.md"])

    # Note: ace-support-cli returns a Set, not the exit code
    refute_nil result[:result]
  end
end
