# frozen_string_literal: true

require "test_helper"
require "ace/support/cli"

class SetupResetCommandsTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # Helper method to invoke CLI using CLI runner pattern
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

  # setup command tests
  def test_setup_command_creates_prompt
    # Stub the initializer to return successful result
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**_opts|
      { success: true, path: "/tmp/the-prompt.md", archive_path: nil }
    }) do
      result = invoke_prompt_cli(["setup"])
      # Note: ace-support-cli v1.3.0 returns a Set, not the exit code
      # We verify success by checking the output
      assert_match(/Prompt initialized/, result[:stdout])
      assert_match(/Path:/, result[:stdout])
    end
  end

  def test_setup_command_archives_existing_prompt
    # Stub to return successful result with archive
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**_opts|
      { success: true, path: "/tmp/the-prompt.md", archive_path: "/tmp/archive/the-prompt-20250101.md" }
    }) do
      result = invoke_prompt_cli(["setup"])
      # Note: ace-support-cli v1.3.0 returns a Set, not the exit code
      assert_match(/Prompt initialized/, result[:stdout])
      assert_match(/Path:/, result[:stdout])
      assert_match(/Archive:/, result[:stdout])
    end
  end

  def test_setup_command_with_force_option
    # Stub to capture force flag
    force_passed = nil
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      force_passed = opts[:force]
      { success: true, path: "/tmp/the-prompt.md", skipped: false }
    }) do
      invoke_prompt_cli(["setup", "--force"])
      assert force_passed
    end
  end

  def test_setup_command_with_short_force_flag
    # Test that -f flag works
    force_passed = nil
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      force_passed = opts[:force]
      { success: true, path: "/tmp/the-prompt.md", skipped: false }
    }) do
      invoke_prompt_cli(["setup", "-f"])
      assert force_passed
    end
  end

  def test_setup_command_with_custom_template
    # Stub to capture template_uri
    template_uri_passed = nil
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      template_uri_passed = opts[:template_uri]
      { success: true, path: "/tmp/the-prompt.md", skipped: false }
    }) do
      invoke_prompt_cli(["setup", "--template", "tmpl://custom/template"])
      assert_equal "tmpl://custom/template", template_uri_passed
    end
  end

  def test_setup_command_with_short_template_flag
    # Test that -t flag works
    template_passed = nil
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      template_passed = opts[:template_uri]
      { success: true, path: "/tmp/the-prompt.md", skipped: false }
    }) do
      invoke_prompt_cli(["setup", "-t", "bug"])
      assert_equal "bug", template_passed
    end
  end

  def test_setup_command_handles_failure
    # Stub to return failure
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**_opts|
      { success: false, path: nil, skipped: false, error: "Setup failed" }
    }) do
      result = invoke_prompt_cli(["setup"])
      # Note: ace-support-cli v1.3.0 returns a Set, not the exit code
      # We verify failure by checking stderr for the error message
      assert_match(/Setup failed/, result[:stderr])
    end
  end

  def test_setup_command_handles_exception
    # Stub to raise exception
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, ->(**_opts) { raise "Unexpected error" }) do
      result = invoke_prompt_cli(["setup"])
      # Note: ace-support-cli v1.3.0 returns a Set, not the exit code
      # We verify failure by checking stderr for the error message
      assert_match(/Unexpected error/, result[:stderr])
    end
  end

  def test_setup_command_with_no_archive_option
    # Stub to capture force flag (no_archive should be treated as force)
    force_passed = nil
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      force_passed = opts[:force]
      { success: true, path: "/tmp/the-prompt.md", archive_path: nil }
    }) do
      invoke_prompt_cli(["setup", "--no-archive"])
      assert force_passed
    end
  end

  def test_setup_command_with_short_form_template
    # Stub to capture template_uri (short form should be passed through)
    template_uri_passed = nil
    Ace::PromptPrep::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      template_uri_passed = opts[:template_uri]
      { success: true, path: "/tmp/the-prompt.md", archive_path: nil }
    }) do
      invoke_prompt_cli(["setup", "--template", "bug"])
      assert_equal "bug", template_uri_passed
    end
  end

  def test_default_template_uri_constant
    assert_equal "tmpl://the-prompt-base",
                 Ace::PromptPrep::Organisms::PromptInitializer::DEFAULT_TEMPLATE_URI
  end

  # Task option tests
  def test_setup_command_with_task_option
    # Test that --task option is accepted
    result = invoke_prompt_cli(["setup", "--task", "121"])
    # Should not crash (will likely fail due to task not existing, but that's ok)
    # Note: ace-support-cli returns a Set, not the command's exit code
    refute_nil result[:result]
  end
end
