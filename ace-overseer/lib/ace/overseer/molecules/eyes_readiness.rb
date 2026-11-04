# frozen_string_literal: true
require "ace/lab/auth/issuer_client"
require_relative "eyes_session_evidence"
require_relative "../atoms/start_contract"
require_relative "../atoms/observation_sources"

module Ace
  module Overseer
    module Molecules
      # Choose the observation authority explicitly; a failed isolated query
      # never falls back to opening another session's files as the caller.
      class EyesReadiness
        def initialize(env: ENV, client: Ace::Lab::Auth::IssuerClient.new, local: EyesSessionEvidence.new)
          @env, @client, @local = env, client, local
        end

        def ready?(pane:, root:, prompt:, required_sources:)
          unless @env["ACE_LAB_SESSION"] == "1"
            return @local.ready?(pane: pane, root: root, prompt: prompt, required_sources: required_sources)
          end
          unless @env["ACE_TOOLCHAIN"] == "installed" && prompt == Atoms::StartContract::FIRST_TURN_PROMPT
            raise Ace::Overseer::Error, "isolated eyes readiness requires the installed start contract"
          end
          result = @client.readiness(target: pane)
          return false unless result["root"] == root && %w[lab-overseer project-overseer].include?(result["role"])
          expected = Atoms::ObservationSources::REQUIRED.dup
          expected << Atoms::ObservationSources::PROJECT_SESSIONS if result["role"] == "lab-overseer"
          result["ready"] == true && required_sources.sort == expected.sort
        rescue Ace::Lab::Auth::Error
          raise Ace::Overseer::Error, "authenticated isolated eyes readiness is unavailable"
        end
      end
    end
  end
end
