# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module Providers
            # Sync provider YAML configs with models.dev
            class Sync < Ace::Support::Cli::Command
              include Ace::Core::CLI::Base

              desc "Sync provider YAML configs with models.dev"

              option :apply, type: :boolean, desc: "Apply changes to config files (default: dry-run)"
              option :commit, type: :boolean, desc: "Commit changes via ace-git-commit"
              option :provider, type: :string, aliases: ["-p"], desc: "Sync specific provider only"
              option :config_dir, type: :string, desc: "Target config directory"
              option :all, type: :boolean, desc: "Show all models regardless of release date"
              option :since, type: :string, desc: "Show models released after DATE (YYYY-MM-DD)"
              option :json, type: :boolean, desc: "Output as JSON"

              example [
                "                          # Dry-run: see what would change",
                "-p openai                 # Sync specific provider only",
                "--since 2024-01-01        # Show models released after a date",
                "--all                     # Show all models (ignore release date filter)",
                "--apply                   # Apply changes to config files",
                "--apply --commit          # Apply and commit changes"
              ]

              def call(**options)
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
                  raise Ace::Core::CLI::Error.new(result[:message])
                end

                if options[:json]
                  puts JSON.pretty_generate(result)
                else
                  puts orchestrator.format_result(result)
                end
              rescue CacheError => e
                raise Ace::Core::CLI::Error.new("#{e.message}. Run 'ace-models cache sync' first to download model data.")
              rescue ConfigError => e
                raise Ace::Core::CLI::Error.new("Config error: #{e.message}")
              end
            end
          end
        end
      end
    end
  end
end
