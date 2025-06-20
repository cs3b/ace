# frozen_string_literal: true

require "dry/cli"
require_relative "version"
require_relative "error"

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

      # Deferred command registration to avoid circular dependencies
      def self.register_llm_commands
        return if @llm_commands_registered

        require_relative "cli/commands/llm/query"
        require_relative "cli/commands/llm/models"

        register "llm", aliases: [] do |prefix|
          prefix.register "query", Commands::LLM::Query
          prefix.register "models", Commands::LLM::Models
        end

        @llm_commands_registered = true
      end

      def self.register_lms_commands
        return if @lms_commands_registered

        require_relative "cli/commands/lms/query"

        register "lms", aliases: [] do |prefix|
          prefix.register "query", Commands::LMS::Query
        end

        @lms_commands_registered = true
      end

      # Ensure commands are registered when CLI is used
      def self.call(*args)
        register_llm_commands
        register_lms_commands
        super
      end
    end
  end
end
