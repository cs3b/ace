# frozen_string_literal: true

require "thor"
require "json"

module Ace
  module LLM
    module ModelsDev
      module Commands
        # Provider management subcommands
        class ProvidersCLI < Thor
          def self.exit_on_failure?
            false
          end

          desc "list", "List all providers with model counts"
          option :json, type: :boolean, desc: "Output as JSON"
          def list
            cache_manager = Molecules::CacheManager.new

            unless cache_manager.cached?
              warn "No cache data. Run 'ace-llm-models cache sync' first."
              return 1
            end

            providers = cache_manager.list_providers

            if options[:json]
              puts JSON.pretty_generate(providers)
              return 0
            end

            puts "Providers (#{providers.size}):"
            providers.sort_by { |p| -p[:model_count] }.each do |provider|
              puts "  #{provider[:id]}: #{provider[:model_count]} models"
            end
            0
          rescue CacheError => e
            warn "Error: #{e.message}"
            return 1
          end

          desc "show PROVIDER", "Show provider details and models"
          option :json, type: :boolean, desc: "Output as JSON"
          def show(provider_id)
            cache_manager = Molecules::CacheManager.new

            unless cache_manager.cached?
              warn "No cache data. Run 'ace-llm-models cache sync' first."
              return 1
            end

            provider_data = cache_manager.get_provider(provider_id)

            unless provider_data
              warn "Provider '#{provider_id}' not found"
              return 1
            end

            if options[:json]
              puts JSON.pretty_generate(provider_data)
              return 0
            end

            puts "Provider: #{provider_id}"
            puts "Models (#{provider_data[:models].size}):"
            provider_data[:models].each do |model|
              status = model[:deprecated] ? " (deprecated)" : ""
              puts "  #{model[:id]}#{status}"
              puts "    #{model[:name]}"
            end
            0
          rescue CacheError => e
            warn "Error: #{e.message}"
            return 1
          end

          desc "sync", "Sync provider YAML configs with models.dev"
          long_desc <<-LONGDESC
Compare local provider YAML configs with models.dev data and show differences.
By default runs in dry-run mode; use --apply to write changes.

Examples:
\x5  # Dry-run: see what would change
\x5  ace-llm-models providers sync

\x5  # Sync specific provider only
\x5  ace-llm-models providers sync -p openai

\x5  # Show models released after a date
\x5  ace-llm-models providers sync --since 2024-01-01

\x5  # Show all models (ignore release date filter)
\x5  ace-llm-models providers sync --all

\x5  # Apply changes to config files
\x5  ace-llm-models providers sync --apply

\x5  # Apply and commit changes
\x5  ace-llm-models providers sync --apply --commit
          LONGDESC
          option :apply, type: :boolean, desc: "Apply changes to config files (default: dry-run)"
          option :commit, type: :boolean, desc: "Commit changes via ace-git-commit"
          option :provider, type: :string, aliases: "-p", desc: "Sync specific provider only"
          option :config_dir, type: :string, desc: "Target config directory"
          option :all, type: :boolean, desc: "Show all models regardless of release date"
          option :since, type: :string, desc: "Show models released after DATE (YYYY-MM-DD)"
          option :json, type: :boolean, desc: "Output as JSON"
          def sync
            orchestrator = Organisms::ProviderSyncOrchestrator.new

            result = orchestrator.sync(
              config_dir: options[:config_dir],
              provider: options[:provider],
              apply: options[:apply],
              commit: options[:commit],
              show_all: options[:all],
              since: options[:since]
            )

            if result[:status] == :error
              warn "Error: #{result[:message]}"
              return 1
            end

            if options[:json]
              puts JSON.pretty_generate(result)
            else
              puts orchestrator.format_result(result)
            end
            0
          rescue CacheError => e
            warn "Error: #{e.message}"
            warn "Run 'ace-llm-models cache sync' first to download model data."
            return 1
          rescue ConfigError => e
            warn "Config error: #{e.message}"
            return 1
          end

          # Default to help
          default_task :help
        end
      end
    end
  end
end
