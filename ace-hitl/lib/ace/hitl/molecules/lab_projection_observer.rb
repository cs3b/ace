# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module Molecules
      # Observes the Lab request public projection
      # (`<public-dir>/<request-id>.json`) so waiters can surface lab-side
      # states instead of hanging blind. Read-only; consumption of the
      # answer relay remains the caller's choice.
      class LabProjectionObserver
        DEFAULT_PUBLIC_DIR = "/run/lab/hitl/public"
        PUBLIC_DIR_ENV = "ACE_HITL_LAB_PUBLIC_DIR"
        TERMINAL_STATES = %w[answer-delivered callback-ok callback-escalated].freeze

        def initialize(public_dir: nil)
          @public_dir = public_dir
        end

        def state_for(request_id)
          path = projection_path(request_id)
          return nil unless File.file?(path)

          JSON.parse(File.read(path))["state"]
        rescue StandardError
          nil
        end

        def terminal?(state)
          TERMINAL_STATES.include?(state)
        end

        def projection_path(request_id)
          File.join(public_dir, "#{request_id}.json")
        end

        private

        def public_dir
          @public_dir || ENV.fetch(PUBLIC_DIR_ENV, DEFAULT_PUBLIC_DIR)
        end
      end
    end
  end
end
