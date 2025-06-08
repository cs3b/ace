# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # Autoload all atom classes
    autoload :HTTPClient, "coding_agent_tools/atoms/http_client"
    autoload :JSONFormatter, "coding_agent_tools/atoms/json_formatter"
    autoload :EnvReader, "coding_agent_tools/atoms/env_reader"
  end
end
