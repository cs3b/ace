# frozen_string_literal: true
require_relative "eyes_session_evidence"
require_relative "../atoms/start_contract"
require_relative "../atoms/observation_sources"

module Ace
  module Overseer
    module Molecules
      # Read readiness from the actual native pane and its Pi session.
      class EyesReadiness
        def initialize(env: ENV, local: EyesSessionEvidence.new)
          @local = local
        end

        def ready?(pane:, root:, prompt:, required_sources:)
          @local.ready?(pane: pane, root: root, prompt: prompt, required_sources: required_sources)
        end
      end
    end
  end
end
