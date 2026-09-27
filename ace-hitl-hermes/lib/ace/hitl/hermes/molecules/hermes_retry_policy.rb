# frozen_string_literal: true

module Ace
  module Hitl
    module Hermes
      module Molecules
        # Pure retry decisions (spec 8wm.t.vs1 §8). The clock-and-loop
        # belongs to the transport role (y24 / A4); this module pins the
        # policy so both sides decide identically.
        #
        # - collision retries (write time): bounded fresh-id attempts;
        # - undeleted-file retries (post-delivery): a delivered file that
        #   is not ACKed after the stale deadline is redelivered as
        #   IDENTICAL bytes, bounded, then quarantined (terminal).
        module HermesRetryPolicy
          DEFAULT_MAX_ATTEMPTS = 3
          DEFAULT_BASE_DELAY = 1.0
          DEFAULT_MAX_DELAY = 60.0

          class << self
            def collision_retry?(failed_attempts, max_attempts: DEFAULT_MAX_ATTEMPTS)
              failed_attempts < max_attempts
            end

            # Exponential backoff for the given 1-based attempt number.
            def delay_for(attempt, base_delay: DEFAULT_BASE_DELAY, max_delay: DEFAULT_MAX_DELAY)
              [base_delay * (2**(attempt - 1)), max_delay].min
            end

            # Decision for a delivered-but-not-acked file.
            # `attempts` = deliveries already performed (>= 1).
            def undeleted_decision(age_seconds:, stale_after:, attempts:, max_attempts: DEFAULT_MAX_ATTEMPTS)
              return :wait if age_seconds < stale_after
              return :redeliver if attempts < max_attempts

              :quarantine
            end
          end
        end
      end
    end
  end
end
