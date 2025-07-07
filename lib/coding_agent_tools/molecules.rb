# frozen_string_literal: true

require_relative "molecules/executable_wrapper"

module CodingAgentTools
  module Molecules
    # Autoload code review molecules
    module Code
      autoload :SessionDirectoryBuilder, "coding_agent_tools/molecules/code/session_directory_builder"
      autoload :GitDiffExtractor, "coding_agent_tools/molecules/code/git_diff_extractor"
      autoload :FilePatternExtractor, "coding_agent_tools/molecules/code/file_pattern_extractor"
      autoload :ProjectContextLoader, "coding_agent_tools/molecules/code/project_context_loader"
      autoload :PromptCombiner, "coding_agent_tools/molecules/code/prompt_combiner"
    end
  end
end
