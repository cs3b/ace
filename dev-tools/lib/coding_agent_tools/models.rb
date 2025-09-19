# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Autoload core models
    autoload :Result, "coding_agent_tools/models/result"

    # Autoload coverage analysis models
    autoload :CoverageResult, "coding_agent_tools/models/coverage_result"
    autoload :MethodCoverage, "coding_agent_tools/models/method_coverage"
    autoload :CoverageAnalysisResult, "coding_agent_tools/models/coverage_analysis_result"

    # Autoload code review models
    module Code
      autoload :ReviewSession, "coding_agent_tools/models/code/review_session"
      autoload :ReviewTarget, "coding_agent_tools/models/code/review_target"
      autoload :ReviewContext, "coding_agent_tools/models/code/review_context"
      autoload :ReviewPrompt, "coding_agent_tools/models/code/review_prompt"
    end
  end
end
