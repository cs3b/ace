# frozen_string_literal: true

require "ace/llm"
require_relative "cli/version"

module Ace
  module LLM
    module Providers
      module CLI
        # Main entry point for CLI providers
        # Simply requires the provider client classes
        # Configuration comes from YAML files in .ace.example/llm/providers/
        class << self
          def setup
            # Require all CLI provider client classes
            require_cli_providers
          end

          private

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

        # Auto-setup on require
        setup
      end
    end
  end
end