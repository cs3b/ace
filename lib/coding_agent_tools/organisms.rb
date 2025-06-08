# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    # Autoload all organism classes
    autoload :GeminiClient, "coding_agent_tools/organisms/gemini_client"
    autoload :PromptProcessor, "coding_agent_tools/organisms/prompt_processor"
  end
end
