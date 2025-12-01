# frozen_string_literal: true

require "test_helper"

class SetupResetCommandsTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @cli = Ace::Prompt::CLI.new
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # setup command tests
  def test_setup_command_creates_prompt
    # Stub the initializer to return successful result
    Ace::Prompt::Organisms::PromptInitializer.stub(:setup, lambda { |**_opts|
      { success: true, path: "/tmp/the-prompt.md", archive_path: nil }
    }) do
      output, _err = capture_io do
        result = @cli.setup
        assert_equal 0, result
      end

      assert_match(/Prompt initialized/, output)
      assert_match(/Path:/, output)
    end
  end

  def test_setup_command_archives_existing_prompt
    # Stub to return successful result with archive
    Ace::Prompt::Organisms::PromptInitializer.stub(:setup, lambda { |**_opts|
      { success: true, path: "/tmp/the-prompt.md", archive_path: "/tmp/archive/the-prompt-20250101.md" }
    }) do
      output, _err = capture_io do
        result = @cli.setup
        assert_equal 0, result
      end

      assert_match(/Prompt initialized/, output)
      assert_match(/Path:/, output)
      assert_match(/Archive:/, output)
    end
  end

  def test_setup_command_with_force_option
    # Stub to capture force flag
    force_passed = nil
    Ace::Prompt::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      force_passed = opts[:force]
      { success: true, path: "/tmp/the-prompt.md", skipped: false }
    }) do
      capture_io do
        @cli.options = { force: true }
        @cli.setup
      end

      assert force_passed
    end
  end

  def test_setup_command_with_custom_template
    # Stub to capture template_uri
    template_uri_passed = nil
    Ace::Prompt::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      template_uri_passed = opts[:template_uri]
      { success: true, path: "/tmp/the-prompt.md", skipped: false }
    }) do
      capture_io do
        @cli.options = { template: "tmpl://custom/template" }
        @cli.setup
      end

      assert_equal "tmpl://custom/template", template_uri_passed
    end
  end

  def test_setup_command_handles_failure
    # Stub to return failure
    Ace::Prompt::Organisms::PromptInitializer.stub(:setup, lambda { |**_opts|
      { success: false, path: nil, skipped: false, error: "Setup failed" }
    }) do
      _output, err = capture_io do
        result = @cli.setup
        assert_equal 1, result
      end

      assert_match(/Setup failed/, err)
    end
  end

  def test_setup_command_handles_exception
    # Stub to raise exception
    Ace::Prompt::Organisms::PromptInitializer.stub(:setup, ->(**_opts) { raise "Unexpected error" }) do
      _output, err = capture_io do
        result = @cli.setup
        assert_equal 1, result
      end

      assert_match(/Unexpected error/, err)
    end
  end

  def test_setup_command_with_no_archive_option
    # Stub to capture force flag (no_archive should be treated as force)
    force_passed = nil
    Ace::Prompt::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      force_passed = opts[:force]
      { success: true, path: "/tmp/the-prompt.md", archive_path: nil }
    }) do
      capture_io do
        @cli.options = { no_archive: true }
        @cli.setup
      end

      assert force_passed
    end
  end

  def test_setup_command_with_short_form_template
    # Stub to capture template_uri (short form should be passed through)
    template_uri_passed = nil
    Ace::Prompt::Organisms::PromptInitializer.stub(:setup, lambda { |**opts|
      template_uri_passed = opts[:template_uri]
      { success: true, path: "/tmp/the-prompt.md", archive_path: nil }
    }) do
      capture_io do
        @cli.options = { template: "bug" }
        @cli.setup
      end

      assert_equal "bug", template_uri_passed
    end
  end

  def test_default_template_uri_constant
    assert_equal "tmpl://the-prompt-base",
                 Ace::Prompt::Organisms::PromptInitializer::DEFAULT_TEMPLATE_URI
  end
end
