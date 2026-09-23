# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Molecules
        class HermesMessageTest < AceHermesTestCase
          def test_question_and_answer_constructors_carry_dictated_fields
            question = HermesMessage.question(
              id: "q-1", question: "Proceed?", sender: "agent-7", created_at: QUESTION_TS
            )
            assert question.question?
            refute question.answer?
            assert_equal "q-1", question.id
            assert_equal "Proceed?", question.body
            assert_equal "created_at", question.timestamp_field

            answer = HermesMessage.answer(
              id: "q-1", answer: "Ship it.", sender: "captain", received_at: ANSWER_TS
            )
            assert answer.answer?
            assert_equal "answer", answer.to_h["kind"]
            assert_equal ANSWER_TS, answer.to_h["received_at"]
            assert_equal "Ship it.", answer.to_h["answer"]
            assert_equal "captain", answer.to_h["sender"]
          end

          def test_canonical_json_round_trip_preserves_the_envelope
            answer = HermesMessage.answer(
              id: "a-9", answer: "Yes", sender: "captain", received_at: ANSWER_TS
            )
            json = answer.to_json
            assert_equal(
              %({"schema":"ace.hitl.hermes.message/v1","id":"a-9","kind":"answer",) +
              %("sender":"captain","answer":"Yes","received_at":"#{ANSWER_TS}"}),
              json
            )
            reparsed = HermesMessage.from_hash(HermesFormats.decode!(json))
            assert_equal answer.to_h, reparsed.to_h
          end

          def test_from_hash_happy_paths_for_both_kinds
            question = HermesMessage.from_hash(question_payload)
            assert_equal :question, question.kind
            assert_equal "agent-7", question.sender

            answer = HermesMessage.from_hash(answer_payload)
            assert_equal :answer, answer.kind
            assert_equal "Ship it.", answer.body
          end

          def test_id_must_match_file_name_stem
            error = assert_raises(InvalidMessageError) do
              HermesMessage.from_hash(answer_payload(id: "a-1"), filename_id: "a-2")
            end
            assert_match(/does not match file name stem/, error.message)
          end

          def test_field_set_is_exact_per_kind
            payload = answer_payload
            payload.delete("sender")
            error = assert_raises(InvalidMessageError) { HermesMessage.from_hash(payload) }
            assert_match(/missing: sender/, error.message)

            payload = answer_payload
            payload["extra"] = "nope"
            error = assert_raises(InvalidMessageError) { HermesMessage.from_hash(payload) }
            assert_match(/unexpected: extra/, error.message)
          end

          def test_kind_is_fail_closed
            payload = answer_payload
            payload["kind"] = "rumour"
            error = assert_raises(InvalidMessageError) { HermesMessage.from_hash(payload) }
            assert_match(/kind must be one of/, error.message)
          end

          def test_body_must_be_non_empty_string
            [nil, "", "   ", 42].each do |bad|
              payload = answer_payload(answer: bad)
              error = assert_raises(InvalidMessageError) { HermesMessage.from_hash(payload) }
              assert_match(/answer must be a non-empty string/, error.message)
            end
          end

          def test_sender_and_id_are_tokens
            payload = answer_payload(sender: "../escape")
            error = assert_raises(ContractError) { HermesMessage.from_hash(payload) }
            assert_match(/hermes sender/, error.message)

            payload = answer_payload(id: ".dot")
            assert_raises(ContractError) { HermesMessage.from_hash(payload) }
          end

          def test_timestamps_are_strict_utc_iso8601
            ["2026-09-24 10:00:00", "2026-09-24T10:00:00+02:00",
             "2026-13-01T10:00:00Z", nil, 123].each do |bad|
              payload = answer_payload(received_at: bad)
              error = assert_raises(InvalidMessageError) { HermesMessage.from_hash(payload) }
              assert_match(/received_at/, error.message)
            end
            assert_equal ANSWER_TS,
              HermesMessage.from_hash(answer_payload).timestamp
          end
        end
      end
    end
  end
end
