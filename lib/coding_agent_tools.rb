# frozen_string_literal: true

require_relative "coding_agent_tools/version"
require_relative "coding_agent_tools/error"

module CodingAgentTools
  # Autoload core components
  autoload :Atoms, "coding_agent_tools/atoms"
  autoload :Molecules, "coding_agent_tools/molecules"
  autoload :Organisms, "coding_agent_tools/organisms"
  autoload :Ecosystems, "coding_agent_tools/ecosystems"
  autoload :Models, "coding_agent_tools/models"
  autoload :Cli, "coding_agent_tools/cli"

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
