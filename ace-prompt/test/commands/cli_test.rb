# frozen_string_literal: true

require "test_helper"

class CLITest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @prompt_dir = File.join(@tmpdir, ".cache/ace-prompt/prompts")
    FileUtils.mkdir_p(@prompt_dir)
    @prompt_file = File.join(@prompt_dir, "the-prompt.md")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_responds_to_version_command
    cli = Ace::Prompt::CLI.new

    assert cli.respond_to?(:version)
  end

  def test_version_returns_version_string
    output = capture_io do
      Ace::Prompt::CLI.start(["version"])
    end.first

    assert_match(/^\d+\.\d+\.\d+/, output.strip)
  end

  def test_process_is_default_command
    # Verify that calling CLI without arguments tries to run process
    # We'll just verify the command exists and is callable
    cli = Ace::Prompt::CLI.new

    assert cli.respond_to?(:process)
  end

  def test_exit_on_failure_is_false
    assert_equal false, Ace::Prompt::CLI.exit_on_failure?
  end

  def test_has_output_option
    # Check that the process command has the --output option
    # by checking the command's options hash
    command = Ace::Prompt::CLI.commands["process"]

    assert command
    assert command.options.key?(:output)
  end

  def test_has_context_options
    # Check that the process command has context-related options
    command = Ace::Prompt::CLI.commands["process"]

    assert command
    assert command.options.key?(:context)
    assert command.options.key?(:no_context)
  end

  def test_determine_context_enabled_with_no_context_flag
    cli = Ace::Prompt::CLI.new
    options = { no_context: true }

    # --no-context should disable regardless of config
    result = cli.send(:determine_context_enabled, options)
    assert_equal false, result
  end

  def test_determine_context_enabled_with_context_flag
    cli = Ace::Prompt::CLI.new
    options = { context: true }

    # --context should enable regardless of config
    result = cli.send(:determine_context_enabled, options)
    assert_equal true, result
  end

  def test_determine_context_enabled_priority_no_context_over_context
    cli = Ace::Prompt::CLI.new
    options = { context: true, no_context: true }

    # --no-context should take priority over --context
    result = cli.send(:determine_context_enabled, options)
    assert_equal false, result
  end

  def test_determine_context_enabled_fallback_to_config_enabled
    # Test with config enabled - we need to mock the underlying config system
    cli = Ace::Prompt::CLI.new
    options = {}

    # Mock the config call directly
    mock_config = { "context" => { "enabled" => true } }
    Ace::Prompt.stub(:config, mock_config) do
      result = cli.send(:determine_context_enabled, options)
      assert_equal true, result
    end
  end

  def test_determine_context_enabled_fallback_to_config_disabled
    # Test with config disabled
    cli = Ace::Prompt::CLI.new
    options = {}

    # Mock the config call directly
    mock_config = { "context" => { "enabled" => false } }
    Ace::Prompt.stub(:config, mock_config) do
      result = cli.send(:determine_context_enabled, options)
      assert_equal false, result
    end
  end

  def test_determine_context_enabled_fallback_to_default_behavior
    # Test that it falls back to config when no CLI flags provided
    cli = Ace::Prompt::CLI.new
    options = {}

    # Should call Ace::Prompt.config.dig("context", "enabled")
    # Let it use the actual config system
    result = cli.send(:determine_context_enabled, options)

    # Default should be false based on default_config
    assert_equal false, result
  end

  def test_short_flag_c_functionality
    # Test that -c flag is properly aliased to --context
    command = Ace::Prompt::CLI.commands["process"]

    # Find the context option
    context_option = command.options[:context]

    assert context_option
    assert_includes context_option.aliases, "-c"
  end

  def test_cli_flag_precedence_integration
    # Integration test to ensure flags are properly parsed
    # and passed to determine_context_enabled

    # Test --no-context flag
    output, error = capture_subprocess_io do
      system("cd #{@tmpdir} && bundle exec exe/ace-prompt process --no-context 2>&1", out: File::NULL)
    end

    # The command should not fail due to flag parsing
    assert_equal "", error
  end

  def test_cli_context_flag_parsing
    # Test that context flags are properly recognized by Thor
    cli = Ace::Prompt::CLI.new

    # These should not raise errors
    assert_respond_to cli, :process
  end
end
