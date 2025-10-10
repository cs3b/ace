# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Organisms::BaseClient do
  describe ".provider_name" do
    it "raises NotImplementedError when called on BaseClient" do
      expect do
        described_class.provider_name
      end.to raise_error(
        NotImplementedError,
        "CodingAgentTools::Organisms::BaseClient must implement .provider_name"
      )
    end
  end

  describe "#provider_name" do
    let(:mock_client_class) do
      Class.new(described_class) do
        def self.name
          "MockClient"
        end

        def self.provider_name
          "mock"
        end

        # Mock required constants to avoid errors
        const_set(:API_BASE_URL, "https://mock.api")
        const_set(:DEFAULT_GENERATION_CONFIG, {})

        private

        def needs_credentials?
          false
        end
      end
    end

    it "returns the class provider_name when called on instance" do
      # We can't instantiate BaseClient directly, so we use a mock subclass
      instance = mock_client_class.new(model: "test-model")
      expect(instance.provider_name).to eq("mock")
    end

    it "cannot be instantiated directly" do
      expect do
        described_class.new
      end.to raise_error(
        NotImplementedError,
        "BaseClient is abstract and cannot be instantiated directly"
      )
    end
  end

  describe "concrete client classes" do
    let(:client_classes) do
      [
        CodingAgentTools::Organisms::GoogleClient,
        CodingAgentTools::Organisms::AnthropicClient,
        CodingAgentTools::Organisms::OpenaiClient,
        CodingAgentTools::Organisms::MistralClient,
        CodingAgentTools::Organisms::TogetheraiClient,
        CodingAgentTools::Organisms::LmstudioClient
      ]
    end

    it "all implement explicit provider_name class method" do
      client_classes.each do |client_class|
        expect(client_class).to respond_to(:provider_name)
        expect do
          provider_name = client_class.provider_name
          expect(provider_name).to be_a(String)
          expect(provider_name).not_to be_empty
        end.not_to raise_error
      end
    end

    it "returns consistent provider names" do
      expected_names = {
        "GoogleClient" => "google",
        "AnthropicClient" => "anthropic",
        "OpenaiClient" => "openai",
        "MistralClient" => "mistral",
        "TogetheraiClient" => "together_ai",
        "LmstudioClient" => "lmstudio"
      }

      client_classes.each do |client_class|
        class_name = client_class.name.split("::").last
        expected_name = expected_names[class_name]

        expect(client_class.provider_name).to eq(expected_name),
          "Expected #{class_name} to have provider_name '#{expected_name}', got '#{client_class.provider_name}'"
      end
    end
  end
end
