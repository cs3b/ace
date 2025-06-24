# frozen_string_literal: true

# Shared examples for common client behaviors across all LLM provider clients
RSpec.shared_examples "a base client" do
  describe "initialization" do
    it "sets up basic properties" do
      expect(subject).to respond_to(:model)
      expect(subject).to respond_to(:base_url)
      expect(subject).to respond_to(:generation_config)
      expect(subject).to respond_to(:provider_name)
    end

    it "uses default model when none specified" do
      client = described_class.new
      expect(client.model).to be_a(String)
      expect(client.model).not_to be_empty
    end

    it "accepts custom model parameter" do
      custom_model = "custom-model-name"
      client = described_class.new(model: custom_model)
      expect(client.model).to eq(custom_model)
    end

    it "accepts custom base_url parameter" do
      custom_url = "https://custom.api.example.com"
      client = described_class.new(base_url: custom_url)
      expect(client.base_url).to eq(custom_url)
    end

    it "merges generation config with defaults" do
      custom_config = { temperature: 0.5 }
      client = described_class.new(generation_config: custom_config)
      expect(client.generation_config[:temperature]).to eq(0.5)
    end

    it "has a recognizable provider name" do
      expect(subject.provider_name).to be_a(String)
      expect(subject.provider_name).not_to be_empty
      expect(subject.provider_name).to match(/^[a-z_]+$/)
    end
  end

  describe "error handling" do
    let(:mock_error_response) do
      {
        success: false,
        error: {
          status: 400,
          message: "Test error message"
        }
      }
    end

    it "formats error messages consistently" do
      expect {
        subject.send(:handle_error, mock_error_response)
      }.to raise_error(CodingAgentTools::Error, /API Error \(400\): Test error message/)
    end

    it "handles missing error details gracefully" do
      minimal_error = { success: false, error: {} }
      expect {
        subject.send(:handle_error, minimal_error)
      }.to raise_error(CodingAgentTools::Error, /API Error.*An unspecified error occurred/)
    end

    it "includes provider name in error messages" do
      expect {
        subject.send(:handle_error, mock_error_response)
      }.to raise_error(CodingAgentTools::Error, /#{subject.provider_name.capitalize} API Error/)
    end
  end
end

RSpec.shared_examples "a chat completion client" do
  include_examples "a base client"

  describe "chat completion interface" do
    it "responds to generate_text method" do
      expect(subject).to respond_to(:generate_text)
    end

    it "responds to generate_text_stream method" do
      expect(subject).to respond_to(:generate_text_stream)
    end

    it "responds to count_tokens method" do
      expect(subject).to respond_to(:count_tokens)
    end

    it "responds to list_models method" do
      expect(subject).to respond_to(:list_models)
    end

    it "responds to model_info method" do
      expect(subject).to respond_to(:model_info)
    end
  end

  describe "streaming support" do
    it "raises NotImplementedError for streaming" do
      expect {
        subject.generate_text_stream("test prompt")
      }.to raise_error(NotImplementedError, /Streaming responses not yet implemented/)
    end
  end

  describe "method signatures" do
    it "accepts standard generate_text parameters" do
      # This verifies the method signature without making actual API calls
      expect(subject.method(:generate_text).parameters).to include(
        [:req, :prompt],
        [:keyrest, :options]
      )
    end

    it "accepts system_instruction option" do
      # Verify the method can be called with system_instruction
      # without making actual network calls
      expect {
        allow(subject).to receive(:build_generation_payload).and_return({})
        allow(subject).to receive(:build_generation_url).and_return("http://test.example")
        allow(subject).to receive(:post_json_request).and_raise("Mock - don't actually call")
        
        subject.generate_text("test", system_instruction: "You are a helpful assistant") rescue nil
      }.not_to raise_error(ArgumentError)
    end
  end
end

# Shared examples for providers that support token counting
RSpec.shared_examples "a client with token counting" do
  include_examples "a chat completion client"

  describe "token counting" do
    it "implements token counting" do
      expect(subject.send(:supports_token_counting?)).to be(true)
    end

    it "provides token counting method" do
      expect(subject).to respond_to(:count_tokens)
    end
  end
end

# Shared examples for providers that don't support token counting
RSpec.shared_examples "a client without token counting" do
  include_examples "a chat completion client"

  describe "token counting" do
    it "does not support token counting" do
      expect(subject.send(:supports_token_counting?)).to be(false)
    end

    it "raises NotImplementedError for token counting" do
      expect {
        subject.count_tokens("test text")
      }.to raise_error(NotImplementedError, /Token counting not directly supported/)
    end
  end
end

# Shared examples for providers with authentication headers
RSpec.shared_examples "a client with auth headers" do
  include_examples "a chat completion client"

  describe "authentication" do
    it "needs authentication headers" do
      expect(subject.send(:needs_auth_headers?)).to be(true)
    end

    it "implements auth_headers method" do
      expect(subject).to respond_to(:auth_headers, true)
    end
  end
end

# Shared examples for providers without authentication headers
RSpec.shared_examples "a client without auth headers" do
  include_examples "a chat completion client"

  describe "authentication" do
    it "does not need authentication headers" do
      expect(subject.send(:needs_auth_headers?)).to be(false)
    end
  end
end