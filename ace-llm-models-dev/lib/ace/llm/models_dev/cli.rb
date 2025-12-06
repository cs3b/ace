# frozen_string_literal: true

require "thor"
require "json"

module Ace
  module LLM
    module ModelsDev
      # CLI for ace-llm-models
      class CLI < Thor
        def self.exit_on_failure?
          false
        end

        # Register subcommands
        desc "cache SUBCOMMAND", "Manage local cache"
        subcommand "cache", Commands::CacheCLI

        desc "providers SUBCOMMAND", "Manage providers"
        subcommand "providers", Commands::ProvidersCLI

        desc "models SUBCOMMAND", "Work with models"
        subcommand "models", Commands::ModelsCLI

        # Top-level shortcuts for common operations
        desc "search [QUERY]", "Search models (shortcut for: models search)"
        option :provider, type: :string, aliases: "-p", desc: "Limit to provider"
        option :limit, type: :numeric, aliases: "-l", default: 20, desc: "Max results"
        option :filter, type: :array, aliases: "-f", desc: "Filter by key:value (repeatable)"
        option :json, type: :boolean, desc: "Output as JSON"
        def search(query = nil)
          Commands::ModelsCLI.new([], options).search(query)
        end

        desc "info MODEL_ID", "Show model info (shortcut for: models info)"
        option :full, type: :boolean, desc: "Show complete details"
        option :json, type: :boolean, desc: "Output as JSON"
        def info(model_id)
          Commands::ModelsCLI.new([], options).info(model_id)
        end

        desc "sync", "Sync from models.dev (shortcut for: cache sync)"
        option :force, type: :boolean, aliases: "-f", desc: "Force sync even if cache is fresh"
        option :json, type: :boolean, desc: "Output as JSON"
        def sync
          Commands::CacheCLI.new([], options).sync
        end

        desc "version", "Show version"
        def version
          puts "ace-llm-models-dev #{VERSION}"
        end

        desc "help [COMMAND]", "Describe available commands"
        def help(command = nil)
          if command.nil?
            puts "ace-llm-models - Query models.dev data"
            puts
            puts "Quick Start:"
            puts "  ace-llm-models sync                              # Download model data"
            puts "  ace-llm-models search gpt-4                      # Search for models"
            puts "  ace-llm-models info openai:gpt-4o                # Get model details"
            puts "  ace-llm-models providers sync -p openai --apply  # Sync provider config"
            puts
          end
          super
        end

        # Default to help
        default_task :help
      end
    end
  end
end
