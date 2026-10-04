# frozen_string_literal: true

module Ace
  module Assign
    module Molecules
      # Conservative classification and resolution of interrupted attempts.
      #
      # Classification of a `running` attempt found after a lost session:
      # - no recorded process start -> `stopped` (nothing could have run)
      # - recorded process still verifiably live -> keep `running`
      # - otherwise -> `uncertain` (the operation may have completed without
      #   a durable receipt)
      #
      # Reconciliation resolves an `uncertain` attempt only against verified
      # receipts whose producer runtime matches the recorded execution
      # boundary. It never replays operations: merge, publish, and deploy
      # effects are never retried automatically, and an uncertain attempt
      # without a receipt stays uncertain.
      class AttemptReconciler
        # @param journal [EvidenceJournal, nil] Managed evidence journal
        # @param verifier [ReceiptVerifier, nil] Receipt verifier (coordinator supplies on use)
        def initialize(journal: nil, verifier: nil, observer: nil, runtime_resolver: Ace::Runtime)
          @journal = journal
          @verifier = verifier
          @observer = observer || Ace::Runtime::Molecules::ProcessIdentity.new
          @runtime_resolver = runtime_resolver
        end

        # Classify a running attempt after an interruption.
        #
        # @param attempt [Models::Attempt] Running attempt
        # @return [Symbol] :stopped, :live, or :uncertain
        def classify(attempt)
          return :live if process_live?(attempt)
          return :stopped unless process_started?(attempt)

          :uncertain
        end

        # @param attempt [Models::Attempt] Attempt to inspect
        # @return [Boolean] True when a process start was recorded
        def process_started?(attempt)
          !start_event(attempt).nil?
        end

        # @param attempt [Models::Attempt] Attempt to inspect
        # @return [Boolean] True when the recorded process is verifiably alive
        def process_live?(attempt)
          observation(attempt)["liveness"] == "live"
        end

        def observation(attempt)
          payload = start_event(attempt)&.dig("payload")
          observation = @observer.observe(payload&.dig("process_identity"))
          binding = payload&.dig("runtime_binding")
          return observation unless binding && observation["liveness"] == "live"

          live = @runtime_resolver.resolve(binding["runtime"]).process_binding(
            pane: binding["pane"], caller_pid: binding.dig("process_identity", "pid"))
          return observation if binding == live

          observation.merge("liveness" => "unknown", "reason" => "native process/session binding changed")
        rescue Ace::Runtime::Error
          {"liveness" => "unknown", "observed_at" => Time.now.utc.iso8601,
            "reason" => "native process/session observation unavailable"}
        end

        def events(attempt)
          events_for(attempt)
        end

        # Runtime recorded at the attempt's process start — the boundary any
        # reconciling receipt must attribute to.
        #
        # @param attempt [Models::Attempt] Attempt to inspect
        # @return [String, nil] Recorded runtime identity
        def recorded_runtime(attempt)
          start_event(attempt)&.dig("payload", "runtime")
        end

        private

        def start_event(attempt)
          events_for(attempt).reverse.find do |event|
            event["type"] == "process_start" && event["attempt_id"] == attempt.attempt_id
          end
        end

        def events_for(attempt)
          events = if attempt.managed?
            (@journal || Molecules::EvidenceJournal.new(repo_root: Dir.pwd))
              .read_events(attempt.binding.assignment_id)
          else
            attempt.events
          end
          # Only this attempt's events define its execution boundary.
          events.select { |event| event["attempt_id"] == attempt.attempt_id }
        end
      end
    end
  end
end
