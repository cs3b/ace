# frozen_string_literal: true

# Temporarily disable Zeitwerk due to conflicts with autoload
# require "zeitwerk"
# 
# loader = Zeitwerk::Loader.new
# loader.push_dir(__dir__)
# 
# loader.inflector.inflect(
#   "json_formatter" => "JSONFormatter",
#   "http_client" => "HTTPClient",
#   "http_request_builder" => "HTTPRequestBuilder",
#   "api_credentials" => "APICredentials",
#   "api_response_parser" => "APIResponseParser",
#   "xdg_directory_resolver" => "XDGDirectoryResolver"
# )
# loader.setup

# Explicitly require modules that define autoloads
require_relative "coding_agent_tools/constants/cli_constants"
require_relative "coding_agent_tools/constants/model_constants"
require_relative "coding_agent_tools/atoms"
require_relative "coding_agent_tools/molecules"
require_relative "coding_agent_tools/organisms"

module CodingAgentTools
  # Your code goes here...
  # For example, a global configuration method could be defined here:
  #
  # class << self
  #   attr_accessor :configuration
  # end
  #
  # def self.configure
  #   self.configuration ||= Configuration.new
  #   yield(configuration) if block_given?
  # end
  #
  # class Configuration
  #   attr_accessor :api_key
  #
  #   def initialize
  #     @api_key = nil
  #   end
  # end
end
