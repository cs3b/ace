# frozen_string_literal: true

require "test_helper"

class CLITest < AceTestCase
  def setup
    @cli = Ace::Prompt::CLI.new
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_process_command_success
    # Mock the processor
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, "test output", [{}])

    @cli.stub(:create_prompt_processor, mock_processor) do
      result = @cli.process

      assert_equal 0, result
      mock_processor.verify
    end
  end

  def test_process_command_with_options
    options = { ace_context: true, enhance: true }
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, "enhanced output", [options])

    @cli.stub(:create_prompt_processor, mock_processor) do
      @cli.stub(:options, options) do
        result = @cli.process

        assert_equal 0, result
        mock_processor.verify
      end
    end
  end

  def test_process_command_handles_prompt_error
    error = Ace::Prompt::Error.new("Test error")
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, nil) { raise error }

    @cli.stub(:create_prompt_processor, mock_processor) do
      result = @cli.process

      assert_equal 1, result
    end
  end

  def test_process_command_handles_standard_error
    error = StandardError.new("Unexpected error")
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, nil) { raise error }

    @cli.stub(:create_prompt_processor, mock_processor) do
      result = @cli.process

      assert_equal 1, result
    end
  end

  def test_process_command_with_debug_environment
    ENV["DEBUG"] = "true"

    error = StandardError.new("Debug error")
    error.set_backtrace(["line1", "line2"])

    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, nil) { raise error }

    @cli.stub(:create_prompt_processor, mock_processor) do
      result = @cli.process

      assert_equal 1, result
    end

    ENV.delete("DEBUG")
  end

  def test_setup_command_success
    mock_initializer = Minitest::Mock.new
    mock_initializer.expect(:setup, "/path/to/prompt", [{ template_uri: nil, force: false }])

    @cli.stub(:create_prompt_initializer, mock_initializer) do
      result = @cli.setup

      assert_equal 0, result
      assert_match(/Prompt initialized: \/path\/to\/prompt/, captured_output)
      mock_initializer.verify
    end
  end

  def test_setup_command_with_options
    options = { template: "tmpl://custom/template", force: true }
    mock_initializer = Minitest::Mock.new
    mock_initializer.expect(:setup, "/custom/path", [{ template_uri: "tmpl://custom/template", force: true }])

    @cli.stub(:create_prompt_initializer, mock_initializer) do
      @cli.stub(:options, options) do
        result = @cli.setup

        assert_equal 0, result
        mock_initializer.verify
      end
    end
  end

  def test_setup_command_handles_error
    error = Ace::Prompt::Error.new("Setup failed")
    mock_initializer = Minitest::Mock.new
    mock_initializer.expect(:setup, nil) { raise error }

    @cli.stub(:create_prompt_initializer, mock_initializer) do
      result = @cli.setup

      assert_equal 1, result
    end
  end

  def test_reset_command_success
    mock_initializer = Minitest::Mock.new
    mock_initializer.expect(:reset, "/path/to/reset", [{ template_uri: nil }])

    @cli.stub(:create_prompt_initializer, mock_initializer) do
      result = @cli.reset

      assert_equal 0, result
      assert_match(/Prompt reset: \/path\/to\/reset/, captured_output)
      assert_match(/Previous prompt archived/, captured_output)
      mock_initializer.verify
    end
  end

  def test_reset_command_with_template
    options = { template: "tmpl://custom/template" }
    mock_initializer = Minitest::Mock.new
    mock_initializer.expect(:reset, "/custom/reset", [{ template_uri: "tmpl://custom/template" }])

    @cli.stub(:create_prompt_initializer, mock_initializer) do
      @cli.stub(:options, options) do
        result = @cli.reset

        assert_equal 0, result
        mock_initializer.verify
      end
    end
  end

  def test_reset_command_handles_error
    error = Ace::Prompt::Error.new("Reset failed")
    mock_initializer = Minitest::Mock.new
    mock_initializer.expect(:reset, nil) { raise error }

    @cli.stub(:create_prompt_initializer, mock_initializer) do
      result = @cli.reset

      assert_equal 1, result
    end
  end

  def test_enhance_command_success
    options = { ace_context: true, task: 117 }
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, "enhanced content", [ace_context: true, task: 117, enhance: true])

    @cli.stub(:create_prompt_processor, mock_processor) do
      @cli.stub(:options, options) do
        result = @cli.enhance

        assert_equal 0, result
        mock_processor.verify
      end
    end
  end

  def test_enhance_command_with_default_options
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, "enhanced content", [enhance: true])

    @cli.stub(:create_prompt_processor, mock_processor) do
      result = @cli.enhance

      assert_equal 0, result
      mock_processor.verify
    end
  end

  def test_enhance_command_handles_error
    error = Ace::Prompt::Error.new("Enhancement failed")
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, nil) { raise error }

    @cli.stub(:create_prompt_processor, mock_processor) do
      result = @cli.enhance

      assert_equal 1, result
    end
  end

  def test_exit_on_failure_returns_true
    assert_equal true, Ace::Prompt::CLI.exit_on_failure?
  end

  def test_default_command_is_process
    assert_equal :process, Ace::Prompt::CLI.default_task
  end

  private

  def captured_output
    # Capture stdout for testing output messages
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end