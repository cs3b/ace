# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    # Autoload code review organisms
    module Code
      autoload :ReviewManager, "coding_agent_tools/organisms/code/review_manager"
      autoload :SessionManager, "coding_agent_tools/organisms/code/session_manager"
      autoload :ContentExtractor, "coding_agent_tools/organisms/code/content_extractor"
      autoload :ContextLoader, "coding_agent_tools/organisms/code/context_loader"
      autoload :PromptBuilder, "coding_agent_tools/organisms/code/prompt_builder"
    end

    # Autoload task management organisms
    module TaskManagement
      autoload :TemplateSynchronizer, "coding_agent_tools/organisms/task_management/template_synchronizer"
    end
  end
end
