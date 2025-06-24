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
        require_relative "cli/commands/llm/unified_query"

        register "llm", aliases: [] do |prefix|
          prefix.register "models", Commands::LLM::Models
          prefix.register "unified_query", Commands::LLM::UnifiedQuery
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

      def self.register_openai_commands
        return if @openai_commands_registered

        require_relative "cli/commands/openai/query"

        register "openai", aliases: [] do |prefix|
          prefix.register "query", Commands::OpenAI::Query
        end

        @openai_commands_registered = true
      end

      def self.register_anthropic_commands
        return if @anthropic_commands_registered

        require_relative "cli/commands/anthropic/query"

        register "anthropic", aliases: [] do |prefix|
          prefix.register "query", Commands::Anthropic::Query
        end

        @anthropic_commands_registered = true
      end

      def self.register_mistral_commands
        return if @mistral_commands_registered

        require_relative "cli/commands/mistral/query"

        register "mistral", aliases: [] do |prefix|
          prefix.register "query", Commands::Mistral::Query
        end

        @mistral_commands_registered = true
      end

      def self.register_together_ai_commands
        return if @together_ai_commands_registered

        require_relative "cli/commands/together_ai/query"

        register "together_ai", aliases: [] do |prefix|
          prefix.register "query", Commands::TogetherAI::Query
        end

        @together_ai_commands_registered = true
      end


      def self.register_google_commands
        return if @google_commands_registered

        require_relative "cli/commands/google/query"

        register "google", aliases: [] do |prefix|
          prefix.register "query", Commands::Google::Query
        end

        @google_commands_registered = true
      end

      # Ensure commands are registered when CLI is used
      def self.call(*args)
        register_llm_commands
        register_lms_commands
        register_openai_commands
        register_anthropic_commands
        register_mistral_commands
        register_together_ai_commands
        register_google_commands
        super
      end
    end
  end
end
