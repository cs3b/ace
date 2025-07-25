# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/constants/model_constants"

RSpec.describe CodingAgentTools::Constants::ModelConstants do
  describe "Gemini constants" do
    let(:gemini_module) { described_class::Gemini }

    describe "model constants" do
      it "defines DEFAULT_MODEL" do
        expect(gemini_module::DEFAULT_MODEL).to eq("gemini-2.0-flash-lite")
      end

      it "defines GEMINI_2_0_FLASH_LITE" do
        expect(gemini_module::GEMINI_2_0_FLASH_LITE).to eq("gemini-2.0-flash-lite")
      end

      it "defines GEMINI_1_5_FLASH" do
        expect(gemini_module::GEMINI_1_5_FLASH).to eq("gemini-1.5-flash")
      end

      it "defines GEMINI_1_5_PRO" do
        expect(gemini_module::GEMINI_1_5_PRO).to eq("gemini-1.5-pro")
      end

      it "default model matches one of the defined models" do
        defined_models = [
          gemini_module::GEMINI_2_0_FLASH_LITE,
          gemini_module::GEMINI_1_5_FLASH,
          gemini_module::GEMINI_1_5_PRO
        ]
        expect(defined_models).to include(gemini_module::DEFAULT_MODEL)
      end
    end

    describe "DESCRIPTIONS hash" do
      it "is frozen" do
        expect(gemini_module::DESCRIPTIONS).to be_frozen
      end

      it "contains descriptions for all defined models" do
        expect(gemini_module::DESCRIPTIONS[gemini_module::GEMINI_2_0_FLASH_LITE]).to eq("Fast and efficient model, good for most tasks")
        expect(gemini_module::DESCRIPTIONS[gemini_module::GEMINI_1_5_FLASH]).to eq("Fast multimodal model optimized for speed")
        expect(gemini_module::DESCRIPTIONS[gemini_module::GEMINI_1_5_PRO]).to eq("Mid-size multimodal model for complex reasoning tasks")
      end

      it "has descriptions for all defined model constants" do
        defined_models = [
          gemini_module::GEMINI_2_0_FLASH_LITE,
          gemini_module::GEMINI_1_5_FLASH,
          gemini_module::GEMINI_1_5_PRO
        ]
        defined_models.each do |model|
          expect(gemini_module::DESCRIPTIONS).to have_key(model)
          expect(gemini_module::DESCRIPTIONS[model]).to be_a(String)
          expect(gemini_module::DESCRIPTIONS[model]).not_to be_empty
        end
      end
    end

    describe "DISPLAY_NAMES hash" do
      it "is frozen" do
        expect(gemini_module::DISPLAY_NAMES).to be_frozen
      end

      it "contains display names for all defined models" do
        expect(gemini_module::DISPLAY_NAMES[gemini_module::GEMINI_2_0_FLASH_LITE]).to eq("Gemini 2.0 Flash Lite")
        expect(gemini_module::DISPLAY_NAMES[gemini_module::GEMINI_1_5_FLASH]).to eq("Gemini 1.5 Flash")
        expect(gemini_module::DISPLAY_NAMES[gemini_module::GEMINI_1_5_PRO]).to eq("Gemini 1.5 Pro")
      end

      it "has display names for all defined model constants" do
        defined_models = [
          gemini_module::GEMINI_2_0_FLASH_LITE,
          gemini_module::GEMINI_1_5_FLASH,
          gemini_module::GEMINI_1_5_PRO
        ]
        defined_models.each do |model|
          expect(gemini_module::DISPLAY_NAMES).to have_key(model)
          expect(gemini_module::DISPLAY_NAMES[model]).to be_a(String)
          expect(gemini_module::DISPLAY_NAMES[model]).not_to be_empty
        end
      end
    end
  end

  describe "LMStudio constants" do
    let(:lmstudio_module) { described_class::LMStudio }

    describe "model constants" do
      it "defines DEFAULT_MODEL" do
        expect(lmstudio_module::DEFAULT_MODEL).to eq("mistralai/devstral-small-2505")
      end

      it "defines DEVSTRAL_SMALL" do
        expect(lmstudio_module::DEVSTRAL_SMALL).to eq("mistralai/devstral-small-2505")
      end

      it "defines DEEPSEEK_R1_QWEN3_8B" do
        expect(lmstudio_module::DEEPSEEK_R1_QWEN3_8B).to eq("deepseek/deepseek-r1-0528-qwen3-8b")
      end

      it "default model matches one of the defined models" do
        defined_models = [
          lmstudio_module::DEVSTRAL_SMALL,
          lmstudio_module::DEEPSEEK_R1_QWEN3_8B
        ]
        expect(defined_models).to include(lmstudio_module::DEFAULT_MODEL)
      end
    end

    describe "DESCRIPTIONS hash" do
      it "is frozen" do
        expect(lmstudio_module::DESCRIPTIONS).to be_frozen
      end

      it "contains descriptions for all defined models" do
        expect(lmstudio_module::DESCRIPTIONS[lmstudio_module::DEVSTRAL_SMALL]).to eq("Specialized coding model, optimized for development tasks")
        expect(lmstudio_module::DESCRIPTIONS[lmstudio_module::DEEPSEEK_R1_QWEN3_8B]).to eq("Advanced reasoning model with strong performance")
      end

      it "has descriptions for all defined model constants" do
        defined_models = [
          lmstudio_module::DEVSTRAL_SMALL,
          lmstudio_module::DEEPSEEK_R1_QWEN3_8B
        ]
        defined_models.each do |model|
          expect(lmstudio_module::DESCRIPTIONS).to have_key(model)
          expect(lmstudio_module::DESCRIPTIONS[model]).to be_a(String)
          expect(lmstudio_module::DESCRIPTIONS[model]).not_to be_empty
        end
      end
    end

    describe "DISPLAY_NAMES hash" do
      it "is frozen" do
        expect(lmstudio_module::DISPLAY_NAMES).to be_frozen
      end

      it "contains display names for all defined models" do
        expect(lmstudio_module::DISPLAY_NAMES[lmstudio_module::DEVSTRAL_SMALL]).to eq("Devstral Small")
        expect(lmstudio_module::DISPLAY_NAMES[lmstudio_module::DEEPSEEK_R1_QWEN3_8B]).to eq("DeepSeek R1 Qwen3 8B")
      end

      it "has display names for all defined model constants" do
        defined_models = [
          lmstudio_module::DEVSTRAL_SMALL,
          lmstudio_module::DEEPSEEK_R1_QWEN3_8B
        ]
        defined_models.each do |model|
          expect(lmstudio_module::DISPLAY_NAMES).to have_key(model)
          expect(lmstudio_module::DISPLAY_NAMES[model]).to be_a(String)
          expect(lmstudio_module::DISPLAY_NAMES[model]).not_to be_empty
        end
      end
    end
  end

  describe "UsageInstructions constants" do
    let(:usage_module) { described_class::UsageInstructions }

    it "defines GEMINI_USAGE" do
      expect(usage_module::GEMINI_USAGE).to eq("llm-gemini-query \"your prompt\" --model MODEL_ID")
    end

    it "defines LM_STUDIO_USAGE" do
      expect(usage_module::LM_STUDIO_USAGE).to eq("llm-lmstudio-query \"your prompt\" --model MODEL_ID")
    end

    it "defines LM_STUDIO_SERVER_INFO" do
      expect(usage_module::LM_STUDIO_SERVER_INFO).to eq("Server: Ensure LM Studio is running at http://localhost:1234")
    end

    it "all usage instructions are strings" do
      expect(usage_module::GEMINI_USAGE).to be_a(String)
      expect(usage_module::LM_STUDIO_USAGE).to be_a(String)
      expect(usage_module::LM_STUDIO_SERVER_INFO).to be_a(String)
    end

    it "all usage instructions are non-empty" do
      expect(usage_module::GEMINI_USAGE).not_to be_empty
      expect(usage_module::LM_STUDIO_USAGE).not_to be_empty
      expect(usage_module::LM_STUDIO_SERVER_INFO).not_to be_empty
    end
  end

  describe "common constants" do
    it "defines LM_STUDIO_NOTE" do
      expect(described_class::LM_STUDIO_NOTE).to eq("Note: Models must be loaded in LM Studio before use.")
    end

    it "defines LM_STUDIO_SERVER_URL" do
      expect(described_class::LM_STUDIO_SERVER_URL).to eq("http://localhost:1234")
    end

    it "LM_STUDIO_SERVER_URL is a valid URL format" do
      expect(described_class::LM_STUDIO_SERVER_URL).to match(%r{\Ahttp://localhost:\d+\z})
    end

    it "all common constants are strings" do
      expect(described_class::LM_STUDIO_NOTE).to be_a(String)
      expect(described_class::LM_STUDIO_SERVER_URL).to be_a(String)
    end

    it "all common constants are non-empty" do
      expect(described_class::LM_STUDIO_NOTE).not_to be_empty
      expect(described_class::LM_STUDIO_SERVER_URL).not_to be_empty
    end
  end

  describe "constant consistency" do
    context "when checking data integrity" do
      it "ensures all Gemini models have both descriptions and display names" do
        gemini_models = [
          described_class::Gemini::GEMINI_2_0_FLASH_LITE,
          described_class::Gemini::GEMINI_1_5_FLASH,
          described_class::Gemini::GEMINI_1_5_PRO
        ]

        gemini_models.each do |model|
          expect(described_class::Gemini::DESCRIPTIONS).to have_key(model),
            "Missing description for Gemini model: #{model}"
          expect(described_class::Gemini::DISPLAY_NAMES).to have_key(model),
            "Missing display name for Gemini model: #{model}"
        end
      end

      it "ensures all LMStudio models have both descriptions and display names" do
        lmstudio_models = [
          described_class::LMStudio::DEVSTRAL_SMALL,
          described_class::LMStudio::DEEPSEEK_R1_QWEN3_8B
        ]

        lmstudio_models.each do |model|
          expect(described_class::LMStudio::DESCRIPTIONS).to have_key(model),
            "Missing description for LMStudio model: #{model}"
          expect(described_class::LMStudio::DISPLAY_NAMES).to have_key(model),
            "Missing display name for LMStudio model: #{model}"
        end
      end

      it "ensures no orphaned entries in descriptions or display names" do
        # Gemini
        gemini_models = [
          described_class::Gemini::GEMINI_2_0_FLASH_LITE,
          described_class::Gemini::GEMINI_1_5_FLASH,
          described_class::Gemini::GEMINI_1_5_PRO
        ]
        expect(described_class::Gemini::DESCRIPTIONS.keys).to match_array(gemini_models)
        expect(described_class::Gemini::DISPLAY_NAMES.keys).to match_array(gemini_models)

        # LMStudio
        lmstudio_models = [
          described_class::LMStudio::DEVSTRAL_SMALL,
          described_class::LMStudio::DEEPSEEK_R1_QWEN3_8B
        ]
        expect(described_class::LMStudio::DESCRIPTIONS.keys).to match_array(lmstudio_models)
        expect(described_class::LMStudio::DISPLAY_NAMES.keys).to match_array(lmstudio_models)
      end
    end
  end

  describe "edge cases and validation" do
    context "when accessing undefined constants" do
      it "does not define any nil or empty string constants" do
        # Spot check key constants to ensure they're not nil or empty
        expect(described_class::Gemini::DEFAULT_MODEL).not_to be_nil
        expect(described_class::Gemini::DEFAULT_MODEL).not_to be_empty
        expect(described_class::LMStudio::DEFAULT_MODEL).not_to be_nil
        expect(described_class::LMStudio::DEFAULT_MODEL).not_to be_empty
        expect(described_class::LM_STUDIO_SERVER_URL).not_to be_nil
        expect(described_class::LM_STUDIO_SERVER_URL).not_to be_empty
      end

      it "raises NameError for undefined constants" do
        expect { described_class::Gemini::UNDEFINED_MODEL }.to raise_error(NameError)
        expect { described_class::LMStudio::UNDEFINED_MODEL }.to raise_error(NameError)
        expect { described_class::UNDEFINED_CONSTANT }.to raise_error(NameError)
      end

      it "handles undefined hash keys gracefully" do
        expect(described_class::Gemini::DESCRIPTIONS["undefined-model"]).to be_nil
        expect(described_class::Gemini::DISPLAY_NAMES["undefined-model"]).to be_nil
        expect(described_class::LMStudio::DESCRIPTIONS["undefined-model"]).to be_nil
        expect(described_class::LMStudio::DISPLAY_NAMES["undefined-model"]).to be_nil
      end
    end

    context "when validating constant types" do
      it "ensures all model IDs are strings" do
        expect(described_class::Gemini::GEMINI_2_0_FLASH_LITE).to be_a(String)
        expect(described_class::Gemini::GEMINI_1_5_FLASH).to be_a(String)
        expect(described_class::Gemini::GEMINI_1_5_PRO).to be_a(String)
        expect(described_class::LMStudio::DEVSTRAL_SMALL).to be_a(String)
        expect(described_class::LMStudio::DEEPSEEK_R1_QWEN3_8B).to be_a(String)
      end

      it "ensures all hashes are proper Hash types" do
        expect(described_class::Gemini::DESCRIPTIONS).to be_a(Hash)
        expect(described_class::Gemini::DISPLAY_NAMES).to be_a(Hash)
        expect(described_class::LMStudio::DESCRIPTIONS).to be_a(Hash)
        expect(described_class::LMStudio::DISPLAY_NAMES).to be_a(Hash)
      end

      it "ensures all hash values are strings" do
        described_class::Gemini::DESCRIPTIONS.values.each do |value|
          expect(value).to be_a(String)
        end
        described_class::Gemini::DISPLAY_NAMES.values.each do |value|
          expect(value).to be_a(String)
        end
        described_class::LMStudio::DESCRIPTIONS.values.each do |value|
          expect(value).to be_a(String)
        end
        described_class::LMStudio::DISPLAY_NAMES.values.each do |value|
          expect(value).to be_a(String)
        end
      end
    end
  end
end
