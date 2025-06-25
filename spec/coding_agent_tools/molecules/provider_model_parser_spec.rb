# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/provider_model_parser"

RSpec.describe CodingAgentTools::Molecules::ProviderModelParser do
  let(:parser) { described_class.new }

  before do
    # Clear dynamic registrations before each test to avoid test pollution
    described_class.clear_registrations!
    CodingAgentTools::Molecules::ClientFactory.clear_registry!
  end

  describe "#parse" do
    context "with valid provider:model syntax" do
      it "parses google provider correctly" do
        result = parser.parse("google:gemini-2.5-flash")

        expect(result).to be_valid
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini-2.5-flash")
        expect(result.original_input).to eq("google:gemini-2.5-flash")
        expect(result.error).to be_nil
      end

      it "parses anthropic provider correctly" do
        result = parser.parse("anthropic:claude-4-0-sonnet-latest")

        expect(result).to be_valid
        expect(result.provider).to eq("anthropic")
        expect(result.model).to eq("claude-4-0-sonnet-latest")
      end

      it "parses openai provider correctly" do
        result = parser.parse("openai:gpt-4o")

        expect(result).to be_valid
        expect(result.provider).to eq("openai")
        expect(result.model).to eq("gpt-4o")
      end

      it "parses mistral provider correctly" do
        result = parser.parse("mistral:mistral-large-latest")

        expect(result).to be_valid
        expect(result.provider).to eq("mistral")
        expect(result.model).to eq("mistral-large-latest")
      end

      it "parses together_ai provider correctly" do
        result = parser.parse("together_ai:meta-llama/Llama-2-7b-chat-hf")

        expect(result).to be_valid
        expect(result.provider).to eq("together_ai")
        expect(result.model).to eq("meta-llama/Llama-2-7b-chat-hf")
      end

      it "parses lmstudio provider correctly" do
        result = parser.parse("lmstudio:local-model")

        expect(result).to be_valid
        expect(result.provider).to eq("lmstudio")
        expect(result.model).to eq("local-model")
      end

      it "handles case-insensitive providers" do
        result = parser.parse("GOOGLE:gemini-2.5-flash")

        expect(result).to be_valid
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini-2.5-flash")
      end

      it "handles whitespace around input" do
        result = parser.parse("  google:gemini-2.5-flash  ")

        expect(result).to be_valid
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini-2.5-flash")
      end

      it "handles models with complex names" do
        result = parser.parse("together_ai:meta-llama/Llama-2-70b-chat-hf")

        expect(result).to be_valid
        expect(result.provider).to eq("together_ai")
        expect(result.model).to eq("meta-llama/Llama-2-70b-chat-hf")
      end
    end

    context "with dynamic aliases" do
      it "resolves gflash alias" do
        result = parser.parse("gflash")

        expect(result).to be_valid
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini-2.5-flash")
        expect(result.original_input).to eq("gflash")
      end

      it "resolves gpro alias" do
        result = parser.parse("gpro")

        expect(result).to be_valid
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini-2.5-pro")
      end

      it "resolves csonet alias" do
        result = parser.parse("csonet")

        expect(result).to be_valid
        expect(result.provider).to eq("anthropic")
        expect(result.model).to eq("claude-4-0-sonnet-latest")
      end

      it "resolves copus alias" do
        result = parser.parse("copus")

        expect(result).to be_valid
        expect(result.provider).to eq("anthropic")
        expect(result.model).to eq("claude-4-0-opus-latest")
      end

      it "resolves o4mini alias" do
        result = parser.parse("o4mini")

        expect(result).to be_valid
        expect(result.provider).to eq("openai")
        expect(result.model).to eq("gpt-4o-mini")
      end

      it "resolves o3 alias" do
        result = parser.parse("o3")

        expect(result).to be_valid
        expect(result.provider).to eq("openai")
        expect(result.model).to eq("o3")
      end

      it "handles whitespace around aliases" do
        result = parser.parse("  gflash  ")

        expect(result).to be_valid
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini-2.5-flash")
      end
    end

    context "with invalid input" do
      it "handles nil input" do
        result = parser.parse(nil)

        expect(result).to be_invalid
        expect(result.error).to eq("Input cannot be nil or empty")
        expect(result.provider).to be_nil
        expect(result.model).to be_nil
      end

      it "handles empty input" do
        result = parser.parse("")

        expect(result).to be_invalid
        expect(result.error).to eq("Input cannot be nil or empty")
      end

      it "handles whitespace-only input" do
        result = parser.parse("   ")

        expect(result).to be_invalid
        expect(result.error).to eq("Input cannot be nil or empty")
      end

      it "handles invalid format without colon" do
        result = parser.parse("googlegemini")

        expect(result).to be_invalid
        expect(result.error).to eq("Unknown provider: googlegemini. Supported providers: anthropic, google, lmstudio, mistral, openai, together_ai")
        expect(result.original_input).to eq("googlegemini")
      end

      it "handles invalid format with multiple colons" do
        result = parser.parse("google:gemini:flash")

        expect(result).to be_valid # This should actually work - it splits on first colon
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini:flash")
      end

      it "handles unknown provider" do
        result = parser.parse("unknown:model")

        expect(result).to be_invalid
        expect(result.error).to include("Unknown provider: unknown")
        expect(result.error).to include("Supported providers:")
      end

      it "handles empty model" do
        result = parser.parse("google:")

        expect(result).to be_invalid
        expect(result.error).to eq("Model name cannot be empty")
      end

      it "handles empty model with whitespace" do
        result = parser.parse("google:   ")

        expect(result).to be_invalid
        expect(result.error).to eq("Model name cannot be empty")
      end

      it "handles unknown alias" do
        result = parser.parse("unknown_alias")

        expect(result).to be_invalid
        expect(result.error).to eq("Unknown provider: unknown_alias. Supported providers: anthropic, google, lmstudio, mistral, openai, together_ai")
      end
    end

    context "with provider-only syntax (using default models)" do
      it "parses google provider-only correctly" do
        result = parser.parse("google")

        expect(result).to be_valid
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini-2.0-flash-lite")
        expect(result.original_input).to eq("google")
      end

      it "parses anthropic provider-only correctly" do
        result = parser.parse("anthropic")

        expect(result).to be_valid
        expect(result.provider).to eq("anthropic")
        expect(result.model).to eq("claude-3-5-haiku-20241022")
        expect(result.original_input).to eq("anthropic")
      end

      it "parses openai provider-only correctly" do
        result = parser.parse("openai")

        expect(result).to be_valid
        expect(result.provider).to eq("openai")
        expect(result.model).to eq("gpt-4o-mini")
        expect(result.original_input).to eq("openai")
      end

      it "parses mistral provider-only correctly" do
        result = parser.parse("mistral")

        expect(result).to be_valid
        expect(result.provider).to eq("mistral")
        expect(result.model).to eq("open-mistral-nemo")
        expect(result.original_input).to eq("mistral")
      end

      it "parses together_ai provider-only correctly" do
        result = parser.parse("together_ai")

        expect(result).to be_valid
        expect(result.provider).to eq("together_ai")
        expect(result.model).to eq("mistralai/Mistral-7B-Instruct-v0.3")
        expect(result.original_input).to eq("together_ai")
      end

      it "parses lmstudio provider-only correctly" do
        result = parser.parse("lmstudio")

        expect(result).to be_valid
        expect(result.provider).to eq("lmstudio")
        expect(result.model).to eq("mistralai/devstral-small-2505")
        expect(result.original_input).to eq("lmstudio")
      end

      it "handles case insensitive provider-only" do
        result = parser.parse("GOOGLE")

        expect(result).to be_valid
        expect(result.provider).to eq("google")
        expect(result.model).to eq("gemini-2.0-flash-lite")
      end

      it "handles whitespace around provider-only" do
        result = parser.parse("  anthropic  ")

        expect(result).to be_valid
        expect(result.provider).to eq("anthropic")
        expect(result.model).to eq("claude-3-5-haiku-20241022")
      end
    end
  end

  describe "#default_models" do
    it "returns all default models" do
      defaults = parser.default_models

      expect(defaults).to include(
        "google" => "gemini-2.0-flash-lite",
        "anthropic" => "claude-3-5-haiku-20241022",
        "openai" => "gpt-4o-mini",
        "mistral" => "open-mistral-nemo",
        "together_ai" => "mistralai/Mistral-7B-Instruct-v0.3",
        "lmstudio" => "mistralai/devstral-small-2505"
      )
    end

    it "returns a copy of the hash" do
      defaults1 = parser.default_models
      defaults2 = parser.default_models

      expect(defaults1).to eq(defaults2)
      expect(defaults1).not_to be(defaults2) # Different object instances
    end
  end

  describe "#default_model_for" do
    it "returns default model for valid providers" do
      expect(parser.default_model_for("google")).to eq("gemini-2.0-flash-lite")
      expect(parser.default_model_for("anthropic")).to eq("claude-3-5-haiku-20241022")
      expect(parser.default_model_for("openai")).to eq("gpt-4o-mini")
      expect(parser.default_model_for("mistral")).to eq("open-mistral-nemo")
      expect(parser.default_model_for("together_ai")).to eq("mistralai/Mistral-7B-Instruct-v0.3")
      expect(parser.default_model_for("lmstudio")).to eq("mistralai/devstral-small-2505")
    end

    it "handles case insensitive provider names" do
      expect(parser.default_model_for("GOOGLE")).to eq("gemini-2.0-flash-lite")
      expect(parser.default_model_for("Anthropic")).to eq("claude-3-5-haiku-20241022")
    end

    it "handles whitespace" do
      expect(parser.default_model_for("  google  ")).to eq("gemini-2.0-flash-lite")
    end

    it "returns nil for unknown providers" do
      expect(parser.default_model_for("unknown")).to be_nil
    end

    it "returns nil for nil input" do
      expect(parser.default_model_for(nil)).to be_nil
    end
  end

  describe "#supported_providers" do
    it "returns all supported providers" do
      providers = parser.supported_providers

      expect(providers).to include("google", "anthropic", "openai", "mistral", "together_ai", "lmstudio")
      expect(providers.length).to eq(6)
    end

    it "returns a copy of the providers array" do
      providers1 = parser.supported_providers
      providers2 = parser.supported_providers

      expect(providers1).not_to be(providers2)
      providers1 << "test"
      expect(providers2).not_to include("test")
    end
  end

  describe "#dynamic_aliases" do
    it "returns all dynamic aliases" do
      aliases = parser.dynamic_aliases

      expect(aliases).to include(
        "gflash" => "google:gemini-2.5-flash",
        "gpro" => "google:gemini-2.5-pro",
        "csonet" => "anthropic:claude-4-0-sonnet-latest",
        "copus" => "anthropic:claude-4-0-opus-latest",
        "o4mini" => "openai:gpt-4o-mini",
        "o3" => "openai:o3"
      )
    end

    it "returns a copy of the aliases hash" do
      aliases1 = parser.dynamic_aliases
      aliases2 = parser.dynamic_aliases

      expect(aliases1).not_to be(aliases2)
      aliases1["test"] = "test:model"
      expect(aliases2).not_to have_key("test")
    end
  end

  describe "#valid_provider?" do
    it "returns true for valid providers" do
      expect(parser.valid_provider?("google")).to be true
      expect(parser.valid_provider?("anthropic")).to be true
      expect(parser.valid_provider?("openai")).to be true
      expect(parser.valid_provider?("mistral")).to be true
      expect(parser.valid_provider?("together_ai")).to be true
      expect(parser.valid_provider?("lmstudio")).to be true
    end

    it "returns false for invalid providers" do
      expect(parser.valid_provider?("unknown")).to be false
      expect(parser.valid_provider?("")).to be false
    end

    it "handles case insensitivity" do
      expect(parser.valid_provider?("GOOGLE")).to be true
      expect(parser.valid_provider?("Google")).to be true
    end

    it "handles whitespace" do
      expect(parser.valid_provider?("  google  ")).to be true
    end

    it "handles nil input" do
      expect(parser.valid_provider?(nil)).to be false
    end
  end

  describe "#resolve_alias" do
    it "resolves known aliases" do
      expect(parser.resolve_alias("gflash")).to eq("google:gemini-2.5-flash")
      expect(parser.resolve_alias("gpro")).to eq("google:gemini-2.5-pro")
      expect(parser.resolve_alias("csonet")).to eq("anthropic:claude-4-0-sonnet-latest")
      expect(parser.resolve_alias("copus")).to eq("anthropic:claude-4-0-opus-latest")
      expect(parser.resolve_alias("o4mini")).to eq("openai:gpt-4o-mini")
      expect(parser.resolve_alias("o3")).to eq("openai:o3")
    end

    it "returns nil for unknown aliases" do
      expect(parser.resolve_alias("unknown")).to be_nil
      expect(parser.resolve_alias("")).to be_nil
    end

    it "handles whitespace" do
      expect(parser.resolve_alias("  gflash  ")).to eq("google:gemini-2.5-flash")
    end

    it "handles nil input" do
      expect(parser.resolve_alias(nil)).to be_nil
    end
  end

  describe "#alias?" do
    it "returns true for known aliases" do
      expect(parser.alias?("gflash")).to be true
      expect(parser.alias?("gpro")).to be true
      expect(parser.alias?("csonet")).to be true
      expect(parser.alias?("copus")).to be true
      expect(parser.alias?("o4mini")).to be true
      expect(parser.alias?("o3")).to be true
    end

    it "returns false for unknown aliases" do
      expect(parser.alias?("unknown")).to be false
      expect(parser.alias?("")).to be false
    end

    it "handles whitespace" do
      expect(parser.alias?("  gflash  ")).to be true
    end

    it "handles nil input" do
      expect(parser.alias?(nil)).to be false
    end
  end

  describe "ParseResult" do
    let(:valid_result) { parser.parse("google:gemini-2.5-flash") }
    let(:invalid_result) { parser.parse("unknown:model") }

    describe "#valid?" do
      it "returns true for valid results" do
        expect(valid_result.valid?).to be true
      end

      it "returns false for invalid results" do
        expect(invalid_result.valid?).to be false
      end
    end

    describe "#invalid?" do
      it "returns false for valid results" do
        expect(valid_result.invalid?).to be false
      end

      it "returns true for invalid results" do
        expect(invalid_result.invalid?).to be true
      end
    end

    describe "#to_s" do
      it "returns provider:model format for valid results" do
        expect(valid_result.to_s).to eq("google:gemini-2.5-flash")
      end

      it "returns provider:model format even for invalid results with nil values" do
        expect(invalid_result.to_s).to eq(":")
      end
    end
  end
end
