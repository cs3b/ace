# frozen_string_literal: true

require "test_helper"

class EnhancementSessionManagerTest < Ace::Prompt::TestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @config = {
      "default_dir" => @temp_dir,
      "enhancement" => {
        "model" => "test-model",
        "temperature" => 0.5
      }
    }
    @manager = Ace::Prompt::Organisms::EnhancementSessionManager.new(@config)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_enhance_with_context_success
    content = "Test prompt content"
    frontmatter = {
      "enhancement" => {
        "context" => {
          "project_docs" => ["readme.md"]
        }
      }
    }

    # Mock ace-context to return content with source embedding
    mock_context_result = Minitest::Mock.new
    mock_context_result.expect(:content, "enhanced content")
    mock_context_result.expect(:metadata, {})

    # Mock LLM query
    mock_llm_result = { text: "final enhanced content" }

    @manager.stub(:execute_ace_context, true) do
      @manager.stub(:execute_llm, mock_llm_result[:text]) do
        result = @manager.enhance_with_context(content, frontmatter)
        assert_equal "final enhanced content", result
      end
    end
  end

  def test_enhance_with_context_uses_embed_source_option
    content = "Test prompt content"
    frontmatter = {}

    # Test that embed_source: true is passed to ace-context
    context_file = nil
    @manager.stub(:create_user_context_file, "/tmp/user.context.md") do
      @manager.stub(:create_system_context_file, "/tmp/system.context.md") do
        @manager.stub(:execute_ace_context, true) do |input_file, output_file|
          context_file = input_file
          true
        end
        @manager.stub(:execute_llm, "enhanced") do
          result = @manager.enhance_with_context(content, frontmatter)

          # Verify context files were created and processed
          assert_equal "/tmp/user.context.md", context_file
          assert_equal "enhanced", result
        end
      end
    end
  end

  def test_create_user_context_file
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    content = "User prompt content"
    frontmatter = {
      "enhancement" => {
        "context" => {
          "sections" => {
            "docs" => {
              "files" => ["readme.md"]
            }
          }
        }
      }
    }

    context_path = @manager.send(:create_user_context_file, session_dir, content, frontmatter)

    assert File.exist?(context_path)
    context_content = File.read(context_path)

    # Should contain YAML frontmatter and user content
    assert_match(/description:/, context_content)
    assert_match(/context:/, context_content)
    assert_match(/User prompt content/, context_content)
  end

  def test_create_system_context_file
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    frontmatter = {
      "enhancement" => {
        "system_prompt" => "prompt://custom/system"
      }
    }

    context_path = @manager.send(:create_system_context_file, session_dir, frontmatter)

    assert File.exist?(context_path)
    context_content = File.read(context_path)

    # Should contain system prompt configuration
    assert_match(/Enhancement Instructions/, context_content)
    assert_match(/prompt:\/\/custom\/system/, context_content)
  end

  def test_create_system_context_file_with_default
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    frontmatter = {}

    context_path = @manager.send(:create_system_context_file, session_dir, frontmatter)

    assert File.exist?(context_path)
    context_content = File.read(context_path)

    # Should use default system prompt
    assert_match(/prompt:\/\/ace-prompt\/base\/enhance/, context_content)
  end

  def test_execute_ace_context_success
    input_file = File.join(@temp_dir, "input.md")
    output_file = File.join(@temp_dir, "output.md")

    # Create test input file
    File.write(input_file, "---\ntest: true\n---\n\nTest content")

    # Mock Ace::Context.load_file
    mock_result = Minitest::Mock.new
    mock_result.expect(:content, "processed content")
    mock_result.expect(:metadata, {})

    @manager.stub(:ace_context_load_with_embed_source, mock_result) do
      result = @manager.send(:execute_ace_context, input_file, output_file)

      assert_equal true, result
      assert_equal "processed content", File.read(output_file)
    end
  end

  def test_execute_ace_context_with_error
    input_file = File.join(@temp_dir, "input.md")
    output_file = File.join(@temp_dir, "output.md")

    # Mock Ace::Context.load_file with error
    mock_result = Minitest::Mock.new
    mock_result.expect(:metadata, { error: "Context processing failed" })

    assert_raises(Ace::Prompt::Organisms::EnhancementSessionManager::EnhancementError) do
      @manager.stub(:ace_context_load_with_embed_source, mock_result) do
        @manager.send(:execute_ace_context, input_file, output_file)
      end
    end
  end

  def test_execute_ace_context_handles_missing_ace_context_gracefully
    input_file = File.join(@temp_dir, "input.md")
    output_file = File.join(@temp_dir, "output.md")

    # Simulate missing ace-context gem
    @manager.stub(:ace_context_available?, false) do
      assert_raises(Ace::Prompt::Organisms::EnhancementSessionManager::EnhancementError) do
        @manager.send(:execute_ace_context, input_file, output_file)
      end
    end
  end

  def test_execute_llm_success
    user_prompt = "User prompt"
    system_prompt = "System prompt"
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    output_file = File.join(session_dir, "enhanced.md")

    # Mock Ace::LLM::QueryInterface.query
    mock_result = { text: "LLM enhanced content" }

    @manager.stub(:ace_llm_query, mock_result) do
      result = @manager.send(:execute_llm, user_prompt, system_prompt, session_dir)
      assert_equal "LLM enhanced content", result
    end
  end

  def test_execute_llm_handles_missing_ace_llm_gracefully
    user_prompt = "User prompt"
    system_prompt = "System prompt"
    session_dir = File.join(@temp_dir, "session")

    @manager.stub(:ace_llm_available?, false) do
      assert_raises(Ace::Prompt::Organisms::EnhancementSessionManager::EnhancementError) do
        @manager.send(:execute_llm, user_prompt, system_prompt, session_dir)
      end
    end
  end

  def test_resolve_model_with_config
    model = @manager.send(:resolve_model)
    assert_equal "test-model", model
  end

  def test_resolve_model_with_default
    config = { "default_dir" => @temp_dir }
    manager = Ace::Prompt::Organisms::EnhancementSessionManager.new(config)

    model = manager.send(:resolve_model)
    assert_equal "glite", model
  end

  def test_create_session_directory
    session_dir = @manager.send(:create_session_directory)

    assert Dir.exist?(session_dir)
    assert session_dir.end_with?("enhancement")
  end

  private

  def ace_context_load_with_embed_source(file)
    # Helper method to simulate Ace::Context.load_file(file, embed_source: true)
    content = File.read(file)
    mock_result = OpenStruct.new(content: content, metadata: {})
    mock_result
  end

  def ace_llm_query(model, user_prompt, options = {})
    # Helper method to simulate Ace::LLM::QueryInterface.query
    { text: "Mock LLM response" }
  end
end