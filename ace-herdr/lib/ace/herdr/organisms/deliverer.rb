# frozen_string_literal: true

require "shellwords"
require "time"
require "ace/hitl"

module Ace
  module Herdr
    module Organisms
      # Push delivery per the ace-hitl provider delivery contract
      # (spec 8wm.t.vrz §1.2, task 8wm.t.vs0):
      #   deliver(ref, answer) -> Ace::Hitl::Providers::DeliverResult
      #   with state :delivered, :retryable or :failed.
      #
      # Guarantees:
      # - Idempotent per event id: a delivered record short-circuits
      #   identical content; different content or a different destination
      #   for the same id fails closed.
      # - The answer is never lost: the record carries the full answer and
      #   is persisted before the first herdr contact (0600, atomic) and
      #   around every attempt; a crashed run can be resumed with #resume.
      # - Concurrent deliveries of one event serialize on a per-event lock.
      # - An ambiguous crash window (prompt submitted, outcome not yet
      #   persisted) is reported as :failed instead of silently resending.
      # - A pane without an agent is bootstrapped (herdr agent start) with
      #   the reverse address exported into the pane shell, then gated on
      #   readiness before the prompt is submitted.
      # - Transient failures (probe or prompt) persist their history and
      #   return :retryable within retry limits; terminal failures return
      #   :failed with the error persisted in the record.
      class Deliverer
        READY_STATES = %w[idle].freeze

        # executor: seam responding to the Molecules::HerdrExecutor API
        # clock: sleeper for backoff, injectable for tests (default Kernel.sleep)
        def initialize(executor:, deliveries_dir:, max_attempts:, backoff_seconds:,
          default_agent_kind:, agent_start_timeout_ms:, readiness_timeout_ms:, clock: nil)
          @executor = executor
          @deliveries_dir = deliveries_dir
          @max_attempts = max_attempts
          @backoff_seconds = backoff_seconds
          @default_agent_kind = default_agent_kind
          @agent_start_timeout_ms = agent_start_timeout_ms
          @readiness_timeout_ms = readiness_timeout_ms
          @clock = clock || ->(seconds) { Kernel.sleep(seconds) }
        end

        # Build a Deliverer from the merged config cascade hash (string keys)
        def self.from_config(executor:, deliveries_dir:, config: {})
          delivery = config["delivery"] || {}
          timeouts = config["timeouts"] || {}
          new(
            executor: executor,
            deliveries_dir: deliveries_dir,
            max_attempts: delivery["max_attempts"] || 3,
            backoff_seconds: delivery["backoff_seconds"] || [1, 2, 4],
            default_agent_kind: config["default_agent_kind"] || "pi",
            agent_start_timeout_ms: (timeouts["agent_start"] || 60) * 1000,
            readiness_timeout_ms: (timeouts["wait"] || 30) * 1000
          )
        end

        # @param ref [Ace::Hitl::Providers::Ref, Hash] reverse address; a Hash
        #   with "session"/"pane" keys (persisted event fields) is coerced.
        # @param answer [String] content pushed to the pane
        # @param event_id [String, nil] idempotency key; derived from the
        #   ref and content digest when omitted
        # @param kind [String, nil] agent kind for bootstrap
        #   (default: config default_agent_kind)
        # @param label [String, nil] agent name used when bootstrapping
        #   (default: the event id)
        # @return [Ace::Hitl::Providers::DeliverResult]
        # @raise [Ace::Hitl::Providers::InvalidRefError] invalid reverse address
        # @raise [ValidationError] event id, destination or content conflict
        def deliver(ref, answer, event_id: nil, kind: nil, label: nil)
          ref = coerce_ref(ref)
          raise ValidationError, "answer is required" if answer.to_s.empty?

          digest = Ace::Herdr::Atoms::AnswerDigest.call(answer)
          event_id = normalize_event_id(event_id, ref, digest)

          Molecules::DeliveryRecordStore.with_lock(@deliveries_dir, event_id) do
            record = Molecules::DeliveryRecordStore.load(@deliveries_dir, event_id)
            raise ValidationError, "event belongs to the agent inbox" if record&.inbox
            validate_existing_record(record, ref, digest) if record
            record ||= Models::DeliveryRecord.new(
              event_id: event_id, session: ref.session, pane: ref.pane,
              answer_digest: digest, answer: answer
            )
            deliver_locked(ref, answer, record, kind, label)
          end
        end

        # Re-deliver from the persisted record after a crash. The answer and
        # destination come from the record; no fresh content is needed.
        # @return [Ace::Hitl::Providers::DeliverResult]
        # @raise [ValidationError] no recoverable record for the event id
        def resume(event_id, kind: nil, label: nil)
          validate_event_id!(event_id)
          Molecules::DeliveryRecordStore.with_lock(@deliveries_dir, event_id) do
            record = Molecules::DeliveryRecordStore.load(@deliveries_dir, event_id)
            raise ValidationError, "event belongs to the agent inbox" if record&.inbox
            if record.nil? || record.answer.to_s.empty?
              raise ValidationError,
                "no recoverable answer stored for event #{event_id.inspect}"
            end

            ref = Ace::Hitl::Providers::Ref.new(session: record.session, pane: record.pane)
            deliver_locked(ref, record.answer, record, kind, label)
          end
        end

        private

        def deliver_locked(ref, answer, record, kind, label)
          if record.delivered?
            return DeliverResult(ref: ref, state: :delivered)
          end
          if record.state == "failed"
            # Terminal: retrying would need a new event id, never a resend
            return DeliverResult(ref: ref, state: :failed)
          end
          if record.ambiguous_submission?
            # The previous run may have already pushed this answer; resending
            # could duplicate it, so report instead of acting.
            record = record.append_event(
              state: "failed",
              detail: {action: "reconcile", outcome: "ambiguous",
                       error: "previous run crashed after submitting; resolve manually"},
              timestamp: now
            )
            persist(record)
            return DeliverResult(ref: ref, state: :failed)
          end
          persist(record) if record.attempts.zero? && record.history.empty?

          deliver_with_bootstrap(ref, answer, record, kind, label)
        end

        def deliver_with_bootstrap(ref, answer, record, kind, label)
          outcome = probe_agent(ref, record, kind, label)
          return outcome.result if outcome.terminal?

          push_prompt(ref, answer, outcome.record)
        end

        # Probe the pane and bootstrap a missing agent. Returns a terminal
        # outcome carrying the final DeliverResult, or the record to prompt.
        # Transient probe failures retry within the configured limits.
        def probe_agent(ref, record, kind, label)
          attempt = 0
          loop do
            @executor.agent_get(ref.pane)
            return Outcome.present(record)
          rescue PaneNotFoundError => e
            return Outcome.terminal(terminal(ref, record, e, action: "probe"))
          rescue AgentNotFoundError
            return bootstrap_and_wait(ref, record, kind, label)
          rescue ExecutorError => e
            attempt += 1
            exhausted = attempt >= @max_attempts
            record = record.append_event(
              state: exhausted ? "retryable" : "pending",
              detail: {action: "probe", attempt: attempt, outcome: e.class.name,
                       error: e.message},
              timestamp: now
            )
            persist(record)
            if exhausted
              return Outcome.terminal(DeliverResult(ref: ref, state: :retryable))
            end

            @clock.call(backoff_for(attempt))
          end
        end

        # Bootstrap a missing agent, then gate on readiness. Returns a
        # terminal outcome when bootstrapping or readiness terminates the
        # delivery; otherwise the record to prompt. Bootstrap failures are
        # terminal: an immediate retry cannot heal a broken pane.
        def bootstrap_and_wait(ref, record, kind, label)
          export = "export HERDR_SESSION=#{Shellwords.escape(ref.session)} " \
            "HERDR_PANE=#{Shellwords.escape(ref.pane)}"
          begin
            @executor.pane_run(ref.pane, export)
            @executor.agent_start(
              name: label || record.event_id, kind: kind || @default_agent_kind,
              pane: ref.pane, timeout_ms: @agent_start_timeout_ms
            )
          rescue ExecutorError => e
            return Outcome.terminal(terminal(ref, record, e, action: "bootstrap"))
          end

          record = record.append_event(
            detail: {action: "bootstrap", outcome: "agent started"},
            timestamp: now
          )
          persist(record)

          begin
            @executor.agent_wait(
              pane: ref.pane, until_states: READY_STATES,
              timeout_ms: @readiness_timeout_ms
            )
          rescue ExecutorError => e
            # Started but not yet ready: do not prompt; safe to retry later
            record = record.append_event(
              state: "retryable",
              detail: {action: "readiness", outcome: "timeout", error: e.message},
              timestamp: now
            )
            persist(record)
            return Outcome.terminal(DeliverResult(ref: ref, state: :retryable))
          end
          Outcome.present(record)
        end

        # Prompt with retry limits and fixed deterministic backoff. Each
        # attempt is written ahead (outcome "submitting") so an interrupted
        # run never silently duplicates the submission.
        def push_prompt(ref, answer, record)
          attempt = 0
          loop do
            attempt += 1
            record = record.append_event(
              detail: {action: "prompt", outcome: "submitting"},
              timestamp: now
            )
            persist(record)
            begin
              @executor.agent_prompt(pane: ref.pane, text: answer)
              record = record.record_attempt(
                state: "delivered",
                detail: {action: "prompt", outcome: "delivered"},
                timestamp: now
              )
              persist(record)
              return DeliverResult(ref: ref, state: :delivered)
            rescue ExecutorError => e
              terminal = !e.retryable?
              exhausted = !terminal && attempt >= @max_attempts
              state = if terminal
                "failed"
              elsif exhausted
                "retryable"
              else
                "pending"
              end
              record = record.record_attempt(
                state: state,
                detail: {action: "prompt", outcome: e.class.name, error: e.message},
                timestamp: now
              )
              persist(record)
              if terminal
                return DeliverResult(ref: ref, state: :failed)
              elsif exhausted
                return DeliverResult(ref: ref, state: :retryable)
              end

              @clock.call(backoff_for(attempt))
            end
          end
        end

        # Fail closed when an existing record conflicts with this delivery
        def validate_existing_record(record, ref, digest)
          if record.answer_digest != digest || record.session != ref.session ||
              record.pane != ref.pane
            raise ValidationError,
              "event #{record.event_id} was already used for a different " \
              "answer or destination (idempotency conflict; fail closed)"
          end
        end

        def terminal(ref, record, error, action:)
          record = record.record_attempt(
            state: "failed",
            detail: {action: action, outcome: error.class.name, error: error.message},
            timestamp: now
          )
          persist(record)
          DeliverResult(ref: ref, state: :failed)
        end

        def persist(record)
          Molecules::DeliveryRecordStore.save(record, @deliveries_dir)
        end

        def backoff_for(attempt)
          @backoff_seconds[[attempt - 1, @backoff_seconds.length - 1].min].to_f
        end

        def coerce_ref(ref)
          session, pane =
            if ref.is_a?(Ace::Hitl::Providers::Ref)
              [ref.session, ref.pane]
            elsif ref.is_a?(Hash)
              [ref["session"], ref["pane"]]
            else
              raise ValidationError, "ref must be an Ace::Hitl::Providers::Ref or a Hash"
            end

          Ace::Hitl::Providers::Ref.new(
            session: Ace::Hitl::Providers::Ref.validate!(session, "ref session"),
            pane: Ace::Hitl::Providers::Ref.validate!(pane, "ref pane")
          )
        end

        def normalize_event_id(event_id, ref, digest)
          return validate_event_id!(event_id) if event_id

          seed = Ace::Herdr::Atoms::AnswerDigest.call("ref:#{ref.session}/#{ref.pane}:#{digest}")
          "ans-#{seed[0, 24]}"
        end

        # Event ids become record file names and lock names; only tokens may
        # pass (also blocks path traversal via resume)
        def validate_event_id!(event_id)
          token = event_id.to_s
          unless token.match?(Ace::Hitl::Providers::Ref::TOKEN_PATTERN)
            raise ValidationError,
              "event id may only contain letters, digits, '.', '_', ':', '-' " \
              "(got #{token.inspect})"
          end

          token
        end

        def now
          Time.now.utc.iso8601
        end

        # Contract result type from ace-hitl (spec 8wm.t.vrz §1.2)
        def DeliverResult(ref:, state:)
          Ace::Hitl::Providers::DeliverResult.new(ref: ref, state: state)
        end

        # Probe/bootstrap phase outcome for deliver_with_bootstrap
        class Outcome
          attr_reader :record, :result

          def initialize(record:, result: nil, terminal: false, bootstrapped: false)
            @record = record
            @result = result
            @terminal = terminal
            @bootstrapped = bootstrapped
          end

          def self.present(record) = new(record: record)
          def self.bootstrapped(record) = new(record: record, bootstrapped: true)
          def self.terminal(result) = new(record: nil, result: result, terminal: true)

          def terminal? = @terminal
          def bootstrapped? = @bootstrapped
        end
      end
    end
  end
end
