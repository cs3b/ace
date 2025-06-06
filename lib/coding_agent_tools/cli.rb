# frozen_string_literal: true

require "dry/cli"
require_relative "../coding_agent_tools" # To access VERSION and other parts of the gem

module CodingAgentTools
  module Cli
    # Module to hold all CLI command definitions
    module Commands
      extend Dry::CLI::Registry

      # Simple command to display the gem version
      class Version < Dry::CLI::Command
        desc "Print version"

        def call(*)
          puts CodingAgentTools::VERSION
        end
      end

      # Registering the version command
      register "version", Version, aliases: ["v", "-v", "--version"]

      # Future command namespaces will be registered here.
      # For example:
      #
      # module LLM
      #   extend Dry::CLI::Registry
      #
      #   class Query < Dry::CLI::Command
      #     desc "Query a large language model"
      #     # ...
      #     def call(**options)
      #       # ...
      #     end
      #   end
      #   register "query", Query
      # end
      # register "llm", aliases: [] do |prefix|
      #   prefix.register "query", LLM::Query
      # end
      #
      # Similar structures for SCM, Task, Project etc.
    end
  end
end
