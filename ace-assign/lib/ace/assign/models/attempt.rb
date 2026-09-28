# frozen_string_literal: true

require_relative "../atoms/attempt_state_machine"
require_relative "attempt_binding"

module Ace
  module Assign
    module Models
      # Mutable derived state of an assignment attempt.
      #
      # The binding is immutable; an Attempt carries the derived execution
      # state: the current state-machine state, the pinned candidate head,
      # the latest evidence journal commit, accepted receipts (by digest),
      # recorded effects, and the append-only local event trail for
      # taskless attempts. `base_head` (binding) and `candidate_head`
      # (deliverable) are always tracked separately.
      class Attempt
        attr_reader :binding, :state, :candidate_head, :journal_commit,
          :accepted_receipts, :effects, :events, :updated_at

        # @param binding [Models::AttemptBinding] Immutable start-time binding
        # @param state [String] State-machine state
        # @param candidate_head [String, nil] Pinned deliverable head
        # @param journal_commit [String, nil] Latest evidence journal commit SHA
        # @param accepted_receipts [Array<Hash>] Accepted receipt payloads (digests included)
        # @param effects [Array<Hash>] Recorded effects with intent/receipt linkage
        # @param events [Array<Hash>] Local event trail (taskless attempts only)
        # @param updated_at [Time] Last state change
        def initialize(binding:, state: "reserved", candidate_head: nil, journal_commit: nil,
          accepted_receipts: [], effects: [], events: [], updated_at: nil)
          @binding = binding
          @state = state.to_s
          @candidate_head = candidate_head
          @journal_commit = journal_commit
          @accepted_receipts = accepted_receipts.dup.freeze
          @effects = effects.dup.freeze
          @events = events.dup.freeze
          @updated_at = updated_at || binding.created_at
        end

        # @return [String] Immutable attempt ID
        def attempt_id
          binding.attempt_id
        end

        # @return [Boolean] True if no further transitions or effects are allowed
        def terminal?
          Atoms::AttemptStateMachine.terminal?(state)
        end

        # @return [Boolean] True if the attempt awaits reconciliation
        def uncertain?
          state == "uncertain"
        end

        # @return [Boolean] True if the attempt owns an active subtree slot
        def active?
          %w[reserved running uncertain].include?(state)
        end

        # @return [String] "git" or "local_only" recovery mode
        def recovery_mode
          binding.recovery_mode
        end

        # @return [Boolean] True when managed evidence-ref journaling applies
        def managed?
          binding.managed?
        end

        # Effects whose intent was recorded but whose accepted receipt is missing.
        #
        # @return [Array<Hash>] Unresolved effect records
        def unresolved_effects
          effects.reject { |effect| effect["receipt_digest"] }
        end

        # Return a new Attempt with the state transitioned.
        #
        # @param to [String] Target state (validated against the state machine)
        # @param at [Time] Transition time
        # @return [Attempt] New attempt instance
        # @raise [Ace::Assign::AttemptErrors::InvalidTransition] if illegal
        def transition(to, at: Time.now.utc)
          Atoms::AttemptStateMachine.transition!(state, to)
          with(state: to.to_s, updated_at: at)
        end

        # Return a new Attempt with updated derived fields. The binding is
        # never replaced.
        #
        # @param attrs [Hash] Fields to override (state, candidate_head,
        #   journal_commit, accepted_receipts, effects, events, updated_at)
        # @return [Attempt] New attempt instance
        def with(**attrs)
          Attempt.new(
            binding: binding,
            state: attrs.fetch(:state, state),
            candidate_head: attrs.fetch(:candidate_head, candidate_head),
            journal_commit: attrs.fetch(:journal_commit, journal_commit),
            accepted_receipts: attrs.fetch(:accepted_receipts, accepted_receipts),
            effects: attrs.fetch(:effects, effects),
            events: attrs.fetch(:events, events),
            updated_at: attrs.fetch(:updated_at, Time.now.utc)
          )
        end

        # Convert to a hash for canonical serialization.
        # @return [Hash] Attempt data with string keys
        def to_h
          {
            "binding" => binding.to_h,
            "state" => state,
            "candidate_head" => candidate_head,
            "journal_commit" => journal_commit,
            "accepted_receipts" => accepted_receipts,
            "effects" => effects,
            "events" => events,
            "updated_at" => updated_at.iso8601
          }
        end

        # JSON projection exposed by public commands. Contains attempt
        # ID, state, binding facts, references and digests only — never
        # credentials, receipt bytes, or terminal output.
        #
        # @return [Hash] Redacted projection
        def projection
          {
            "attempt_id" => attempt_id,
            "state" => state,
            "assignment_id" => binding.assignment_id,
            "scope" => binding.scope,
            "project_id" => binding.project_id,
            "task_id" => binding.task_id,
            "actor" => binding.actor,
            "role" => binding.role,
            "runtime" => binding.runtime,
            "base_head" => binding.base_head,
            "candidate_head" => candidate_head,
            "evidence_git_ref" => binding.evidence_git_ref,
            "journal_commit" => journal_commit,
            "recovery_mode" => recovery_mode,
            "accepted_receipt_digests" => accepted_receipts.map { |receipt| receipt["digest"] },
            "unresolved_effects" => unresolved_effects.map { |effect| effect["operation"] },
            "created_at" => binding.created_at.iso8601,
            "updated_at" => updated_at.iso8601
          }
        end

        # Rebuild an attempt from serialized data.
        #
        # @param data [Hash] Serialized attempt (string keys)
        # @return [Attempt] Rebuilt attempt
        def self.from_h(data)
          new(
            binding: AttemptBinding.from_h(data["binding"]),
            state: data["state"],
            candidate_head: data["candidate_head"],
            journal_commit: data["journal_commit"],
            accepted_receipts: data["accepted_receipts"] || [],
            effects: data["effects"] || [],
            events: data["events"] || [],
            updated_at: parse_time(data["updated_at"])
          )
        end

        def self.parse_time(value)
          return nil if value.nil?
          return value if value.is_a?(Time)
          require "time"
          Time.parse(value)
        end
        private_class_method :parse_time
      end
    end
  end
end
