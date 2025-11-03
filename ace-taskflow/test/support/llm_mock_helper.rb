# frozen_string_literal: true

# Load the LLM dependencies
begin
  require "ace/llm/query_interface"
  require "ace/llm/molecules/llm_alias_resolver"
rescue LoadError => e
  # LLM gem not available in test environment
  warn "Warning: ace-llm not available in test environment: #{e.message}"
end

# Helper module for mocking Ace::LLM::QueryInterface in tests
# Uses define_singleton_method pattern consistent with existing test mocking
module LlmMockHelper
  # Track if global mocking is enabled
  @@global_llm_mocking = false
  @@original_llm_query = nil

  # Enable global LLM mocking (called automatically from test_helper)
  def self.enable_global_mocking!
    return if @@global_llm_mocking

    begin
      @@original_llm_query = Ace::LLM::QueryInterface.method(:query)
      @@global_llm_mocking = true

      # Globally mock all LLM calls to return a default response
      Ace::LLM::QueryInterface.define_singleton_method(:query) do |model, prompt, **kwargs|
        # Return minimal valid response for slug generation
        {
          text: '{"folder_slug": "test-default", "file_slug": "test-content"}',
          model: model || "mocked",
          provider: "mocked",
          usage: { prompt_tokens: 10, completion_tokens: 20, total_tokens: 30 },
          metadata: {}
        }
      end
    rescue NameError
      # Ace::LLM not loaded yet, will be mocked when first accessed
    end
  end

  # Disable global mocking (restore original)
  def self.disable_global_mocking!
    return unless @@global_llm_mocking

    if @@original_llm_query
      Ace::LLM::QueryInterface.define_singleton_method(:query, @@original_llm_query)
    end

    @@global_llm_mocking = false
    @@original_llm_query = nil
  end
  # Mock successful LLM query with custom response text
  # @param response_text [String] The text response from LLM (typically JSON)
  # @param model [String] Model identifier for response metadata
  # @param usage [Hash] Token usage statistics
  # @yield Block to execute with mocked LLM
  def mock_llm_query(response_text:, model: "glite", usage: nil)
    # Save original method if it exists
    original_method = begin
      Ace::LLM::QueryInterface.singleton_method(:query)
    rescue NameError
      nil
    end

    # Create mock that returns successful response
    Ace::LLM::QueryInterface.define_singleton_method(:query) do |*_args, **_kwargs|
      {
        text: response_text,
        model: model,
        provider: "google",
        usage: usage || { prompt_tokens: 10, completion_tokens: 20, total_tokens: 30 },
        metadata: {}
      }
    end

    yield if block_given?
  ensure
    # Restore original method
    if original_method
      Ace::LLM::QueryInterface.define_singleton_method(:query, original_method)
    end
  end

  # Mock LLM failure with custom error
  # @param error_class [Class] Exception class to raise
  # @param error_message [String] Error message
  # @yield Block to execute with mocked failing LLM
  def mock_llm_failure(error_class: StandardError, error_message: "LLM call failed")
    # Save original method if it exists
    original_method = begin
      Ace::LLM::QueryInterface.singleton_method(:query)
    rescue NameError
      nil
    end

    # Create mock that raises error
    Ace::LLM::QueryInterface.define_singleton_method(:query) do |*_args, **_kwargs|
      raise error_class, error_message
    end

    yield if block_given?
  ensure
    # Restore original method
    if original_method
      Ace::LLM::QueryInterface.define_singleton_method(:query, original_method)
    end
  end

  # Generate mock response for slug generation
  # @param folder_slug [String] Folder slug value
  # @param file_slug [String] File slug value
  # @return [String] JSON response text
  def mock_slug_response(folder_slug:, file_slug:)
    {
      folder_slug: folder_slug,
      file_slug: file_slug
    }.to_json
  end

  # Generate mock response for idea enhancement
  # @param title [String] Idea title
  # @param filename [String] Suggested filename
  # @param enhanced_description [String] Enhanced description text
  # @return [String] JSON response text
  def mock_enhancement_response(title:, filename:, enhanced_description:)
    {
      title: title,
      filename: filename,
      enhanced_description: enhanced_description
    }.to_json
  end
end

# Enable global LLM mocking automatically when module is loaded in tests
LlmMockHelper.enable_global_mocking! if defined?(Minitest)
