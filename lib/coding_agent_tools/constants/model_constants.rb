# frozen_string_literal: true

module CodingAgentTools
  module Constants
    # Model constants for centralized model definitions and fallback configurations
    module ModelConstants
      # Gemini model constants
      module Gemini
        DEFAULT_MODEL = "gemini-2.0-flash-lite"

        # Model IDs
        GEMINI_2_0_FLASH_LITE = "gemini-2.0-flash-lite"
        GEMINI_1_5_FLASH = "gemini-1.5-flash"
        GEMINI_1_5_PRO = "gemini-1.5-pro"

        # Model descriptions
        DESCRIPTIONS = {
          GEMINI_2_0_FLASH_LITE => "Fast and efficient model, good for most tasks",
          GEMINI_1_5_FLASH => "Fast multimodal model optimized for speed",
          GEMINI_1_5_PRO => "Mid-size multimodal model for complex reasoning tasks"
        }.freeze

        # Model display names
        DISPLAY_NAMES = {
          GEMINI_2_0_FLASH_LITE => "Gemini 2.0 Flash Lite",
          GEMINI_1_5_FLASH => "Gemini 1.5 Flash",
          GEMINI_1_5_PRO => "Gemini 1.5 Pro"
        }.freeze
      end

      # LM Studio model constants
      module LMStudio
        DEFAULT_MODEL = "mistralai/devstral-small-2505"

        # Model IDs
        DEVSTRAL_SMALL = "mistralai/devstral-small-2505"
        DEEPSEEK_R1_QWEN3_8B = "deepseek/deepseek-r1-0528-qwen3-8b"

        # Model descriptions
        DESCRIPTIONS = {
          DEVSTRAL_SMALL => "Specialized coding model, optimized for development tasks",
          DEEPSEEK_R1_QWEN3_8B => "Advanced reasoning model with strong performance"
        }.freeze

        # Model display names
        DISPLAY_NAMES = {
          DEVSTRAL_SMALL => "Devstral Small",
          DEEPSEEK_R1_QWEN3_8B => "DeepSeek R1 Qwen3 8B"
        }.freeze
      end

      # Usage instructions
      module UsageInstructions
        GEMINI_USAGE = "llm-gemini-query \"your prompt\" --model MODEL_ID"
        LM_STUDIO_USAGE = "llm-lmstudio-query \"your prompt\" --model MODEL_ID"
        LM_STUDIO_SERVER_INFO = "Server: Ensure LM Studio is running at http://localhost:1234"
      end

      # Common model-related messages
      LM_STUDIO_NOTE = "Note: Models must be loaded in LM Studio before use."
      LM_STUDIO_SERVER_URL = "http://localhost:1234"
    end
  end
end
