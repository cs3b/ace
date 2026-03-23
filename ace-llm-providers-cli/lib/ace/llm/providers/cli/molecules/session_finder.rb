# frozen_string_literal: true

require_relative "../atoms/session_finders/claude_session_finder"
require_relative "../atoms/session_finders/codex_session_finder"
require_relative "../atoms/session_finders/pi_session_finder"
require_relative "../atoms/session_finders/gemini_session_finder"
require_relative "../atoms/session_finders/open_code_session_finder"

module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          # Dispatches session detection to the appropriate provider-specific finder.
          #
          # Used as a fallback when a provider doesn't natively return a session_id.
          # Each finder scans the provider's local session storage and matches by prompt.
          class SessionFinder
            FINDERS = {
              "claude" => Atoms::SessionFinders::ClaudeSessionFinder,
              "codex" => Atoms::SessionFinders::CodexSessionFinder,
              "pi" => Atoms::SessionFinders::PiSessionFinder,
              "gemini" => Atoms::SessionFinders::GeminiSessionFinder,
              "opencode" => Atoms::SessionFinders::OpenCodeSessionFinder
            }.freeze

            # @param provider [String] provider name
            # @param working_dir [String] project directory
            # @param prompt [String] the prompt sent to the provider
            # @return [Hash, nil] { session_id:, session_path: } or nil
            def self.call(provider:, working_dir:, prompt:)
              finder = FINDERS[provider]
              return nil unless finder

              finder.call(working_dir: working_dir, prompt: prompt)
            rescue
              nil
            end
          end
        end
      end
    end
  end
end
