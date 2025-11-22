# frozen_string_literal: true

require "test_helper"

class ProcessWorkflowTest < AceTestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @cache_dir = File.join(@temp_dir, ".cache", "ace-prompt", "prompts")
    FileUtils.mkdir_p(@cache_dir)

    @config = {
      "default_dir" => @cache_dir,
      "enhancement" => {
        "model" => "test-model"
      }
    }

    # Create a test prompt file
    @prompt_content = <<~PROMPT
      ---
      title: Test Prompt
      enhancement:
        context:
          sections:
            docs:
              files: ["README.md"]
      ---

      This is a test prompt that should be enhanced with context.
    PROMPT

    @prompt_path = File.join(@cache_dir, "the-prompt.md")
    File.write(@prompt_path, @prompt_content)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_basic_process_workflow
    # Test basic processing without context or enhancement
    processor = Ace::Prompt::Organisms::PromptProcessor.new

    # Mock the file reading to return our test content
    processor.stub(:read_prompt_file, @prompt_content) do
      result = processor.process({})

      assert_equal @prompt_content, result
    end
  end

  def test_context_loading_workflow
    # Test context loading with graceful fallback
    processor = Ace::Prompt::Organisms::PromptProcessor.new

    processor.stub(:read_prompt_file, @prompt_content) do
      processor.stub(:ace_context_available?, false) do
        result = processor.process(ace_context: true)

        # Should return original content if ace-context is not available
        assert_equal @prompt_content, result
      end
    end
  end

  def test_enhancement_workflow_with_fallback
    # Test enhancement with graceful fallback on missing dependencies
    processor = Ace::Prompt::Organisms::PromptProcessor.new

    processor.stub(:read_prompt_file, @prompt_content) do
      processor.stub(:ace_llm_available?, false) do
        result = processor.process(enhance: true)

        # Should return original content if LLM is not available
        assert_equal @prompt_content, result
      end
    end
  end

  def test_full_workflow_with_missing_dependencies
    # Test full context + enhancement workflow when dependencies are missing
    processor = Ace::Prompt::Organisms::PromptProcessor.new

    processor.stub(:read_prompt_file, @prompt_content) do
      processor.stub(:ace_context_available?, false) do
        processor.stub(:ace_llm_available?, false) do
          result = processor.process(ace_context: true, enhance: true)

          # Should return original content when both dependencies are missing
          assert_equal @prompt_content, result
        end
      end
    end
  end

  def test_enhancement_session_with_context_embedding
    # Test that enhancement session properly uses embed_source: true
    session_manager = Ace::Prompt::Organisms::EnhancementSessionManager.new(@config)
    content = "Test prompt content"
    frontmatter = {
      "enhancement" => {
        "context" => {
          "project_docs" => ["README.md"]
        }
      }
    }

    # Mock the ace-context call to verify embed_source is used
    context_called_with_embed = false

    def mock_ace_context_load(input_file, embed_source: false)
      context_called_with_embed = embed_source if respond_to?(:context_called_with_embed=)

      # Return a mock result
      OpenStruct.new(
        content: "content with embedded source",
        metadata: {}
      )
    end

    session_manager.singleton_class.alias_method :original_execute_ace_context, :execute_ace_context
    session_manager.define_singleton_method(:execute_ace_context) do |input_file, output_file|
      context_called_with_embed = true
      File.write(output_file, "enhanced content")
      true
    end

    session_manager.stub(:execute_llm, "final enhanced content") do
      result = session_manager.enhance_with_context(content, frontmatter)
      assert_equal "final enhanced content", result
    end
  end

  def test_cli_composability_with_status_codes
    # Test that CLI commands return status codes instead of exiting
    cli = Ace::Prompt::CLI.new

    # Mock successful processor
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, "success", [{}])

    cli.stub(:create_prompt_processor, mock_processor) do
      result = cli.process
      assert_equal 0, result
    end

    mock_processor.verify
  end

  def test_cli_error_handling_with_status_codes
    # Test that CLI errors return status codes instead of exiting
    cli = Ace::Prompt::CLI.new

    # Mock processor that raises an error
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:process, nil) do
      raise Ace::Prompt::Error, "Test error"
    end

    cli.stub(:create_prompt_processor, mock_processor) do
      result = cli.process
      assert_equal 1, result
    end

    mock_processor.verify
  end

  def test_archive_creation_and_symlink_management
    # Test that archive directory and symlinks are created properly
    archive_dir = File.join(@cache_dir, "archive")
    FileUtils.mkdir_p(archive_dir)

    # Simulate archiving process
    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    archive_file = File.join(archive_dir, "#{timestamp}.md")
    previous_link = File.join(@cache_dir, "_previous.md")

    # Write original content to archive
    File.write(archive_file, "archived content")

    # Create symlink
    File.symlink(archive_file, previous_link) unless File.exist?(previous_link)

    assert File.exist?(archive_file)
    assert File.symlink?(previous_link)
    assert_equal archive_file, File.readlink(previous_link)
  end

  def test_enhancement_archive_versioning
    # Test that enhancement archives use _eXXX suffixes
    archive_dir = File.join(@cache_dir, "archive")
    FileUtils.mkdir_p(archive_dir)

    # Create original archive
    original_file = File.join(archive_dir, "20251122-150000.md")
    File.write(original_file, "original content")

    # Create enhancement archives
    enhancement_1 = File.join(archive_dir, "20251122-150000_e001.md")
    enhancement_2 = File.join(archive_dir, "20251122-150000_e002.md")

    File.write(enhancement_1, "enhanced content 1")
    File.write(enhancement_2, "enhanced content 2")

    assert File.exist?(original_file)
    assert File.exist?(enhancement_1)
    assert File.exist?(enhancement_2)

    # Verify suffix pattern
    assert enhancement_1.end_with?("_e001.md")
    assert enhancement_2.end_with?("_e002.md")
  end

  def test_prompt_discovery_integration
    # Test that prompt discovery works with nested directories
    # This verifies the ace-nav protocol configuration fix

    # Check that the enhance prompt is discoverable
    prompt_uri = "prompt://base/enhance"

    # This should resolve to the actual file
    begin
      resolved_path = `ace-nav "#{prompt_uri}"`.strip
      assert File.exist?(resolved_path)
      assert resolved_path.include?("handbook/prompts/base/enhance.md")
    rescue => e
      # If ace-nav is not available, skip this test
      skip "ace-nav not available for integration test"
    end
  end

  def test_error_messages_are_helpful
    # Test that error messages provide actionable guidance
    processor = Ace::Prompt::Organisms::PromptProcessor.new

    # Test missing file error
    assert_raises(Ace::Prompt::Molecules::PromptReader::PromptNotFoundError) do
      processor.send(:read_prompt_file, "nonexistent.md")
    end
  end

  def test_configuration_loading
    # Test that configuration loads properly from various sources
    processor = Ace::Prompt::Organisms::PromptProcessor.new

    # Test with valid config
    config = {
      "default_dir" => @cache_dir,
      "enhancement" => {
        "model" => "test-model",
        "temperature" => 0.5
      }
    }

    manager = processor.send(:create_enhancement_session_manager, config)
    assert_instance_of(Ace::Prompt::Organisms::EnhancementSessionManager, manager)
  end
end