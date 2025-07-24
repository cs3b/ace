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

    # Autoload taskflow management molecules
    module TaskflowManagement
      autoload :FileSynchronizer, "coding_agent_tools/molecules/taskflow_management/file_synchronizer"
      autoload :GitLogFormatter, "coding_agent_tools/molecules/taskflow_management/git_log_formatter"
      autoload :ReleasePathResolver, "coding_agent_tools/molecules/taskflow_management/release_path_resolver"
      autoload :TaskDependencyChecker, "coding_agent_tools/molecules/taskflow_management/task_dependency_checker"
      autoload :TaskFileLoader, "coding_agent_tools/molecules/taskflow_management/task_file_loader"
      autoload :TaskIdGenerator, "coding_agent_tools/molecules/taskflow_management/task_id_generator"
      autoload :TaskFilterEngine, "coding_agent_tools/molecules/taskflow_management/task_filter_engine"
      autoload :TaskFilterParser, "coding_agent_tools/molecules/taskflow_management/task_filter_parser"
      autoload :TaskSortEngine, "coding_agent_tools/molecules/taskflow_management/task_sort_engine"
      autoload :TaskSortParser, "coding_agent_tools/molecules/taskflow_management/task_sort_parser"
      autoload :XmlTemplateParser, "coding_agent_tools/molecules/taskflow_management/xml_template_parser"
    end

    # Autoload navigation molecules
    autoload :TreeConfigLoader, "coding_agent_tools/molecules/tree_config_loader"
    autoload :PathConfigLoader, "coding_agent_tools/molecules/path_config_loader"
    autoload :ProjectSandbox, "coding_agent_tools/molecules/project_sandbox"
    autoload :PathResolver, "coding_agent_tools/molecules/path_resolver"
    autoload :PathAutocorrector, "coding_agent_tools/molecules/path_autocorrector"
  end
end
