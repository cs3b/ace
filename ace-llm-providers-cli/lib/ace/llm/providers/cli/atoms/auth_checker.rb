# frozen_string_literal: true

require "open3"

module Ace
  module Llm
    module Providers
      module Cli
        module Atoms
          # Checks authentication status for CLI-based LLM providers
          class AuthChecker
            # Check authentication for a specific provider
            # @param provider [String] Provider name (claude, codex, opencode, codexoss)
            # @return [Hash] Result with :authenticated and :message
            def self.check(provider)
              case provider
              when "claude" then check_claude
              when "codex" then check_codex
              when "opencode" then check_opencode
              when "codexoss" then check_codexoss
              else
                {authenticated: false, message: "Unknown provider: #{provider}"}
              end
            end

            def self.check_claude
              stdout, _, status = Open3.capture3("claude", "--version")
              if status.success? && (stdout.include?("Claude") || stdout.include?("claude"))
                {authenticated: true, message: "Authenticated"}
              else
                {authenticated: false, message: "Run: claude setup-token"}
              end
            rescue Errno::ENOENT, Errno::EACCES
              {authenticated: false, message: "Authentication check failed"}
            end

            def self.check_codex
              _, _, status = Open3.capture3("codex", "--help")
              if status.success?
                {authenticated: true, message: "Authenticated"}
              else
                {authenticated: false, message: "Run: codex login"}
              end
            rescue Errno::ENOENT, Errno::EACCES
              {authenticated: false, message: "Authentication check failed"}
            end

            def self.check_opencode
              _, _, status = Open3.capture3("opencode", "--version")
              if status.success?
                {authenticated: true, message: "Authenticated"}
              else
                {authenticated: false, message: "Run: opencode auth"}
              end
            rescue Errno::ENOENT, Errno::EACCES
              {authenticated: false, message: "Authentication check failed"}
            end

            def self.check_codexoss
              stdout, _, status = Open3.capture3("codex-oss", "--version")
              if status.success? && stdout.include?("codex")
                {authenticated: true, message: "Configured"}
              else
                {authenticated: false, message: "Run: codex-oss init"}
              end
            rescue Errno::ENOENT, Errno::EACCES
              {authenticated: false, message: "Configuration check failed"}
            end
          end
        end
      end
    end
  end
end
