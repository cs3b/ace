# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "json_formatter" => "JSONFormatter",
  "http_client" => "HTTPClient",
  "api_credentials" => "APICredentials",
  "api_response_parser" => "APIResponseParser"
)
loader.setup

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
