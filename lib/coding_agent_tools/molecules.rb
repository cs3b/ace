# frozen_string_literal: true

require_relative "molecules/executable_wrapper"

module CodingAgentTools
  module Molecules
    # Autoload coverage analysis molecules
    autoload :CoverageDataProcessor, "coding_agent_tools/molecules/coverage_data_processor"
    autoload :MethodCoverageMapper, "coding_agent_tools/molecules/method_coverage_mapper"
    autoload :FileAnalyzer, "coding_agent_tools/molecules/file_analyzer"
    autoload :ReportFormatter, "coding_agent_tools/molecules/report_formatter"

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

    # Autoload context molecules
    module Context
      autoload :ContextAggregator, "coding_agent_tools/molecules/context/context_aggregator"
      autoload :OutputFormatter, "coding_agent_tools/molecules/context/output_formatter"
      autoload :AgentContextExtractor, "coding_agent_tools/molecules/context/agent_context_extractor"
    end

    # Autoload MCP molecules
    module Mcp
      autoload :MessageHandler, "coding_agent_tools/molecules/mcp/message_handler"
      autoload :ToolWrapper, "coding_agent_tools/molecules/mcp/tool_wrapper"
      autoload :SecurityValidator, "coding_agent_tools/molecules/mcp/security_validator"
    end

    # Autoload agents molecules
    module Agents
      autoload :AgentParser, "coding_agent_tools/molecules/agents/agent_parser"
      autoload :MetadataExtractor, "coding_agent_tools/molecules/agents/metadata_extractor"
      autoload :ContextDefinitionParser, "coding_agent_tools/molecules/agents/context_definition_parser"
    end

    # Autoload LLM-related molecules
    autoload :ClientFactory, "coding_agent_tools/molecules/client_factory"
    autoload :ProviderModelParser, "coding_agent_tools/molecules/provider_model_parser"
  end
end
