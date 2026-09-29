# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      # Fail-closed Lab Work classification for prune.
      #
      # A Lab Work may only be destroyed when the authoritative Lab surface
      # reports a documented terminal state AND preservation evidence is
      # available (declared destination proof). Active work, unknown states,
      # unreadable state, or missing preservation evidence block the
      # candidate — including under --yes. When the Lab surface cannot supply
      # the state, the path reports blocked rather than assuming safety.
      class LabPruneSafetyChecker
        STATES_KEY = %w[state status].freeze
        TERMINAL_STATES = %w[completed done archived cancelled].freeze
        ACTIVE_STATES = %w[
          running in_flight in-flight in_progress in-progress
          active pending reserved claimed started queued
        ].freeze

        Classification = Struct.new(:safe?, :reason, keyword_init: true)

        # @param lab_client [LabClient] Lab surface adapter
        # @param work_id [String] Exact Lab Work ID
        # @param preservation_proof [Models::PreservationProof, nil] Declared
        #   destination proof for the Work's content
        # @return [Classification]
        def check(lab_client:, work_id:, preservation_proof: nil)
          state = read_state(lab_client, work_id)
          return classify(false, state) if state.is_a?(String)

          value = STATES_KEY.filter_map { |key| state[key] }.find { |entry| entry.is_a?(String) }
          return classify(false, "lab state for #{work_id} is unreadable") if value.nil?

          normalized = value.strip.downcase
          return classify(false, "lab work #{work_id} is #{normalized} (active writer)") if ACTIVE_STATES.include?(normalized)

          unless TERMINAL_STATES.include?(normalized)
            return classify(false, "lab work #{work_id} state #{normalized.inspect} is not a documented terminal state")
          end

          if preservation_proof.nil?
            return classify(false, "no preservation evidence for lab work #{work_id}; " \
              "declare a verified destination via --preservation")
          end
          unless preservation_proof.preserved?
            return classify(false, preservation_proof.reason)
          end

          Classification.new(safe?: true, reason: nil)
        end

        private

        def read_state(lab_client, work_id)
          data = lab_client.call("work", "show", work_id)
          return data if data.is_a?(Hash)

          classify(false, "lab state for #{work_id} is not structured")
        rescue Ace::Overseer::Error => e
          classify(false, "lab state for #{work_id} is unavailable: #{e.message}")
        end

        def classify(safe, reason)
          Classification.new(safe?: safe, reason: reason)
        end
      end
    end
  end
end
