# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::ClientFactory do
  let(:factory) { described_class }
  let(:mock_client_class) do
    Class.new do
      def initialize(**options)
        @options = options
      end

      attr_reader :options
    end
  end

  before do
    # Clear registry before each test
    factory.clear_registry!
  end

  after do
    # Clean up after each test
    factory.clear_registry!
  end

  describe ".register" do
    it "registers a client class for a provider" do
      factory.register("test_provider", mock_client_class)

      expect(factory.registered_providers).to include("test_provider")
      expect(factory.registry["test_provider"]).to eq(mock_client_class)
    end

    it "allows re-registration of the same provider" do
      other_client_class = Class.new

      factory.register("test_provider", mock_client_class)
      factory.register("test_provider", other_client_class)

      expect(factory.registry["test_provider"]).to eq(other_client_class)
    end
  end

  describe ".build" do
    before do
      factory.register("test_provider", mock_client_class)
    end

    it "builds a client instance for registered provider" do
      client = factory.build("test_provider", model: "test-model")

      expect(client).to be_an_instance_of(mock_client_class)
      expect(client.options[:model]).to eq("test-model")
    end

    it "passes options to the client constructor" do
      options = {model: "test-model", temperature: 0.7, timeout: 30}
      client = factory.build("test_provider", options)

      expect(client.options).to eq(options)
    end

    it "raises UnknownProviderError for unregistered provider" do
      expect {
        factory.build("unknown_provider")
      }.to raise_error(
        CodingAgentTools::Molecules::ClientFactory::UnknownProviderError,
        /Unknown provider 'unknown_provider'/
      )
    end

    it "includes registered providers in error message" do
      factory.register("provider_a", mock_client_class)
      factory.register("provider_b", mock_client_class)

      expect {
        factory.build("unknown_provider")
      }.to raise_error(
        CodingAgentTools::Molecules::ClientFactory::UnknownProviderError,
        /Registered providers: .*provider_a.*provider_b/
      )
    end
  end

  describe ".registered_providers" do
    it "returns empty array when no providers are registered" do
      expect(factory.registered_providers).to eq([])
    end

    it "returns sorted list of registered provider names" do
      factory.register("zebra", mock_client_class)
      factory.register("alpha", mock_client_class)
      factory.register("beta", mock_client_class)

      expect(factory.registered_providers).to eq(["alpha", "beta", "zebra"])
    end
  end

  describe ".registry" do
    it "returns the internal registry hash" do
      factory.register("test_provider", mock_client_class)

      registry = factory.registry
      expect(registry).to be_a(Hash)
      expect(registry["test_provider"]).to eq(mock_client_class)
    end
  end

  describe ".clear_registry!" do
    it "clears all registered providers" do
      factory.register("provider_a", mock_client_class)
      factory.register("provider_b", mock_client_class)

      expect(factory.registered_providers).not_to be_empty

      factory.clear_registry!

      expect(factory.registered_providers).to be_empty
      expect(factory.registry).to be_empty
    end
  end

  describe "auto-loading integration" do
    it "works with provider model parser integration" do
      # Load providers through the parser (which triggers client loading)
      parser = CodingAgentTools::Molecules::ProviderModelParser.new
      parser.parse("google:gemini-2.5-flash")

      # Now the factory should have the providers registered
      expect(factory.registered_providers).to include("google")
    end

    it "has access to real provider names through parser integration" do
      # Use the parser to trigger provider loading
      parser = CodingAgentTools::Molecules::ProviderModelParser.new
      parser.ensure_providers_loaded

      expected_providers = %w[google anthropic openai mistral together_ai lmstudio]
      expect(factory.registered_providers).to include(*expected_providers)
    end
  end
end
