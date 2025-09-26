# frozen_string_literal: true

require "ace/llm"
require_relative "cli/version"

module Ace
  module LLM
    module Providers
      module CLI
        # Main entry point for CLI providers
        # Auto-registers providers when this file is required
        class << self
          def register_providers
            # Register provider configurations in ace-llm's registry
            # by placing YAML files in the providers directory
            register_provider_configs

            # Require all CLI provider client classes
            require_cli_providers
          end

          private

          def register_provider_configs
            # Get the providers directory in this gem
            providers_dir = File.expand_path("../../../../../providers", __FILE__)

            # Ensure directory exists
            return unless File.directory?(providers_dir)

            # Add to ace-llm's config paths if possible
            if defined?(Ace::LLM::Molecules::ClientRegistry)
              # This would need ace-llm to expose a way to add config paths dynamically
              # For now, we'll rely on YAML configs being copied or symlinked
            end
          end

          def require_cli_providers
            # Require each CLI provider client
            providers = %w[
              claude_code_client
              codex_client
              open_code_client
              codex_oss_client
            ]

            providers.each do |provider|
              begin
                require_relative "cli/#{provider}"
              rescue LoadError => e
                warn "Could not load CLI provider #{provider}: #{e.message}"
              end
            end
          end
        end

        # Auto-register on require
        register_providers
      end
    end
  end
end