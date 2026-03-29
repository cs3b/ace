# frozen_string_literal: true

require "test_helper"

class PromptEnhancerTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir

    # Create a mock system prompt file
    @system_prompt_path = File.join(@test_dir, "system-prompt.md")
    File.write(@system_prompt_path, "You are a prompt enhancer.")
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_returns_cached_content_when_available
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      content = "Original prompt"
      model = "role:prompt-enhance" # Default model
      system_prompt_uri = @system_prompt_path
      temperature = 0.3 # Default temperature

      # Read the system prompt content (cache key now uses content, not URI)
      system_prompt_content = File.read(@system_prompt_path)

      # Calculate cache key with all parameters (using resolved content)
      cache_key = Ace::PromptPrep::Molecules::EnhancementTracker.cache_key(
        content, model, system_prompt_content, temperature
      )
      cached_content = "Previously enhanced prompt"

      # Store in cache
      Ace::PromptPrep::Molecules::EnhancementTracker.store_cache(cache_key, cached_content)

      # Call enhancer with matching parameters
      result = Ace::PromptPrep::Organisms::PromptEnhancer.call(
        content: content,
        model: model,
        system_prompt_uri: system_prompt_uri,
        temperature: temperature
      )

      assert result[:enhanced]
      assert result[:cached]
      assert_equal cached_content, result[:content]
      assert_nil result[:error]
    end
  end

  def test_returns_original_when_system_prompt_fails_to_load
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      content = "Test prompt"

      result = Ace::PromptPrep::Organisms::PromptEnhancer.call(
        content: content,
        system_prompt_uri: "/nonexistent/path.md"
      )

      refute result[:enhanced]
      refute result[:cached]
      assert_equal content, result[:content]
      assert_equal "Failed to load system prompt", result[:error]
    end
  end

  def test_returns_original_when_ace_llm_not_available
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      content = "Test prompt"

      # Mock LoadError when trying to require ace/llm
      Ace::PromptPrep::Organisms::PromptEnhancer.stub :require, ->(_gem) { raise LoadError, "gem not found" } do
        result = Ace::PromptPrep::Organisms::PromptEnhancer.call(
          content: content,
          system_prompt_uri: @system_prompt_path
        )

        refute result[:enhanced]
        refute result[:cached]
        assert_equal content, result[:content]
        assert_equal "ace-llm not available", result[:error]
      end
    end
  end

  def test_passes_model_alias_to_llm_directly
    content = "Test prompt"

    # Skip if ace-llm not available
    begin
      require "ace/llm"
    rescue LoadError
      skip "ace-llm not available for testing"
    end

    # Mock the LLM query - ace-llm handles alias resolution internally
    mock_query = lambda { |model, _prompt, **_opts|
      # Model alias is passed directly; ace-llm resolves it
      assert_equal "role:prompt-enhance", model
      {text: "Enhanced content"}
    }

    Ace::LLM::QueryInterface.stub :query, mock_query do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
        result = Ace::PromptPrep::Organisms::PromptEnhancer.call(
          content: content,
          model: "role:prompt-enhance",
          system_prompt_uri: @system_prompt_path
        )

        assert result[:enhanced]
      end
    end
  end

  def test_uses_default_model_when_nil
    content = "Test prompt"

    begin
      require "ace/llm"
    rescue LoadError
      skip "ace-llm not available for testing"
    end

    # Mock to verify default model is used
    mock_query = lambda { |model, _prompt, **_opts|
      # Default role is used when nil
      assert_equal "role:prompt-enhance", model
      {text: "Enhanced content"}
    }

    Ace::LLM::QueryInterface.stub :query, mock_query do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
        Ace::PromptPrep::Organisms::PromptEnhancer.call(
          content: content,
          model: nil,
          system_prompt_uri: @system_prompt_path
        )
      end
    end
  end

  def test_handles_empty_llm_response
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      content = "Test prompt"

      begin
        require "ace/llm"
      rescue LoadError
        skip "ace-llm not available for testing"
      end

      # Mock empty response
      mock_query = ->(_model, _prompt, **_opts) { {text: ""} }

      Ace::LLM::QueryInterface.stub :query, mock_query do
        result = Ace::PromptPrep::Organisms::PromptEnhancer.call(
          content: content,
          system_prompt_uri: @system_prompt_path
        )

        refute result[:enhanced]
        assert_equal content, result[:content]
        assert_equal "Empty LLM response", result[:error]
      end
    end
  end

  def test_handles_llm_error
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      content = "Test prompt"

      begin
        require "ace/llm"
      rescue LoadError
        skip "ace-llm not available for testing"
      end

      # Mock LLM error
      mock_query = ->(_model, _prompt, **_opts) { raise StandardError, "API error" }

      Ace::LLM::QueryInterface.stub :query, mock_query do
        result = Ace::PromptPrep::Organisms::PromptEnhancer.call(
          content: content,
          system_prompt_uri: @system_prompt_path
        )

        refute result[:enhanced]
        assert_equal content, result[:content]
        assert_equal "API error", result[:error]
      end
    end
  end

  def test_successful_enhancement_stores_in_cache
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      content = "Test prompt"
      model = "role:prompt-enhance" # Default model
      system_prompt_uri = @system_prompt_path
      temperature = 0.3 # Default temperature
      enhanced_content = "Enhanced test prompt with more details"

      begin
        require "ace/llm"
      rescue LoadError
        skip "ace-llm not available for testing"
      end

      # Mock successful enhancement
      mock_query = ->(_model, _prompt, **_opts) { {text: enhanced_content} }

      Ace::LLM::QueryInterface.stub :query, mock_query do
        result = Ace::PromptPrep::Organisms::PromptEnhancer.call(
          content: content,
          model: model,
          system_prompt_uri: system_prompt_uri,
          temperature: temperature
        )

        assert result[:enhanced]
        refute result[:cached]
        assert_equal enhanced_content, result[:content]
        assert_nil result[:error]

        # Verify it was cached with full cache key (uses resolved content, not URI)
        system_prompt_content = File.read(system_prompt_uri)
        cache_key = Ace::PromptPrep::Molecules::EnhancementTracker.cache_key(
          content, model, system_prompt_content, temperature
        )
        assert Ace::PromptPrep::Molecules::EnhancementTracker.cached?(cache_key)
      end
    end
  end

  def test_load_system_prompt_from_file_path
    content = File.read(@system_prompt_path, encoding: "utf-8")
    loaded = Ace::PromptPrep::Organisms::PromptEnhancer.load_system_prompt(@system_prompt_path)

    assert_equal content, loaded
  end

  def test_load_system_prompt_returns_nil_for_nonexistent
    loaded = Ace::PromptPrep::Organisms::PromptEnhancer.load_system_prompt("/nonexistent.md")
    assert_nil loaded
  end
end
