# Test fixture for Ruby module renaming
# This file contains various references to CodingAgentTools that should be renamed to AceTools

require 'coding_agent_tools'
require_relative 'coding_agent_tools/version'
require "coding_agent_tools/cli"

module CodingAgentTools
  class Configuration
    attr_accessor :api_key

    def initialize
      @api_key = nil
      @base_path = 'coding_agent_tools/config'
    end
  end

  module Cli
    class Command
      def self.run
        puts "Running CodingAgentTools command"
        CodingAgentTools::VERSION
      end
    end
  end

  class Error < StandardError; end

  class Client < CodingAgentTools::BaseClient
    include CodingAgentTools::HTTPHelpers

    def initialize
      super
      @name = "CodingAgentTools Client"
    end

    def execute
      # This is a CodingAgentTools method
      result = CodingAgentTools.process_data
      CodingAgentTools::Logger.info("Processing with CodingAgentTools")
      return result
    end
  end
end

# Namespace references
CodingAgentTools::Configuration.new
::CodingAgentTools::Error

# Module extensions
class MyApp
  include CodingAgentTools
  extend CodingAgentTools::Cli
  prepend CodingAgentTools::HTTPHelpers
end

# Inheritance
class CustomClient < CodingAgentTools::Client
  def initialize
    super
    @tool = 'coding_agent_tools'
  end
end

# Autoload
module MyModule
  autoload :CodingAgentTools, 'coding_agent_tools'
end

# String references (common in specs)
describe "CodingAgentTools" do
  it "should have correct name" do
    expect(described_class.name).to eq("CodingAgentTools")
    expect(tool_name).to eq('coding_agent_tools')
  end
end

# Comments
# The CodingAgentTools module provides utilities for coding agents
# See coding_agent_tools documentation for more details
# Run with: coding-agent-tools --help

# Hash keys and values
CONFIG = {
  'module' => 'CodingAgentTools',
  'path' => 'coding_agent_tools',
  'executable' => 'coding-agent-tools'
}

# Method calls
CodingAgentTools.configure do |config|
  config.api_key = "test"
end

result = CodingAgentTools::Client.new.execute

# Gem specification
Gem::Specification.new do |spec|
  spec.name = "coding_agent_tools"
  spec.require_paths = ["lib/coding_agent_tools"]
  spec.executables = ["coding-agent-tools"]
end