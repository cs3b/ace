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
        def initialize(journal: nil, verifier: nil)
          @journal = journal
          @verifier = verifier
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
          pid = start_event(attempt)&.dig("payload", "pid")
          return false unless pid

          Process.kill(0, pid)
          true
        rescue Errno::EPERM
          true
        rescue Errno::ESRCH, TypeError, ArgumentError
          false
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
          events_for(attempt).reverse.find { |event| event["type"] == "process_start" }
        end

        def events_for(attempt)
          if attempt.managed?
            (@journal || Molecules::EvidenceJournal.new(repo_root: Dir.pwd))
              .read_events(attempt.binding.assignment_id)
          else
            attempt.events
          end
        end
      end
    end
  end
end
