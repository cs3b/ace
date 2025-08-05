# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/organisms/google_client'
require 'webmock/rspec'

RSpec.describe CodingAgentTools::Organisms::GoogleClient do
  let(:api_key) { 'test-api-key-123' }
  let(:client) { described_class.new(api_key: api_key) }
  let(:custom_client) do
    described_class.new(
      api_key: api_key,
      model: 'gemini-pro',
      base_url: 'https://custom.api.com',
      generation_config: { temperature: 0.5, maxOutputTokens: 4096 },
      timeout: 60
    )
  end

  describe '.dynamic_aliases' do
    it 'returns expected aliases for Google provider' do
      aliases = described_class.dynamic_aliases
      expect(aliases).to eq({
        'gflash' => 'google:gemini-2.5-flash',
        'gpro' => 'google:gemini-2.5-pro'
      })
    end
  end

  describe '#initialize' do
    context 'with default configuration' do
      it 'uses default model' do
        expect(client.instance_variable_get(:@model)).to eq('gemini-2.0-flash-lite')
      end

      it 'uses default base URL' do
        expect(client.instance_variable_get(:@base_url)).to eq('https://generativelanguage.googleapis.com/v1beta')
      end

      it 'uses default generation config' do
        config = client.instance_variable_get(:@generation_config)
        expect(config[:temperature]).to eq(0.7)
        expect(config[:maxOutputTokens]).to eq(8192)
      end

      it 'uses GOOGLE_API_KEY environment variable by default' do
        credentials = client.instance_variable_get(:@credentials)
        expect(credentials.instance_variable_get(:@env_key_name)).to eq('GOOGLE_API_KEY')
      end
    end

    context 'with custom configuration' do
      it 'uses custom model' do
        expect(custom_client.instance_variable_get(:@model)).to eq('gemini-pro')
      end

      it 'uses custom base URL' do
        expect(custom_client.instance_variable_get(:@base_url)).to eq('https://custom.api.com')
      end

      it 'merges custom generation config' do
        config = custom_client.instance_variable_get(:@generation_config)
        expect(config[:temperature]).to eq(0.5)
        expect(config[:maxOutputTokens]).to eq(4096)
      end

      it 'accepts timeout configuration' do
        # Test that timeout is accepted without error
        expect { custom_client }.not_to raise_error
      end

      it 'accepts event namespace configuration' do
        # Test that client initializes without error
        expect { client }.not_to raise_error
      end
    end

    context 'with API key from environment' do
      it 'uses environment variable when no api_key provided' do
        allow_any_instance_of(CodingAgentTools::Molecules::APICredentials)
          .to receive(:api_key).and_return('env-api-key')

        env_client = described_class.new
        expect(env_client.instance_variable_get(:@api_key)).to eq('env-api-key')
      end
    end
  end

  describe '#generate_text' do
    let(:prompt) { 'Tell me about Ruby programming' }
    let(:success_response) do
      {
        candidates: [
          {
            content: {
              parts: [
                { text: 'Ruby is a dynamic programming language...' }
              ]
            },
            finishReason: 'STOP',
            safetyRatings: []
          }
        ],
        usageMetadata: {
          promptTokenCount: 10,
          candidatesTokenCount: 20,
          totalTokenCount: 30
        }
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).and_return(success_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({ success: true, data: success_response })
    end

    it 'generates text successfully' do
      result = client.generate_text(prompt)

      expect(result[:text]).to eq('Ruby is a dynamic programming language...')
      expect(result[:finish_reason]).to eq('STOP')
      expect(result[:usage_metadata]).to eq(success_response[:usageMetadata])
    end

    it 'builds correct API URL' do
      expected_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=#{api_key}"

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).with(expected_url, anything)

      client.generate_text(prompt)
    end

    it 'builds correct payload structure' do
      expected_payload = {
        contents: [
          {
            role: 'user',
            parts: [{ text: prompt }]
          }
        ],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 8192
        }
      }

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).with(anything, expected_payload)

      client.generate_text(prompt)
    end

    context 'with system instruction' do
      let(:system_instruction) { 'You are a helpful programming assistant' }

      it 'includes system instruction in payload' do
        expected_payload = hash_including(
          systemInstruction: {
            parts: [{ text: system_instruction }]
          }
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload)

        client.generate_text(prompt, system_instruction: system_instruction)
      end
    end

    context 'with custom generation config' do
      it 'merges generation config options' do
        custom_config = { temperature: 0.9, maxOutputTokens: 1000 }
        expected_config = { temperature: 0.9, maxOutputTokens: 1000 }

        expected_payload = hash_including(
          generationConfig: expected_config
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload)

        client.generate_text(prompt, generation_config: custom_config)
      end
    end

    context 'when API returns error' do
      let(:error_response) do
        {
          error: {
            status: 'INVALID_ARGUMENT',
            message: 'Invalid prompt'
          }
        }
      end

      before do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({ success: false, error: error_response[:error] })
      end

      it 'raises error with formatted message' do
        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /Google API Error.*INVALID_ARGUMENT.*Invalid prompt/)
      end
    end

    context 'when response has malformed structure', :error_handling do
      before do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({ success: true, data: { candidates: [] } })
      end

      it 'raises error for empty candidates' do
        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /candidates.*array is empty/)
      end

      it 'raises error when candidates is not an array' do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({ success: true, data: { candidates: 'not_an_array' } })

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /candidates.*field is not an array/)
      end

      it 'raises error when data is not a hash' do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({ success: true, data: 'not_a_hash' })

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /Response data is not a Hash/)
      end

      it 'raises error when first candidate is not a hash' do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({ success: true, data: { candidates: ['not_a_hash'] } })

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /No valid first candidate found/)
      end

      it 'raises error when candidate content is missing' do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({ success: true, data: { candidates: [{}] } })

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /content.*field is missing/)
      end

      it 'raises error when candidate content is not a hash' do
        malformed_response = {
          success: true,
          data: {
            candidates: [{ content: 'not_a_hash' }]
          }
        }
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return(malformed_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /content.*field is missing or not a Hash/)
      end

      it 'raises error when content parts is missing' do
        malformed_response = {
          success: true,
          data: {
            candidates: [{ content: {} }]
          }
        }
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return(malformed_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /content\.parts.*field is missing/)
      end

      it 'raises error when content parts is not an array' do
        malformed_response = {
          success: true,
          data: {
            candidates: [{ content: { parts: 'not_an_array' } }]
          }
        }
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return(malformed_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /content\.parts.*field is missing or not an Array/)
      end

      it 'raises error when content parts is empty' do
        malformed_response = {
          success: true,
          data: {
            candidates: [{ content: { parts: [] } }]
          }
        }
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return(malformed_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /content\.parts.*array is empty/)
      end

      it 'raises error when first part is not a hash' do
        malformed_response = {
          success: true,
          data: {
            candidates: [{ content: { parts: ['not_a_hash'] } }]
          }
        }
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return(malformed_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /first element.*is not a Hash/)
      end

      it 'raises error when text key is missing' do
        malformed_response = {
          success: true,
          data: {
            candidates: [{ content: { parts: [{}] } }]
          }
        }
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return(malformed_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /does not have a 'text' key/)
      end

      it 'raises error when text value is nil' do
        malformed_response = {
          success: true,
          data: {
            candidates: [{ content: { parts: [{ text: nil }] } }]
          }
        }
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return(malformed_response)

        expect { client.generate_text(prompt) }
          .to raise_error(CodingAgentTools::Error, /text missing from the first part/)
      end
    end
  end

  describe '#count_tokens', :token_counting do
    let(:text) { 'Hello world' }
    let(:token_count_response) do
      {
        totalTokens: 15
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).and_return(token_count_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({ success: true, data: token_count_response })
    end

    it 'returns token count information' do
      result = client.count_tokens(text)

      expect(result[:token_count]).to eq(15)
      expect(result[:details]).to eq(token_count_response)
    end

    it 'builds correct API URL' do
      expected_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:countTokens?key=#{api_key}"

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).with(expected_url, anything)

      client.count_tokens(text)
    end

    it 'sends correct payload structure' do
      expected_payload = {
        contents: [
          {
            parts: [{ text: text }]
          }
        ]
      }

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).with(anything, expected_payload)

      client.count_tokens(text)
    end

    context 'when API returns error' do
      let(:error_response) do
        {
          error: {
            status: 'PERMISSION_DENIED',
            message: 'API key not valid'
          }
        }
      end

      before do
        allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
          .to receive(:parse_response).and_return({ success: false, error: error_response[:error] })
      end

      it 'raises error with formatted message' do
        expect { client.count_tokens(text) }
          .to raise_error(CodingAgentTools::Error, /Google API Error.*PERMISSION_DENIED.*API key not valid/)
      end
    end

    context 'with empty text' do
      it 'handles empty string' do
        result = client.count_tokens('')
        expect(result[:token_count]).to eq(15)
        expect(result[:details]).to eq(token_count_response)
      end
    end

    context 'with special characters' do
      let(:special_text) { 'Hello 🌍 world! こんにちは' }

      it 'handles unicode characters' do
        result = client.count_tokens(special_text)
        expect(result[:token_count]).to eq(15)
        expect(result[:details]).to eq(token_count_response)
      end
    end
  end

  describe '#list_models' do
    let(:models_response) do
      {
        models: [
          { name: 'models/gemini-pro', displayName: 'Gemini Pro' },
          { name: 'models/gemini-2.0-flash-lite', displayName: 'Gemini 2.0 Flash Lite' }
        ]
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:get_json).and_return(models_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({ success: true, data: models_response })
    end

    it 'returns list of models' do
      result = client.list_models

      expect(result).to eq(models_response[:models])
    end

    it 'builds correct API URL' do
      expected_url = "https://generativelanguage.googleapis.com/v1beta/models?key=#{api_key}"

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:get_json).with(expected_url)

      client.list_models
    end
  end

  describe '#model_info' do
    let(:model_info_response) do
      {
        name: 'models/gemini-2.0-flash-lite',
        displayName: 'Gemini 2.0 Flash Lite',
        description: 'Fast and efficient model'
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:get_json).and_return(model_info_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({ success: true, data: model_info_response })
    end

    it 'returns model information' do
      result = client.model_info

      expect(result).to eq(model_info_response)
    end

    it 'builds correct API URL with model name' do
      expected_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite?key=#{api_key}"

      expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:get_json).with(expected_url)

      client.model_info
    end
  end

  describe '#generate_text_stream' do
    it 'raises NotImplementedError' do
      expect { client.generate_text_stream('test prompt') }
        .to raise_error(NotImplementedError, 'Streaming responses not yet implemented')
    end
  end

  describe 'private URL building methods', :url_building do
    describe '#build_url_with_path' do
      it 'handles base URLs without trailing slash' do
        client_without_slash = described_class.new(
          api_key: api_key,
          base_url: 'https://api.example.com'
        )

        url = client_without_slash.send(:build_url_with_path, 'test/path')
        expect(url).to eq("https://api.example.com/test/path?key=#{api_key}")
      end

      it 'handles base URLs with trailing slash' do
        client_with_slash = described_class.new(
          api_key: api_key,
          base_url: 'https://api.example.com/'
        )

        url = client_with_slash.send(:build_url_with_path, 'test/path')
        expect(url).to eq("https://api.example.com/test/path?key=#{api_key}")
      end

      it 'handles complex path segments with special characters' do
        url = client.send(:build_url_with_path, 'test/path-with-special_chars')
        expect(url).to eq("https://generativelanguage.googleapis.com/v1beta/test/path-with-special_chars?key=#{api_key}")
      end

      it 'handles path segments with spaces (URL encoding handled by Addressable)' do
        url = client.send(:build_url_with_path, 'test/path with spaces')
        expect(url).to include('test/path with spaces')
        expect(url).to include("?key=#{api_key}")
      end
    end

    describe '#build_api_url' do
      it 'builds correct URL for generation endpoint' do
        url = client.send(:build_api_url, 'generateContent')
        expect(url).to eq("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=#{api_key}")
      end

      it 'builds correct URL for token counting endpoint' do
        url = client.send(:build_api_url, 'countTokens')
        expect(url).to eq("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:countTokens?key=#{api_key}")
      end
    end
  end

  describe 'error extraction', :error_extraction do
    describe '#extract_error_content' do
      it 'extracts details message when available' do
        error_obj = {
          details: { message: 'Detailed error message' },
          message: 'General error message',
          raw_message: 'Raw error message'
        }

        result = client.send(:extract_error_content, error_obj)
        expect(result).to eq('Detailed error message')
      end

      it 'falls back to raw_message when details message is missing' do
        error_obj = {
          message: 'General error message',
          raw_message: 'Raw error message'
        }

        result = client.send(:extract_error_content, error_obj)
        expect(result).to eq('Raw error message')
      end

      it 'falls back to general message when details and raw_message are missing' do
        error_obj = {
          message: 'General error message'
        }

        result = client.send(:extract_error_content, error_obj)
        expect(result).to eq('General error message')
      end

      it 'returns default message when all specific messages are missing' do
        error_obj = {}

        result = client.send(:extract_error_content, error_obj)
        expect(result).to eq('An unspecified error occurred.')
      end

      it 'handles non-hash error objects' do
        error_obj = 'string error'

        result = client.send(:extract_error_content, error_obj)
        expect(result).to eq('An unspecified error occurred.')
      end

      it 'handles nil error objects' do
        error_obj = nil

        result = client.send(:extract_error_content, error_obj)
        expect(result).to eq('An unspecified error occurred.')
      end
    end
  end

  describe 'configuration edge cases', :configuration do
    let(:success_response) do
      {
        candidates: [
          {
            content: {
              parts: [
                { text: 'Configuration test response' }
              ]
            },
            finishReason: 'STOP',
            safetyRatings: []
          }
        ],
        usageMetadata: {
          promptTokenCount: 10,
          candidatesTokenCount: 20,
          totalTokenCount: 30
        }
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
        .to receive(:post_json).and_return(success_response)
      allow_any_instance_of(CodingAgentTools::Molecules::APIResponseParser)
        .to receive(:parse_response).and_return({ success: true, data: success_response })
    end

    describe 'with complex system instructions' do
      let(:complex_system_instruction) { "You are a helpful assistant.\n\nPlease format your responses using markdown and include examples where appropriate." }

      it 'handles multi-line system instructions' do
        expected_payload = hash_including(
          systemInstruction: {
            parts: [{ text: complex_system_instruction }]
          }
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload).and_return(success_response)

        result = client.generate_text('test prompt', system_instruction: complex_system_instruction)
        expect(result[:text]).to eq('Configuration test response')
      end

      it 'handles system instructions with special characters' do
        special_instruction = 'You are a helpful assistant! 🤖 Use emojis: ✨, 🌟, 💡'

        expected_payload = hash_including(
          systemInstruction: {
            parts: [{ text: special_instruction }]
          }
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload).and_return(success_response)

        result = client.generate_text('test prompt', system_instruction: special_instruction)
        expect(result[:text]).to eq('Configuration test response')
      end
    end

    describe 'with complex generation configs' do
      it 'handles all possible generation config options' do
        complex_config = {
          temperature: 0.9,
          maxOutputTokens: 1000,
          topP: 0.8,
          topK: 40,
          responseMimeType: 'application/json'
        }

        expected_payload = hash_including(
          generationConfig: complex_config
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload).and_return(success_response)

        result = client.generate_text('test prompt', generation_config: complex_config)
        expect(result[:text]).to eq('Configuration test response')
      end

      it 'handles generation config with boundary values' do
        boundary_config = {
          temperature: 2.0,
          maxOutputTokens: 8192,
          topP: 1.0,
          topK: 1
        }

        expected_payload = hash_including(
          generationConfig: boundary_config
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload).and_return(success_response)

        result = client.generate_text('test prompt', generation_config: boundary_config)
        expect(result[:text]).to eq('Configuration test response')
      end
    end

    describe 'combined complex configurations' do
      it 'handles both system instruction and complex generation config' do
        system_instruction = 'You are a JSON API assistant.'
        generation_config = {
          temperature: 0.1,
          maxOutputTokens: 500,
          responseMimeType: 'application/json'
        }

        expected_payload = hash_including(
          systemInstruction: {
            parts: [{ text: system_instruction }]
          },
          generationConfig: generation_config
        )

        expect_any_instance_of(CodingAgentTools::Molecules::HTTPRequestBuilder)
          .to receive(:post_json).with(anything, expected_payload).and_return(success_response)

        result = client.generate_text('test prompt',
          system_instruction: system_instruction,
          generation_config: generation_config)
        expect(result[:text]).to eq('Configuration test response')
      end
    end
  end
end
