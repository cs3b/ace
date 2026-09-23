# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Molecules
        class HermesNotificationsTest < AceHermesTestCase
          ADDRESS = "lab01/inbox/m-1"

          def test_lines_are_deterministic_single_line_texts
            emit = ->(event, **details) do
              HermesNotifications.emit(event, address: ADDRESS, **details)
            end

            assert_equal "hermes: question #{ADDRESS} received",
              emit.call(:question_received)
            assert_equal "hermes: answer #{ADDRESS} written", emit.call(:answer_written)
            assert_equal "hermes: #{ADDRESS} delivered", emit.call(:delivered)
            assert_equal "hermes: #{ADDRESS} acked (file deleted)", emit.call(:acked)
            assert_equal "hermes: #{ADDRESS} quarantined (bad JSON)",
              emit.call(:quarantined, reason: "bad JSON")
            assert_equal "hermes: #{ADDRESS} retry 1/3 (collision)",
              emit.call(:retry_scheduled, attempt: 1, max_attempts: 3, policy: "collision")
            assert_equal "hermes: #{ADDRESS} retries exhausted (undeleted)",
              emit.call(:retry_exhausted, reason: "undeleted")
          end

          def test_unknown_events_fail_closed
            error = assert_raises(ContractError) do
              HermesNotifications.emit(:nonsense, address: ADDRESS)
            end
            assert_match(/unknown hermes notification event/, error.message)
            assert_match(/question_received/, error.message)
          end
        end
      end
    end
  end
end
