# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Molecules
        class HermesRetryPolicyTest < AceHermesTestCase
          def test_collision_retries_are_bounded
            assert HermesRetryPolicy.collision_retry?(0)
            assert HermesRetryPolicy.collision_retry?(1)
            assert HermesRetryPolicy.collision_retry?(2)
            refute HermesRetryPolicy.collision_retry?(3)
          end

          def test_backoff_is_exponential_with_a_cap
            assert_in_delta 1.0, HermesRetryPolicy.delay_for(1)
            assert_in_delta 2.0, HermesRetryPolicy.delay_for(2)
            assert_in_delta 4.0, HermesRetryPolicy.delay_for(3)
            assert_in_delta HermesRetryPolicy::DEFAULT_MAX_DELAY,
              HermesRetryPolicy.delay_for(30)
          end

          def test_undeleted_progression_wait_redeliver_quarantine
            decision = ->(age:, attempts:) do
              HermesRetryPolicy.undeleted_decision(
                age_seconds: age, stale_after: 60.0, attempts: attempts
              )
            end

            assert_equal :wait, decision.call(age: 0.0, attempts: 1)
            assert_equal :wait, decision.call(age: 59.9, attempts: 1)
            assert_equal :redeliver, decision.call(age: 60.0, attempts: 1)
            assert_equal :redeliver, decision.call(age: 600.0, attempts: 2)
            assert_equal :quarantine, decision.call(age: 600.0, attempts: 3)
          end
        end
      end
    end
  end
end
