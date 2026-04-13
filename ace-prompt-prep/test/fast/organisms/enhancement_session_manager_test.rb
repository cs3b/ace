# frozen_string_literal: true

require "test_helper"
require "open3"
require "ostruct"

class EnhancementSessionManagerTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_prepare_session_no_frontmatter
    # System prompt with no frontmatter - returns as-is
    system_prompt = "You are a helpful assistant."
    prompt_path = File.join(@test_dir, "system.md")
    File.write(prompt_path, system_prompt)

    result = Ace::PromptPrep::Organisms::EnhancementSessionManager.prepare_session(prompt_path)

    assert_equal system_prompt, result[:content]
    refute result[:context_loaded]
    assert_nil result[:error]
  end

  def test_prepare_session_frontmatter_without_context
    # System prompt with frontmatter but no context key - returns body only
    system_prompt = <<~MD
      ---
      title: Test Prompt
      category: base
      ---

      You are a helpful assistant.
    MD
    prompt_path = File.join(@test_dir, "system.md")
    File.write(prompt_path, system_prompt)

    result = Ace::PromptPrep::Organisms::EnhancementSessionManager.prepare_session(prompt_path)

    # Should return body without frontmatter
    assert_includes result[:content], "You are a helpful assistant."
    refute_includes result[:content], "title: Test Prompt"
    refute result[:context_loaded]
    assert_nil result[:error]
  end

  def test_prepare_session_returns_error_when_file_not_found
    result = Ace::PromptPrep::Organisms::EnhancementSessionManager.prepare_session("/nonexistent/path.md")

    assert_nil result[:content]
    refute result[:context_loaded]
    assert_equal "Failed to load system prompt", result[:error]
  end

  def test_prepare_session_with_context_frontmatter_processes_via_ace_context
    # Skip if ace-bundle not available
    begin
      require "ace/bundle"
    rescue LoadError
      skip "ace-bundle not available for testing"
    end

    # Create a system prompt with context frontmatter
    system_prompt = <<~MD
      ---
      context:
        presets:
          - project
      ---

      You are a helpful assistant.
    MD
    prompt_path = File.join(@test_dir, "system.md")
    File.write(prompt_path, system_prompt)

    # Stub ace-bundle to avoid actual preset loading
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      # Create a mock context data object
      mock_context_data = Object.new
      def mock_context_data.content
        "Loaded context content"
      end

      Ace::Bundle.stub :load_preset, mock_context_data do
        result = Ace::PromptPrep::Organisms::EnhancementSessionManager.prepare_session(prompt_path)

        # Context was loaded
        assert result[:context_loaded]
        assert_nil result[:error]
        assert_includes result[:content], "Loaded context content"
        assert_includes result[:content], "You are a helpful assistant."
      end
    end
  end

  def test_prepare_session_fallback_when_context_loading_fails
    # Skip if ace-bundle not available
    begin
      require "ace/bundle"
    rescue LoadError
      skip "ace-bundle not available for testing"
    end

    # Create a system prompt with context frontmatter
    system_prompt = <<~MD
      ---
      context:
        presets:
          - project
      ---

      You are a helpful assistant.
    MD
    prompt_path = File.join(@test_dir, "system.md")
    File.write(prompt_path, system_prompt)

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      # Stub ace-bundle to raise an error (simulates API failure)
      # Also stub CLI fallback to fail
      Ace::Bundle.stub :load_preset, ->(*_args) { raise StandardError, "Context loading failed" } do
        Open3.stub :capture3, ["", "CLI failed", OpenStruct.new(success?: false)] do
          result = Ace::PromptPrep::Organisms::EnhancementSessionManager.prepare_session(prompt_path)

          # Should fall back to body without context
          refute result[:context_loaded]
          assert_equal "No preset content loaded", result[:error]
          # Still has content (the body)
          assert_includes result[:content], "You are a helpful assistant."
        end
      end
    end
  end

  def test_prepare_session_fallback_when_ace_context_not_available
    # Skip this test if ace-bundle IS available, since we can't unload it
    # and require is idempotent (won't re-require an already-loaded gem)
    begin
      require "ace/bundle"
      skip "Cannot test LoadError fallback when ace-bundle is already loaded"
    rescue LoadError
      # Good - ace-bundle is not available, so we can test the fallback
    end

    # Create a system prompt with context frontmatter
    system_prompt = <<~MD
      ---
      context:
        presets:
          - project
      ---

      You are a helpful assistant.
    MD
    prompt_path = File.join(@test_dir, "system.md")
    File.write(prompt_path, system_prompt)

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      result = Ace::PromptPrep::Organisms::EnhancementSessionManager.prepare_session(prompt_path)

      # Should fall back to body without context
      refute result[:context_loaded]
      assert_includes result[:error], "ace-bundle not available"
      # Still has content (the body)
      assert_includes result[:content], "You are a helpful assistant."
    end
  end

  def test_prepare_session_empty_context_result_falls_back
    # Skip if ace-bundle not available
    begin
      require "ace/bundle"
    rescue LoadError
      skip "ace-bundle not available for testing"
    end

    # Create a system prompt with context frontmatter
    system_prompt = <<~MD
      ---
      context:
        presets:
          - project
      ---

      You are a helpful assistant.
    MD
    prompt_path = File.join(@test_dir, "system.md")
    File.write(prompt_path, system_prompt)

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      # Create a mock context data object with empty content
      mock_context_data = Object.new
      def mock_context_data.content
        ""
      end

      # Stub API to return empty content, and CLI fallback to also fail
      Ace::Bundle.stub :load_preset, mock_context_data do
        Open3.stub :capture3, ["", "", OpenStruct.new(success?: false)] do
          result = Ace::PromptPrep::Organisms::EnhancementSessionManager.prepare_session(prompt_path)

          # Should fall back since context is empty
          refute result[:context_loaded]
          assert_equal "No preset content loaded", result[:error]
          # Still has content (the body)
          assert_includes result[:content], "You are a helpful assistant."
        end
      end
    end
  end
end
