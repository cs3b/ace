# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Organisms
        class HermesBoxTest < AceHermesTestCase
          def test_publish_writes_canonical_v1_answer_atomically
            with_hermes_dir do |folder|
              notifier, lines = collector
              box, = build_box(folder, notifier: notifier)

              message = box.publish(
                kind: :answer, id: "q-1", body: "Ship it.",
                sender: "captain", timestamp: ANSWER_TS
              )

              assert_equal "q-1", message.id
              assert_equal "lab01/#{File.basename(folder)}/q-1", box.address("q-1")
              path = File.join(folder, "q-1.json")
              assert File.exist?(path)
              assert_equal 0o640, (File.stat(path).mode & 0o777)
              assert_equal message.to_json, File.read(path)
              assert_empty tmp_leftovers(folder)
              assert_includes lines,
                "hermes: answer lab01/#{File.basename(folder)}/q-1 written"
            end
          end

          def test_publish_generates_token_ids_when_none_given
            with_hermes_dir do |folder|
              box, = build_box(folder)
              message = box.publish(
                kind: :answer, body: "ok", sender: "captain", timestamp: ANSWER_TS
              )
              assert_match(/\A[A-Za-z0-9][A-Za-z0-9._:-]{0,63}\z/, message.id)
              assert File.exist?(File.join(folder, "#{message.id}.json"))
            end
          end

          def test_publish_retries_collisions_with_a_fresh_id
            with_hermes_dir do |folder|
              write_file(File.join(folder, "fixed-id.json"), "taken by another writer")
              ids = %w[fixed-id fresh-id spare-id]
              notifier, lines = collector
              box, = build_box(folder, id_generator: -> { ids.shift },
                notifier: notifier)

              message = box.publish(
                kind: :answer, body: "ok", sender: "captain", timestamp: ANSWER_TS
              )

              assert_equal "fresh-id", message.id
              assert_equal message.to_json, File.read(File.join(folder, "fresh-id.json"))
              assert_equal "taken by another writer",
                File.read(File.join(folder, "fixed-id.json"))
              assert_empty tmp_leftovers(folder)
              retry_line = lines.find { |l| l.include?("retry 1/3 (collision)") }
              assert retry_line, "expected a collision retry notification, got: #{lines}"
            end
          end

          def test_publish_fails_terminally_when_collisions_are_exhausted
            with_hermes_dir do |folder|
              box, = build_box(folder, id_generator: -> { "same-id" })
              write_file(File.join(folder, "same-id.json"), "taken")

              error = assert_raises(CollisionError) do
                box.publish(
                  kind: :answer, body: "ok", sender: "captain", timestamp: ANSWER_TS
                )
              end
              assert_match(/already exists/, error.message)
              assert_equal "taken", File.read(File.join(folder, "same-id.json"))
            end
          end

          def test_poll_returns_validated_messages_and_skips_foreign_names
            with_hermes_dir do |folder|
              box, = build_box(folder)
              message_file(folder, "q-1", question_payload)
              message_file(folder, "q-2", question_payload(id: "q-2", question: "Second?"))
              write_file(File.join(folder, "notes.txt"), "not a message")
              write_file(File.join(folder, ".hidden"), "dotfile")
              write_file(File.join(folder, ".hermes-tmp-123-ab.tmp"), "crashed writer")

              result = box.poll

              assert_equal 2, result.messages.length
              assert_equal %w[q-1 q-2], result.messages.map(&:id)
              assert result.messages.first.question?
              assert_empty result.quarantined
              assert File.exist?(File.join(folder, "notes.txt"))
              assert File.exist?(File.join(folder, ".hidden"))
              assert File.exist?(File.join(folder, ".hermes-tmp-123-ab.tmp"))
            end
          end

          def test_poll_quarantines_invalid_files_and_never_delivers_them
            with_hermes_dir do |folder|
              notifier, lines = collector
              box, = build_box(folder, notifier: notifier)
              write_file(File.join(folder, "bad-1.json"), "{not json")
              message_file(folder, "bad-2", answer_payload(id: "wrong-inner-id"))
              message_file(folder, "ok-1", answer_payload(id: "ok-1"))

              result = box.poll

              assert_equal 1, result.messages.length
              assert_equal "ok-1", result.messages.first.id
              assert_equal 2, result.quarantined.length
              reasons = result.quarantined.map(&:reason)
              assert reasons.any? { |r| r.include?("not valid JSON") }
              assert reasons.any? { |r| r.include?("does not match file name stem") }
              quarantine_dir = File.join(folder, ".quarantine")
              assert File.exist?(File.join(quarantine_dir, "bad-1.json"))
              assert File.exist?(File.join(quarantine_dir, "bad-2.json"))
              assert File.exist?(File.join(quarantine_dir, "bad-1.json#{Ace::Hitl::Hermes::Molecules::HermesContract::REASON_EXT}"))
              assert lines.any? { |l| l.include?("quarantined") }

              second = box.poll
              assert_equal 1, second.messages.length # poll observes; ACK removes
              assert_empty second.quarantined

              box.ack("ok-1")
              third = box.poll
              assert_empty third.messages
              assert_empty third.quarantined
            end
          end

          def test_poll_quarantines_empty_files_and_the_channel_survives
            with_hermes_dir do |folder|
              notifier, lines = collector
              box, = build_box(folder, notifier: notifier)
              write_file(File.join(folder, "empty-1.json"), "")
              message_file(folder, "ok-1", question_payload(id: "ok-1"))

              result = box.poll

              assert_equal 1, result.messages.length
              assert_equal "ok-1", result.messages.first.id
              assert_equal 1, result.quarantined.length
              assert result.quarantined.first.reason.include?("not valid JSON")
              assert File.exist?(File.join(folder, ".quarantine", "empty-1.json"))
              assert lines.any? { |l| l.include?("quarantined") }

              second = box.poll
              assert_equal 1, second.messages.length
              assert_empty second.quarantined
            end
          end

          def test_ack_deletes_the_file_and_is_idempotent
            with_hermes_dir do |folder|
              box, = build_box(folder)
              message_file(folder, "q-1", question_payload)

              assert_equal :acked, box.ack("q-1")
              refute File.exist?(File.join(folder, "q-1.json"))
              assert_equal :already_acked, box.ack("q-1")
            end
          end

          def test_age_is_the_retry_clock_and_nil_after_ack
            with_hermes_dir do |folder|
              box, = build_box(folder)
              message_file(folder, "q-1", question_payload)

              age = box.age("q-1")
              assert age >= 0.0 && age < 5.0
              assert_nil box.age("missing-id")

              box.ack("q-1")
              assert_nil box.age("q-1")
            end
          end

          def test_identical_checks_redelivery_identity
            with_hermes_dir do |folder|
              box, = build_box(folder)
              bytes = JSON.generate(answer_payload)
              write_file(File.join(folder, "a-1.json"), bytes)

              assert box.identical?("a-1", bytes)
              refute box.identical?("a-1", bytes + " ")
              refute box.identical?("a-2", bytes)
            end
          end

          def test_invalid_ids_never_reach_the_filesystem
            with_hermes_dir do |folder|
              box, = build_box(folder)
              ["../escape", ".dot", "", "a/b"].each do |bad|
                assert_raises(ContractError) { box.ack(bad) }
                assert_raises(ContractError) { box.age(bad) }
              end
              assert_equal Dir.children(folder).sort, []
            end
          end

          def test_publish_with_explicit_correlated_id_never_renames_on_collision
            with_hermes_dir do |folder|
              box, = build_box(folder)
              write_file(File.join(folder, "hitl-42.json"), "question not acked yet")

              error = assert_raises(CollisionError) do
                box.publish(
                  kind: :answer, id: "hitl-42", body: "ok",
                  sender: "captain", timestamp: ANSWER_TS
                )
              end
              assert_match(/already exists/, error.message)
              assert_equal "question not acked yet",
                File.read(File.join(folder, "hitl-42.json"))
            end
          end

          def test_full_folder_contract_flow_question_answer_deliver_ack
            with_hermes_dir do |folder|
              lab_notifs, lab_lines = collector
              hermes_notifs, hermes_lines = collector
              lab_box, = build_box(folder, notifier: lab_notifs)
              hermes_box, = build_box(folder, notifier: hermes_notifs)

              # lab side: agent asks through the folder (atomic write)
              question = lab_box.publish(
                kind: :question, id: "hitl-42", body: "Proceed with deploy?",
                sender: "agent-7", timestamp: QUESTION_TS
              )

              # hermes side: pick the question up (push to the Captain);
              # ACK = deletion, which also frees <id>.json for the answer
              picked = hermes_box.poll
              assert_equal 1, picked.messages.length
              assert_equal question.id, picked.messages.first.id
              assert_equal "Proceed with deploy?", picked.messages.first.body
              assert hermes_lines.any? { |l| l.include?("question lab01/#{File.basename(folder)}/hitl-42 received") }
              assert_equal :acked, hermes_box.ack("hitl-42")

              # hermes side: the Captain's answer reuses the question id
              # and is written atomically
              answer = hermes_box.publish(
                kind: :answer, id: "hitl-42", body: "Ship it.",
                sender: "captain", timestamp: ANSWER_TS
              )
              assert answer.answer?
              assert_equal %w[schema id kind sender answer received_at].sort,
                JSON.parse(File.read(File.join(folder, "hitl-42.json"))).keys.sort

              # lab side: push delivery observed, then ACK = deletion
              delivered = lab_box.poll
              assert_equal 1, delivered.messages.length
              assert delivered.messages.first.answer?
              assert_equal "Ship it.", delivered.messages.first.body

              assert box_acked = lab_box.ack("hitl-42")
              assert_equal :acked, box_acked
              final = lab_box.poll
              assert_empty final.messages
              assert_empty final.quarantined
              assert_equal :already_acked, lab_box.ack("hitl-42")

              assert lab_lines.any? { |l| l.include?("acked (file deleted)") }
            end
          end
        end
      end
    end
  end
end
