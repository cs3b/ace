# frozen_string_literal: true

require_relative "../atoms/provider_detector"
require_relative "../atoms/auth_checker"

module Ace
  module Llm
    module Providers
      module Cli
        module Molecules
          # Orchestrates provider detection and authentication checking
          class HealthChecker
            PROVIDERS = {
              "claude" => {
                name: "Claude Code",
                provider: "claude",
                check_cmd: ["claude", "--version"],
                install_cmd: "npm install -g @anthropic-ai/claude-cli"
              },
              "codex" => {
                name: "Codex",
                provider: "codex",
                check_cmd: ["codex", "--version"],
                install_cmd: "npm install -g @openai/codex",
                install_url: "https://codex.ai"
              },
              "opencode" => {
                name: "OpenCode",
                provider: "opencode",
                check_cmd: ["opencode", "--version"],
                install_cmd: "npm install -g opencode-cli",
                install_url: "https://opencode.dev"
              },
              "codex-oss" => {
                name: "Codex OSS",
                provider: "codexoss",
                check_cmd: ["codex-oss", "--version"],
                install_cmd: "pip install codex-oss",
                install_url: "https://github.com/codex-oss/codex"
              }
            }.freeze

            # Check all providers and return results
            # @return [Array<Hash>] Results for each provider
            def check_all
              PROVIDERS.map do |cli_name, config|
                check_provider(cli_name, config)
              end
            end

            private

            def check_provider(cli_name, config)
              result = {
                name: config[:name],
                provider: config[:provider],
                config: config,
                available: false,
                authenticated: false,
                version: nil,
                auth_status: "Not checked"
              }

              if Atoms::ProviderDetector.available?(cli_name)
                result[:available] = true
                result[:version] = Atoms::ProviderDetector.version(config[:check_cmd])

                auth_result = Atoms::AuthChecker.check(config[:provider])
                result[:authenticated] = auth_result[:authenticated]
                result[:auth_status] = auth_result[:message]
              end

              result
            end
          end
        end
      end
    end
  end
end
