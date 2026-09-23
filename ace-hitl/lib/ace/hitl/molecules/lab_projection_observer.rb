# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module Molecules
      # Observes the Lab request public projection
      # (`<public-dir>/<request-id>.json`) so waiters can surface lab-side
      # states instead of hanging blind. Read-only; consumption of the
      # answer relay remains the caller's choice.
      #
      # Projection schema (deployed lab relay, lab-config 8wl.t.ga9): the
      # lifecycle field `state` carries created / answer-delivered /
      # consumed / cancelled, while effect-callback outcomes live in the
      # SEPARATE `effect_state` field (callback-pending-with-answer /
      # callback-ok / callback-escalated). Both fields are observed here.
      class LabProjectionObserver
        DEFAULT_PUBLIC_DIR = "/run/lab/hitl/public"
        PUBLIC_DIR_ENV = "ACE_HITL_LAB_PUBLIC_DIR"

        # Lifecycle (`state`) terminal values: the answer was delivered to
        # the relay, consumed, or the request was cancelled.
        LIFECYCLE_TERMINAL_STATES = %w[answer-delivered consumed cancelled].freeze
        # Effect (`effect_state`) terminal values: the callback reached a
        # verdict. `callback-pending-with-answer` keeps a waiter holding.
        EFFECT_TERMINAL_STATES = %w[callback-ok callback-escalated].freeze

        # Both observed projection fields; either may be nil while the lab
        # has not written it yet.
        Snapshot = Struct.new(:state, :effect_state)

        def initialize(public_dir: nil)
          @public_dir = public_dir
        end

        # Reads the projection and returns a Snapshot with the lifecycle
        # `state` and the separate `effect_state`, or nil when the
        # projection is missing or unreadable.
        def snapshot_for(request_id)
          path = projection_path(request_id)
          return nil unless File.file?(path)

          projection = JSON.parse(File.read(path))
          Snapshot.new(
            state: projection["state"],
            effect_state: projection["effect_state"]
          )
        rescue
          nil
        end

        # The state a waiter should report: the effect outcome when one
        # exists (so `lab_request_state` never claims plain
        # `answer-delivered` while an effect outcome is present), the
        # lifecycle state otherwise.
        def effective_state(snapshot)
          return nil unless snapshot

          snapshot.effect_state || snapshot.state
        end

        # Terminality depends on whether the request declared an effect
        # callback: effect-declaring requests terminate only on an effect
        # verdict (callback-ok / callback-escalated), never at answer
        # delivery; other requests terminate on lifecycle terminal states.
        def terminal?(snapshot, effect_declared: false)
          return false unless snapshot

          if effect_declared
            EFFECT_TERMINAL_STATES.include?(snapshot.effect_state)
          else
            LIFECYCLE_TERMINAL_STATES.include?(snapshot.state)
          end
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
