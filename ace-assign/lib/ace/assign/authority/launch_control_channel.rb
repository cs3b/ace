# frozen_string_literal: true
require "securerandom"
require_relative "transfer_codec"

module Ace
  module Assign
    module Authority
      # A rendezvous for one already authenticated original launcher stream.
      # Canonical issue permits belong to LaunchLifecycle/JournalMutation.
      # This queue owns no replay, authorization, terminal state or effects.
      class LaunchControlChannel
        Pending = Struct.new(:frame, :bytes, :deadline, :result, :error, :finished, keyword_init: true)
        PROMPT_FIELDS = %w[attempt_id intent_event_id journal_commit mutation_id original_binding_digest text_descriptor transfer_id type version].freeze
        OUTCOME_FIELDS = %w[guarded_evidence intent_event_id mutation_id original_binding_digest type version].freeze
        RECORDED_FIELDS = %w[intent_event_id journal_commit mutation_id original_binding_digest outcome type version].freeze
        REVIEW_FIELDS = %w[attempt_id journal_commit mutation_id original_binding_digest request_event_id type version].freeze
        REVIEW_ASSIGNED_FIELDS = %w[assignment_event_id journal_commit mutation_id original_binding_digest request_event_id type version].freeze
        INHIBIT_FIELDS = %w[attempt_id journal_commit original_binding_digest seal_event_id type version].freeze
        INHIBIT_OUTCOME_FIELDS = %w[guarded_evidence original_binding_digest seal_event_id type version].freeze
        INHIBIT_RECORDED_FIELDS = %w[journal_commit original_binding_digest seal_event_id type version].freeze

        def initialize(socket:, codec:, outcome:, input_inhibition: nil)
          @socket, @codec, @outcome = socket, codec, outcome
          @input_inhibition = input_inhibition
          @mutex, @changed = Mutex.new, ConditionVariable.new
          @pending = nil
          @closed = false
        end

        def reserve_dispatch!
          @mutex.synchronize do
            raise AttemptErrors::EvidenceUnavailable, "Original launcher control channel is unavailable" if @closed
            raise AttemptErrors::Conflict, "Original launcher input is inhibited" if @inhibiting
            raise AttemptErrors::Conflict, "Original launcher control channel is busy" if @reservation || @pending
            @reservation = Object.new.freeze
          end
        end

        def inhibit_input(frame:, deadline:)
          self.class.validate_inhibit!(frame)
          pending = Pending.new(frame: frame, deadline: deadline, finished: false)
          @mutex.synchronize do
            @inhibiting = true
            if @inhibition_pending
              unless @inhibition_pending.frame.slice("attempt_id", "original_binding_digest", "seal_event_id") == frame.slice("attempt_id", "original_binding_digest", "seal_event_id")
                raise AttemptErrors::Conflict, "Original input inhibition names another seal"
              end
              pending = @inhibition_pending
            else
              @inhibition_pending = pending
              while @reservation || @pending
                raise AttemptErrors::EvidenceUnavailable, "Original launcher control channel is unavailable" if @closed
                remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
                raise AttemptErrors::EvidenceUnavailable, "Original input inhibition is uncertain" unless remaining.positive?
                @changed.wait(@mutex, remaining)
              end
              raise AttemptErrors::EvidenceUnavailable, "Original launcher control channel is unavailable" if @closed
              @pending = pending
              @changed.broadcast
            end
            until pending.finished
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              raise AttemptErrors::EvidenceUnavailable, "Original input inhibition is uncertain" unless remaining.positive?
              @changed.wait(@mutex, remaining)
            end
          end
          raise pending.error if pending.error
          pending.result
        rescue AttemptErrors::EvidenceUnavailable
          close
          raise
        end

        def dispatch_reserved?(reservation)
          @mutex.synchronize { !@closed && !reservation.nil? && @reservation.equal?(reservation) }
        end

        def release_dispatch!(reservation)
          @mutex.synchronize do
            @reservation = nil if @reservation.equal?(reservation) && !@pending
            @changed.broadcast if @inhibiting
          end
        end

        def dispatch_prompt(frame:, bytes:, deadline:, reservation:)
          validate_prompt!(frame)
          dispatch_pending(Pending.new(frame: frame, bytes: bytes, deadline: deadline, finished: false), reservation)
        end

        def dispatch_review(frame:, deadline:, reservation:)
          self.class.validate_review!(frame)
          dispatch_pending(Pending.new(frame: frame, deadline: deadline, finished: false), reservation)
        end

        def dispatch_pending(pending, reservation)
          @mutex.synchronize do
            raise AttemptErrors::EvidenceUnavailable, "Original launcher control channel is unavailable" if @closed
            raise AttemptErrors::EvidenceUnavailable, "Original launcher dispatch capacity is not held" unless reservation && @reservation.equal?(reservation)
            raise AttemptErrors::Conflict, "Original launcher control channel is busy" if @pending
            @pending = pending
            @changed.broadcast
            until pending.finished
              remaining = pending.deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              raise AttemptErrors::EvidenceUnavailable, "Original launcher dispatch outcome is uncertain" unless remaining.positive?
              @changed.wait(@mutex, remaining)
            end
          end
          raise pending.error if pending.error
          pending.result
        end

        private :dispatch_pending

        # Only the existing Server connection handler calls serve. No slot,
        # assignment, journal or channel mutex is held over a socket wait or
        # the original owner's canonical outcome ingestion callback.
        def serve
          loop do
            pending = @mutex.synchronize do
              @changed.wait(@mutex, 1) unless @closed || @pending
              break if @closed
              @pending
            end
            break if closed?
            unless pending
              ping
              next
            end
            begin
              wire.write(@socket, pending.frame, deadline: pending.deadline, limit: 16_384)
              if pending.frame.fetch("type") == "launch_review_delegate"
                result = wire.read(@socket, deadline: pending.deadline, limit: 16_384)
                self.class.validate_review_assigned!(result, pending.frame)
                # This transport correlation is not assignment acceptance.
                # The canonical request owner must authenticate the returned
                # event/commit before recording the public response.
                complete(pending, result: result)
                next
              end
              if pending.frame.fetch("type") == "launch_input_inhibit"
                result = wire.read(@socket, deadline: pending.deadline, limit: 16_384)
                self.class.validate_inhibit_outcome!(result, pending.frame)
                raise AttemptErrors::EvidenceUnavailable, "Canonical input inhibition owner unavailable" unless @input_inhibition
                accepted = @input_inhibition.call(result)
                unless accepted.is_a?(Hash) && accepted.keys.sort == %w[journal_commit original_binding_digest seal_event_id] &&
                    %w[original_binding_digest seal_event_id].all? { |key| accepted[key] == pending.frame.fetch(key) }
                  raise AttemptErrors::EvidenceUnavailable, "Canonical input inhibition acceptance differs"
                end
                recorded = pending.frame.slice("original_binding_digest", "seal_event_id").merge("version" => 1,
                  "type" => "launch_input_inhibit_recorded", "journal_commit" => accepted.fetch("journal_commit"))
                self.class.validate_inhibit_recorded!(recorded, pending.frame)
                wire.write(@socket, recorded, deadline: pending.deadline, limit: 16_384)
                complete(pending, result: result)
                next
              end
              @codec.send_launch_prompt(@socket, bytes: pending.bytes, descriptor: pending.frame.fetch("text_descriptor"),
                transfer_id: pending.frame.fetch("transfer_id"), deadline: pending.deadline)
              pending.bytes = nil
              result = wire.read(@socket, deadline: pending.deadline, limit: 16_384)
              validate_outcome!(result, pending.frame)
              accepted = @outcome.call(result)
              unless accepted.is_a?(Hash) && accepted.keys.sort == %w[journal_commit outcome] &&
                  accepted["outcome"] == result.dig("guarded_evidence", "outcome") &&
                  accepted["journal_commit"].is_a?(String) && accepted["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
                raise AttemptErrors::EvidenceUnavailable, "Canonical prompt completion acknowledgement is unavailable"
              end
              recorded = pending.frame.slice("mutation_id", "intent_event_id", "original_binding_digest").merge(accepted).merge(
                "version" => 1, "type" => "prompt_outcome_recorded")
              wire.write(@socket, recorded, deadline: pending.deadline, limit: 16_384)
              complete(pending, result: result)
            rescue StandardError => error
              complete(pending, error: error)
              break
            end
          end
        rescue IOError, SystemCallError, Ace::Runtime::RuntimeUnavailableError
          nil
        ensure
          close
        end

        def close
          @mutex.synchronize do
            @closed = true
            @reservation = nil
            if @pending && !@pending.finished
              @pending.error = AttemptErrors::EvidenceUnavailable.new("Original launcher control channel closed with uncertain outcome")
              @pending.finished = true
              @pending.bytes = nil
            end
            if @inhibition_pending && !@inhibition_pending.finished
              @inhibition_pending.error = AttemptErrors::EvidenceUnavailable.new("Original input inhibition is uncertain")
              @inhibition_pending.finished = true
            end
            @changed.broadcast
          end
        end

        def closed?
          @mutex.synchronize { @closed }
        end

        def self.validate_review!(frame)
          unless frame.is_a?(Hash) && frame.keys.sort == REVIEW_FIELDS &&
              frame["version"].is_a?(Integer) && frame["version"] == 1 && frame["type"] == "launch_review_delegate" &&
              %w[attempt_id mutation_id].all? { |key| frame[key].is_a?(String) && frame[key].match?(Molecules::JournalMutation::ID) } &&
              %w[request_event_id original_binding_digest].all? { |key| frame[key].is_a?(String) && frame[key].match?(/\A[0-9a-f]{64}\z/) } &&
              frame["journal_commit"].is_a?(String) && frame["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise AttemptErrors::EvidenceUnavailable, "Private review delegation differs"
          end
          true
        end

        def self.validate_review_assigned!(result, frame)
          unless result.is_a?(Hash) && result.keys.sort == REVIEW_ASSIGNED_FIELDS &&
              result["version"].is_a?(Integer) && result["version"] == 1 && result["type"] == "launch_review_assigned" &&
              %w[mutation_id request_event_id original_binding_digest].all? { |key| result[key] == frame.fetch(key) } &&
              result["assignment_event_id"].is_a?(String) && result["assignment_event_id"].match?(/\A[0-9a-f]{64}\z/) &&
              result["journal_commit"].is_a?(String) && result["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise AttemptErrors::EvidenceUnavailable, "Private review assignment does not join original request"
          end
          true
        end

        def self.validate_prompt!(frame)
          unless frame.is_a?(Hash) && frame.keys.all? { |key| key.is_a?(String) } && frame.keys.sort == PROMPT_FIELDS &&
              frame["version"].is_a?(Integer) && frame["version"] == 1 && frame["type"] == "prompt_dispatch" &&
              %w[intent_event_id original_binding_digest].all? { |key| frame[key].is_a?(String) && frame[key].match?(/\A[0-9a-f]{64}\z/) } &&
              frame["journal_commit"].is_a?(String) && frame["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              %w[attempt_id mutation_id].all? { |key| frame[key].is_a?(String) && frame[key].match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/) } &&
              frame["transfer_id"].is_a?(String) && frame["transfer_id"].match?(/\A[0-9a-f]{32}\z/)
            raise AttemptErrors::EvidenceUnavailable, "Private prompt dispatch frame is malformed"
          end
          TransferCodec.new.validate!(frame.fetch("text_descriptor"), :prompt_text)
          true
        end

        def self.validate_recorded!(recorded, frame, evidence)
          unless recorded.is_a?(Hash) && recorded.keys.sort == RECORDED_FIELDS && recorded["version"].is_a?(Integer) && recorded["version"] == 1 &&
              recorded["type"] == "prompt_outcome_recorded" && recorded["outcome"] == evidence.fetch("outcome") &&
              %w[mutation_id intent_event_id original_binding_digest].all? { |key| recorded[key] == frame.fetch(key) } &&
              recorded["journal_commit"].is_a?(String) && recorded["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise AttemptErrors::EvidenceUnavailable, "Canonical prompt completion acknowledgement differs"
          end
          true
        end

        def self.validate_inhibit!(frame)
          unless frame.is_a?(Hash) && frame.keys.sort == INHIBIT_FIELDS && frame["version"].is_a?(Integer) && frame["version"] == 1 &&
              frame["type"] == "launch_input_inhibit" && frame["attempt_id"].is_a?(String) && frame["attempt_id"].match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/) &&
              %w[original_binding_digest seal_event_id].all? { |key| frame[key].is_a?(String) && frame[key].match?(/\A[0-9a-f]{64}\z/) } &&
              frame["journal_commit"].is_a?(String) && frame["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise AttemptErrors::EvidenceUnavailable, "Private input inhibition frame is malformed"
          end
          true
        end

        def self.validate_inhibit_outcome!(result, frame)
          unless result.is_a?(Hash) && result.keys.sort == INHIBIT_OUTCOME_FIELDS && result["version"].is_a?(Integer) && result["version"] == 1 &&
              result["type"] == "launch_input_inhibit_outcome" && result["guarded_evidence"].is_a?(Hash) &&
              %w[original_binding_digest seal_event_id].all? { |key| result[key] == frame.fetch(key) }
            raise AttemptErrors::EvidenceUnavailable, "Private input inhibition outcome differs"
          end
          true
        end

        def self.validate_inhibit_recorded!(result, frame)
          unless result.is_a?(Hash) && result.keys.sort == INHIBIT_RECORDED_FIELDS && result["version"].is_a?(Integer) && result["version"] == 1 &&
              result["type"] == "launch_input_inhibit_recorded" && %w[original_binding_digest seal_event_id].all? { |key| result[key] == frame.fetch(key) } &&
              result["journal_commit"].is_a?(String) && result["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise AttemptErrors::EvidenceUnavailable, "Canonical input inhibition acknowledgement differs"
          end
          true
        end

        private

        def validate_prompt!(frame) = self.class.validate_prompt!(frame)

        def validate_outcome!(result, frame)
          unless result.is_a?(Hash) && result.keys.all? { |key| key.is_a?(String) } && result.keys.sort == OUTCOME_FIELDS &&
              result["version"].is_a?(Integer) && result["version"] == 1 && result["type"] == "prompt_dispatch_outcome" &&
              %w[mutation_id intent_event_id original_binding_digest].all? { |key| result[key] == frame.fetch(key) } &&
              result["guarded_evidence"].is_a?(Hash)
            raise AttemptErrors::EvidenceUnavailable, "Private prompt outcome does not join original dispatch"
          end
        end

        def complete(pending, result: nil, error: nil)
          @mutex.synchronize do
            @closed = true if error
            pending.result, pending.error, pending.finished = result, error, true
            pending.bytes = nil
            @pending = nil if @pending.equal?(pending)
            @reservation = nil
            @changed.broadcast
          end
        end

        def ping
          nonce, deadline = SecureRandom.hex(16), wire.deadline(5)
          wire.write(@socket, {"version" => 1, "type" => "launch_control_idle", "nonce" => nonce}, deadline: deadline, limit: 16_384)
          result = wire.read(@socket, deadline: deadline, limit: 16_384)
          unless result.is_a?(Hash) && result["version"].is_a?(Integer) && result == {"version" => 1, "type" => "launch_control_idle_ack", "nonce" => nonce}
            raise AttemptErrors::EvidenceUnavailable, "Private launcher idle response differs"
          end
        end

        def wire = Ace::Runtime::Molecules::ProtectedSocket
      end
    end
  end
end
