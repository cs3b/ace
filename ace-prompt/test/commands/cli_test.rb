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
end
