# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # Autoload all molecule classes
    autoload :APICredentials, "coding_agent_tools/molecules/api_credentials"
    autoload :HTTPRequestBuilder, "coding_agent_tools/molecules/http_request_builder"
    autoload :APIResponseParser, "coding_agent_tools/molecules/api_response_parser"
  end
end
