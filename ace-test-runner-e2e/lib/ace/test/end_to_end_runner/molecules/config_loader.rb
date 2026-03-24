# frozen_string_literal: true

require "ace/support/config"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Load configuration using Ace::Support::Config.create() API
        # Follows ADR-022: Configuration Default and Override Pattern
        #
        # Configuration priority (highest to lowest):
        # 1. CLI options (handled by callers)
        # 2. Project config: .ace/e2e-runner/config.yml
        # 3. Gem defaults: ace-test-runner-e2e/.ace-defaults/e2e-runner/config.yml
        class ConfigLoader
          # Load and return merged config hash
          # @return [Hash] Configuration with string keys
          def self.load
            new.load
          end

          # @return [String] Default provider from config
          def self.default_provider
            config = load
            config.dig("execution", "provider") || "claude:sonnet"
          end

          # @return [Integer] Default timeout from config
          def self.default_timeout
            config = load
            config.dig("execution", "timeout") || 300
          end

          # @return [Integer] Default parallel count from config
          def self.default_parallel
            config = load
            config.dig("execution", "parallel") || 3
          end

          # @return [Array<String>] CLI provider names
          def self.cli_providers
            config = load
            config.dig("providers", "cli") || %w[claude gemini codex codexoss opencode pi]
          end

          # @param provider_name [String] Provider name (e.g., "claude")
          # @return [String, nil] Required CLI args for provider
          def self.cli_args_for(provider_name)
            config = load
            config.dig("providers", "cli_args", provider_name)
          end

          # Load merged config from cascade
          # @return [Hash] Configuration with string keys
          def load
            gem_root = Gem.loaded_specs["ace-test-runner-e2e"]&.gem_dir ||
              File.expand_path("../../../../..", __dir__)

            resolver = Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: gem_root
            )

            resolver.resolve_namespace("e2e-runner").data
          rescue => e
            warn "Warning: Could not load e2e-runner config: #{e.message}" if ENV["DEBUG"]
            {}
          end
        end
      end
    end
  end
end
