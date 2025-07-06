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

        require_relative "cli/commands/llm/models"
        require_relative "cli/commands/llm/query"
        require_relative "cli/commands/llm/usage_report"

        register "llm", aliases: [] do |prefix|
          prefix.register "models", Commands::LLM::Models
          prefix.register "query", Commands::LLM::Query
          prefix.register "usage_report", Commands::LLM::UsageReport
        end

        @llm_commands_registered = true
      end

      def self.register_task_commands
        return if @task_commands_registered

        require_relative "cli/commands/task/next"
        require_relative "cli/commands/task/recent"
        require_relative "cli/commands/task/all"
        require_relative "cli/commands/task/generate_id"

        register "task", aliases: [] do |prefix|
          prefix.register "next", Commands::Task::Next
          prefix.register "recent", Commands::Task::Recent
          prefix.register "all", Commands::Task::All
          prefix.register "generate-id", Commands::Task::GenerateId
        end

        @task_commands_registered = true
      end

      def self.register_binstub_commands
        return if @binstub_commands_registered

        require_relative "cli/commands/install_binstubs"

        register "install-binstubs", Commands::InstallBinstubs

        @binstub_commands_registered = true
      end

      # Ensure commands are registered when CLI is used
      def self.call(*args)
        register_llm_commands
        register_task_commands
        register_binstub_commands
        super
      end
    end
  end
end
