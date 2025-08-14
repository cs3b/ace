# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    # Autoload coverage analysis organisms
    autoload :CoverageAnalyzer, "coding_agent_tools/organisms/coverage_analyzer"
    autoload :UndercoveredItemsExtractor, "coding_agent_tools/organisms/undercovered_items_extractor"
    autoload :CoverageReportGenerator, "coding_agent_tools/organisms/coverage_report_generator"

    # Autoload code review organisms
    module Code
      autoload :ReviewManager, "coding_agent_tools/organisms/code/review_manager"
      autoload :SessionManager, "coding_agent_tools/organisms/code/session_manager"
      autoload :ContentExtractor, "coding_agent_tools/organisms/code/content_extractor"
      autoload :ContextLoader, "coding_agent_tools/organisms/code/context_loader"
      autoload :PromptBuilder, "coding_agent_tools/organisms/code/prompt_builder"
    end

    # Autoload taskflow management organisms
    module TaskflowManagement
      autoload :TaskManager, "coding_agent_tools/organisms/taskflow_management/task_manager"
      autoload :ReleaseManager, "coding_agent_tools/organisms/taskflow_management/release_manager"
      autoload :TemplateSynchronizer, "coding_agent_tools/organisms/taskflow_management/template_synchronizer"
    end

    # Autoload context organisms
    autoload :ContextLoader, "coding_agent_tools/organisms/context_loader"

    # Autoload MCP organisms
    module Mcp
      autoload :ProxyServer, "coding_agent_tools/organisms/mcp/proxy_server"
      autoload :HttpTransport, "coding_agent_tools/organisms/mcp/http_transport"
      autoload :StdioTransport, "coding_agent_tools/organisms/mcp/stdio_transport"
    end
  end
end
