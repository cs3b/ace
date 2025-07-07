# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Autoload code review models
    module Code
      autoload :ReviewSession, "coding_agent_tools/models/code/review_session"
      autoload :ReviewTarget, "coding_agent_tools/models/code/review_target"
      autoload :ReviewContext, "coding_agent_tools/models/code/review_context"
      autoload :ReviewPrompt, "coding_agent_tools/models/code/review_prompt"
    end
  end
end
