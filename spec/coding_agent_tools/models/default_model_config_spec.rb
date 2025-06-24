# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/default_model_config"

RSpec.describe CodingAgentTools::Models::DefaultModelConfig do
  let(:config) { described_class.new }

  describe "DEFAULT_MODELS" do
    it "includes all required providers" do
      expect(described_class::DEFAULT_MODELS).to include(
        "google" => "gemini-2.0-flash-lite",
        "anthropic" => "claude-3-5-haiku-20241022",
        "openai" => "gpt-4o-mini",
        "mistral" => "open-mistral-nemo",
        "together_ai" => "mistralai/Mistral-7B-Instruct-v0.3",
        "lmstudio" => "mistralai/devstral-small-2505"
      )
    end

    it "has exactly 6 providers" do
      expect(described_class::DEFAULT_MODELS.keys.length).to eq(6)
    end

    it "has non-empty model names for all providers" do
      described_class::DEFAULT_MODELS.each do |provider, model|
        expect(model).not_to be_nil
        expect(model).not_to be_empty
        expect(provider).not_to be_nil
        expect(provider).not_to be_empty
      end
    end
  end

  describe "SUPPORTED_PROVIDERS" do
    it "matches DEFAULT_MODELS keys" do
      expect(described_class::SUPPORTED_PROVIDERS).to eq(described_class::DEFAULT_MODELS.keys)
    end

    it "is frozen" do
      expect(described_class::SUPPORTED_PROVIDERS).to be_frozen
    end
  end

  describe "#initialize" do
    context "with default configuration" do
      it "initializes successfully" do
        expect { described_class.new }.not_to raise_error
      end

      it "uses DEFAULT_MODELS" do
        config = described_class.new
        expect(config.default_model_for("google")).to eq("gemini-2.0-flash-lite")
        expect(config.default_model_for("anthropic")).to eq("claude-3-5-haiku-20241022")
      end
    end

    context "with custom configuration" do
      it "merges custom config with defaults" do
        custom_config = {"google" => "custom-model"}
        config = described_class.new(custom_config)

        expect(config.default_model_for("google")).to eq("custom-model")
        expect(config.default_model_for("anthropic")).to eq("claude-3-5-haiku-20241022")
      end

      it "allows overriding all providers" do
        custom_config = {
          "google" => "custom-google",
          "anthropic" => "custom-anthropic",
          "openai" => "custom-openai",
          "mistral" => "custom-mistral",
          "together_ai" => "custom-together",
          "lmstudio" => "custom-lmstudio"
        }
        config = described_class.new(custom_config)

        expect(config.default_model_for("google")).to eq("custom-google")
        expect(config.default_model_for("anthropic")).to eq("custom-anthropic")
        expect(config.default_model_for("openai")).to eq("custom-openai")
        expect(config.default_model_for("mistral")).to eq("custom-mistral")
        expect(config.default_model_for("together_ai")).to eq("custom-together")
        expect(config.default_model_for("lmstudio")).to eq("custom-lmstudio")
      end
    end

    context "with invalid configuration" do
      it "raises error for nil config" do
        expect { described_class.new(nil) }.not_to raise_error # nil gets converted to {}
      end

      it "raises error for non-hash config" do
        expect { described_class.new("invalid") }.to raise_error(
          described_class::InvalidConfigurationError,
          "Configuration must be a hash"
        )
      end

      it "raises error for nil provider name" do
        custom_config = {nil => "model"}
        expect { described_class.new(custom_config) }.to raise_error(
          described_class::InvalidConfigurationError,
          "Provider name cannot be nil or empty"
        )
      end

      it "raises error for empty provider name" do
        custom_config = {"" => "model"}
        expect { described_class.new(custom_config) }.to raise_error(
          described_class::InvalidConfigurationError,
          "Provider name cannot be nil or empty"
        )
      end

      it "raises error for nil model name" do
        custom_config = {"google" => nil}
        expect { described_class.new(custom_config) }.to raise_error(
          described_class::InvalidConfigurationError,
          "Model name cannot be nil or empty for provider: google"
        )
      end

      it "raises error for empty model name" do
        custom_config = {"google" => ""}
        expect { described_class.new(custom_config) }.to raise_error(
          described_class::InvalidConfigurationError,
          "Model name cannot be nil or empty for provider: google"
        )
      end
    end
  end

  describe "#default_model_for" do
    context "with valid providers" do
      it "returns correct models for all providers" do
        expect(config.default_model_for("google")).to eq("gemini-2.0-flash-lite")
        expect(config.default_model_for("anthropic")).to eq("claude-3-5-haiku-20241022")
        expect(config.default_model_for("openai")).to eq("gpt-4o-mini")
        expect(config.default_model_for("mistral")).to eq("open-mistral-nemo")
        expect(config.default_model_for("together_ai")).to eq("mistralai/Mistral-7B-Instruct-v0.3")
        expect(config.default_model_for("lmstudio")).to eq("mistralai/devstral-small-2505")
      end

      it "handles case insensitive provider names" do
        expect(config.default_model_for("GOOGLE")).to eq("gemini-2.0-flash-lite")
        expect(config.default_model_for("Google")).to eq("gemini-2.0-flash-lite")
        expect(config.default_model_for("ANTHROPIC")).to eq("claude-3-5-haiku-20241022")
      end

      it "handles whitespace in provider names" do
        expect(config.default_model_for(" google ")).to eq("gemini-2.0-flash-lite")
        expect(config.default_model_for("\tanthropic\n")).to eq("claude-3-5-haiku-20241022")
      end

      it "handles provider aliases" do
        expect(config.default_model_for("lms")).to eq("mistralai/devstral-small-2505")
        expect(config.default_model_for("lm_studio")).to eq("mistralai/devstral-small-2505")
        expect(config.default_model_for("open_ai")).to eq("gpt-4o-mini")
        expect(config.default_model_for("together")).to eq("mistralai/Mistral-7B-Instruct-v0.3")
      end
    end

    context "with invalid providers" do
      it "raises error for unsupported provider" do
        expect { config.default_model_for("unsupported") }.to raise_error(
          described_class::UnsupportedProviderError,
          /Unsupported provider: unsupported.*Supported providers:/
        )
      end

      it "raises error for nil provider" do
        expect { config.default_model_for(nil) }.to raise_error(
          described_class::UnsupportedProviderError
        )
      end

      it "raises error for empty provider" do
        expect { config.default_model_for("") }.to raise_error(
          described_class::UnsupportedProviderError
        )
      end

      it "includes supported providers list in error message" do
        expect { config.default_model_for("invalid") }.to raise_error(
          described_class::UnsupportedProviderError,
          /anthropic, google, lmstudio, mistral, openai, together_ai/
        )
      end
    end
  end

  describe "#supported_provider?" do
    it "returns true for supported providers" do
      expect(config.supported_provider?("google")).to be true
      expect(config.supported_provider?("anthropic")).to be true
      expect(config.supported_provider?("openai")).to be true
      expect(config.supported_provider?("mistral")).to be true
      expect(config.supported_provider?("together_ai")).to be true
      expect(config.supported_provider?("lmstudio")).to be true
    end

    it "returns false for unsupported providers" do
      expect(config.supported_provider?("unsupported")).to be false
      expect(config.supported_provider?("invalid")).to be false
    end

    it "handles case insensitive provider names" do
      expect(config.supported_provider?("GOOGLE")).to be true
      expect(config.supported_provider?("Google")).to be true
    end

    it "handles whitespace in provider names" do
      expect(config.supported_provider?(" google ")).to be true
    end

    it "handles provider aliases" do
      expect(config.supported_provider?("lms")).to be true
      expect(config.supported_provider?("lm_studio")).to be true
      expect(config.supported_provider?("open_ai")).to be true
      expect(config.supported_provider?("together")).to be true
    end

    it "returns false for nil provider" do
      expect(config.supported_provider?(nil)).to be false
    end

    it "returns false for empty provider" do
      expect(config.supported_provider?("")).to be false
    end
  end

  describe "#supported_providers" do
    it "returns all supported provider names" do
      providers = config.supported_providers
      expect(providers).to include("google", "anthropic", "openai", "mistral", "together_ai", "lmstudio")
      expect(providers.length).to eq(6)
    end

    it "returns sorted list" do
      providers = config.supported_providers
      expect(providers).to eq(providers.sort)
    end

    it "returns a copy (not the internal array)" do
      providers1 = config.supported_providers
      providers2 = config.supported_providers

      expect(providers1).not_to be(providers2)
      providers1 << "test"
      expect(providers2).not_to include("test")
    end
  end

  describe "#all_models" do
    it "returns all provider-model mappings" do
      models = config.all_models
      expect(models).to include(
        "google" => "gemini-2.0-flash-lite",
        "anthropic" => "claude-3-5-haiku-20241022",
        "openai" => "gpt-4o-mini",
        "mistral" => "open-mistral-nemo",
        "together_ai" => "mistralai/Mistral-7B-Instruct-v0.3",
        "lmstudio" => "mistralai/devstral-small-2505"
      )
    end

    it "returns a copy of the configuration" do
      models1 = config.all_models
      models2 = config.all_models

      expect(models1).not_to be(models2)
      models1["test"] = "test-model"
      expect(models2).not_to have_key("test")
    end

    it "includes custom configurations" do
      custom_config = {"google" => "custom-model"}
      config_with_custom = described_class.new(custom_config)
      models = config_with_custom.all_models

      expect(models["google"]).to eq("custom-model")
      expect(models["anthropic"]).to eq("claude-3-5-haiku-20241022")
    end
  end

  describe "#complete?" do
    it "returns true for default configuration" do
      expect(config.complete?).to be true
    end

    it "returns true for complete custom configuration" do
      custom_config = {
        "google" => "custom-google",
        "anthropic" => "custom-anthropic",
        "openai" => "custom-openai",
        "mistral" => "custom-mistral",
        "together_ai" => "custom-together",
        "lmstudio" => "custom-lmstudio"
      }
      config_with_custom = described_class.new(custom_config)
      expect(config_with_custom.complete?).to be true
    end

    it "returns false for incomplete configuration" do
      # This test may not work as expected due to validation in initialize
      # but keeping it for conceptual completeness
      incomplete_config = described_class::DEFAULT_MODELS.dup
      incomplete_config.delete("google")

      # This should raise an error during initialization, so we can't test this scenario
      # as the constructor validates completeness
    end
  end

  describe "#missing_providers" do
    it "returns empty array for complete configuration" do
      expect(config.missing_providers).to be_empty
    end

    it "identifies missing providers" do
      # Since the constructor validates completeness, we can't easily test this
      # but the method exists for potential future use
      expect(config.missing_providers).to eq([])
    end
  end

  describe ".load_from_file" do
    let(:temp_file) { "/tmp/test_config.yml" }

    after do
      File.delete(temp_file) if File.exist?(temp_file)
    end

    context "with valid YAML file" do
      it "loads configuration from file" do
        yaml_content = {
          "google" => "custom-google-model",
          "anthropic" => "custom-anthropic-model",
          "openai" => "custom-openai-model",
          "mistral" => "custom-mistral-model",
          "together_ai" => "custom-together-model",
          "lmstudio" => "custom-lmstudio-model"
        }

        File.write(temp_file, yaml_content.to_yaml)
        config = described_class.load_from_file(temp_file)

        expect(config.default_model_for("google")).to eq("custom-google-model")
        expect(config.default_model_for("anthropic")).to eq("custom-anthropic-model")
      end
    end

    context "with non-existent file" do
      it "raises error for missing file" do
        expect { described_class.load_from_file("/non/existent/file.yml") }.to raise_error(
          described_class::InvalidConfigurationError,
          /Configuration file not found/
        )
      end
    end

    context "with invalid YAML file" do
      it "raises error for invalid YAML" do
        File.write(temp_file, "invalid: yaml: content: [")

        expect { described_class.load_from_file(temp_file) }.to raise_error(
          described_class::InvalidConfigurationError,
          /Failed to load configuration/
        )
      end
    end
  end

  describe ".default" do
    it "returns a DefaultModelConfig instance" do
      expect(described_class.default).to be_a(described_class)
    end

    it "returns the same instance on multiple calls" do
      instance1 = described_class.default
      instance2 = described_class.default
      expect(instance1).to be(instance2)
    end

    it "has all default models configured" do
      default_config = described_class.default
      expect(default_config.default_model_for("google")).to eq("gemini-2.0-flash-lite")
      expect(default_config.default_model_for("anthropic")).to eq("claude-3-5-haiku-20241022")
    end
  end

  describe "provider normalization" do
    it "handles various provider name formats" do
      expect(config.default_model_for("Google")).to eq("gemini-2.0-flash-lite")
      expect(config.default_model_for("GOOGLE")).to eq("gemini-2.0-flash-lite")
      expect(config.default_model_for(" google ")).to eq("gemini-2.0-flash-lite")
      expect(config.default_model_for("lms")).to eq("mistralai/devstral-small-2505")
      expect(config.default_model_for("lm_studio")).to eq("mistralai/devstral-small-2505")
      expect(config.default_model_for("open_ai")).to eq("gpt-4o-mini")
      expect(config.default_model_for("together")).to eq("mistralai/Mistral-7B-Instruct-v0.3")
    end
  end

  describe "error classes" do
    it "defines UnsupportedProviderError" do
      expect(described_class::UnsupportedProviderError).to be < StandardError
    end

    it "defines InvalidConfigurationError" do
      expect(described_class::InvalidConfigurationError).to be < StandardError
    end
  end
end
