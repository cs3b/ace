# frozen_string_literal: true

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
      #   identical content; different content for the same id fails closed.
      # - The answer is never lost: a write-ahead record is persisted before
      #   the first herdr contact and after every event and attempt.
      # - A pane without an agent is bootstrapped (herdr agent start) with
      #   the reverse address exported into the pane shell, then gated on
      #   readiness before the prompt is submitted.
      # - Transient failures back off on a fixed deterministic schedule
      #   within retry limits; terminal failures are persisted in the record
      #   and reported via the :failed state.
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
        # @raise [ValidationError] event id/content conflict (fail closed)
        def deliver(ref, answer, event_id: nil, kind: nil, label: nil)
          ref = coerce_ref(ref)
          digest = Ace::Herdr::Atoms::AnswerDigest.call(answer)
          event_id = normalize_event_id(event_id, ref, digest)

          record = Molecules::DeliveryRecordStore.load(@deliveries_dir, event_id)
          if record
            if record.answer_digest != digest
              raise ValidationError,
                "event #{event_id} was already delivered with different content " \
                "(idempotency conflict; fail closed)"
            end
            return DeliverResult(ref: ref, state: :delivered) if record.delivered?
          end
          record ||= new_record(event_id, ref, digest)
          persist(record)

          deliver_with_bootstrap(ref, answer, record, kind, label, event_id)
        end

        private

        def deliver_with_bootstrap(ref, answer, record, kind, label, event_id)
          begin
            @executor.agent_get(ref.pane)
          rescue PaneNotFoundError => e
            return terminal(ref, record, e, action: "probe")
          rescue AgentNotFoundError
            record, result = bootstrap(ref, record, kind, label, event_id)
            return result if result

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
              return DeliverResult(ref: ref, state: :retryable)
            end
          end

          push_prompt(ref, answer, record)
        end

        # Bootstrap a missing agent. Returns [record, non-nil result] when
        # bootstrapping terminates the delivery, [record, nil] on success.
        # Bootstrap failures are terminal: an immediate retry cannot heal a
        # broken pane, so the failure is reported and persisted.
        def bootstrap(ref, record, kind, label, event_id)
          export = "export HERDR_SESSION=#{ref.session} HERDR_PANE=#{ref.pane}"
          begin
            @executor.pane_run(ref.pane, export)
            @executor.agent_start(
              name: label || event_id, kind: kind || @default_agent_kind,
              pane: ref.pane, timeout_ms: @agent_start_timeout_ms
            )
          rescue ExecutorError => e
            return [record, terminal(ref, record, e, action: "bootstrap")]
          end

          record = record.append_event(
            detail: {action: "bootstrap", outcome: "agent started"},
            timestamp: now
          )
          persist(record)
          [record, nil]
        end

        # Prompt with retry limits and fixed deterministic backoff
        def push_prompt(ref, answer, record)
          attempt = 0
          loop do
            attempt += 1
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
              state = terminal ? "failed" : (exhausted ? "retryable" : "pending")
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
          unless event_id
            seed = Ace::Herdr::Atoms::AnswerDigest.call("ref:#{ref.session}/#{ref.pane}:#{digest}")
            return "ans-#{seed[0, 24]}"
          end

          token = event_id.to_s
          unless token.match?(Ace::Hitl::Providers::Ref::TOKEN_PATTERN)
            raise ValidationError,
              "event id may only contain letters, digits, '.', '_', ':', '-' " \
              "(got #{token.inspect})"
          end

          token
        end

        def new_record(event_id, ref, digest)
          Models::DeliveryRecord.new(
            event_id: event_id, session: ref.session, pane: ref.pane,
            answer_digest: digest
          )
        end

        def now
          Time.now.utc.iso8601
        end

        # Contract result type from ace-hitl (spec 8wm.t.vrz §1.2)
        def DeliverResult(ref:, state:)
          Ace::Hitl::Providers::DeliverResult.new(ref: ref, state: state)
        end
      end
    end
  end
end
