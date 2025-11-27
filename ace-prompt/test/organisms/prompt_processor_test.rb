# frozen_string_literal: true

require "test_helper"

class PromptProcessorTest < Ace::Prompt::TestCase
  def setup
    @processor = Ace::Prompt::Organisms::PromptProcessor.new
    @temp_dir = Dir.mktmpdir
    @config = {
      "default_dir" => @temp_dir
    }
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_process_basic_prompt_without_options
    # Create a basic prompt file
    prompt_content = "This is a test prompt"
    prompt_path = File.join(@temp_dir, "test.md")
    File.write(prompt_path, prompt_content)

    # Test basic processing
    result = @processor.process({})

    assert_equal prompt_content, result
  end

  def test_process_with_task_option
    # This would test task-specific prompt processing
    # For now, just test that it doesn't crash
    assert_raises(Ace::Prompt::Error) do
      @processor.process(task: 999999)
    end
  end

  def test_process_with_context_option
    # Test context loading - should gracefully handle missing ace-context
    prompt_content = "Test prompt with context"

    # Mock the prompt file
    @processor.stub :read_prompt_file, prompt_content do
      result = @processor.process(ace_context: true)
      # Should return the original content if context loading fails
      assert_equal prompt_content, result
    end
  end

  def test_process_with_enhance_option
    # Test enhancement - should gracefully handle missing dependencies
    prompt_content = "Test prompt for enhancement"

    # Mock the prompt file and enhancement process
    @processor.stub :read_prompt_file, prompt_content do
      @processor.stub :enhance_prompt, "enhanced content" do
        result = @processor.process(enhance: true)
        assert_equal "enhanced content", result
      end
    end
  end

  def test_read_prompt_file_missing
    assert_raises(Ace::Prompt::Molecules::PromptReader::PromptNotFoundError) do
      @processor.send(:read_prompt_file, "nonexistent.md")
    end
  end

  def test_enhance_prompt_success
    # Mock enhancement session manager
    enhanced_content = "Enhanced prompt content"
    mock_manager = Minitest::Mock.new
    mock_manager.expect(:enhance_with_context, enhanced_content, ["original", {}])

    @processor.stub :create_enhancement_session_manager, mock_manager do
      result = @processor.send(:enhance_prompt, "original", {})
      assert_equal enhanced_content, result
    end

    mock_manager.verify
  end

  def test_enhance_prompt_failure
    # Test graceful failure handling
    mock_manager = Minitest::Mock.new
    mock_manager.expect(:enhance_with_context, nil) do
      raise Ace::Prompt::Organisms::EnhancementSessionManager::EnhancementError, "Test error"
    end

    @processor.stub :create_enhancement_session_manager, mock_manager do
      result = @processor.send(:enhance_prompt, "original", {})
      assert_equal "original", result # Should fall back to original
    end
  end

  def test_create_enhancement_session_manager
    manager = @processor.send(:create_enhancement_session_manager, @config)
    assert_instance_of(Ace::Prompt::Organisms::EnhancementSessionManager, manager)
  end

  def test_process_with_both_context_and_enhance
    # Test full workflow with both options
    prompt_content = "Test prompt"

    # Mock both context loading and enhancement
    @processor.stub :read_prompt_file, prompt_content do
      @processor.stub :load_context, prompt_content do
        @processor.stub :enhance_prompt, "enhanced content" do
          result = @processor.process(ace_context: true, enhance: true)
          assert_equal "enhanced content", result
        end
      end
    end
  end

  def test_process_with_raw_option_skips_enhancement
    prompt_content = "Original prompt"

    @processor.stub :read_prompt_file, prompt_content do
      result = @processor.process(enhance: true, raw: true)
      assert_equal prompt_content, result # Should skip enhancement
    end
  end

  def test_process_with_no_context_skips_context_loading
    prompt_content = "Original prompt"

    @processor.stub :read_prompt_file, prompt_content do
      result = @processor.process(ace_context: true, no_context: true)
      assert_equal prompt_content, result # Should skip context
    end
  end
end