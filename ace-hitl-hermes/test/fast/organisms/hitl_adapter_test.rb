# frozen_string_literal: true

require_relative "../../test_helper"
$LOAD_PATH.unshift File.expand_path("../../../ace-hitl/lib", __dir__) if Dir.exist?(File.expand_path("../../../ace-hitl/lib", __dir__))
require "ace/hitl"
require "ace/hitl/adapters/hermes"

module Ace
  module Hitl
    module Hermes
      module Organisms
        class HitlAdapterTest < AceHermesTestCase
          def route(folder, sender: nil)
            {"route" => "captain-telegram", "adapter" => "hermes",
             "channel" => "project", "machine" => "lab01",
             "folder" => folder, "sender" => sender}.compact
          end

          def question_event(id: "8xhk91")
            hitl_event = Ace::Hitl::Models::HitlEvent.new(
              id: id, status: "pending", kind: "decision", type: "question",
              result: nil, title: "Which DB?", tags: [], questions: ["Postgres?"],
              answer: nil, content: "", path: nil, file_path: nil,
              special_folder: nil, created_at: nil,
              metadata: {
                "reply_to_machine" => "lab01", "reply_to_folder" => ".ace-local/hitl",
                "reply_to_id" => id
              })
            [hitl_event, Ace::Hitl::Atoms::HitlEventText.call(hitl_event)]
          end

          def report_event(id: "8xhk92")
            hitl_event = Ace::Hitl::Models::HitlEvent.new(
              id: id, status: "recorded", kind: nil, type: "report",
              result: "success", title: "Work done", tags: [], questions: [],
              answer: nil,
              content: "# Work done\n\n## Report\n\nResult: success\n\n- Done the thing",
              path: nil, file_path: nil, special_folder: nil, created_at: nil,
              metadata: {"task" => "8xg.t.sbz.1.2"})
            [hitl_event, Ace::Hitl::Atoms::HitlEventText.call(hitl_event)]
          end

          def test_question_publishes_envelope_with_reply_to_body
            with_hermes_dir do |folder|
              adapter = HitlAdapter.new(route(folder))
              event, text = question_event

              result = adapter.deliver(event: event, text: text,
                recipient: event.recipient, reply_to: event.reply_to)

              assert result.delivered?
              envelope = JSON.parse(File.read(File.join(folder, "#{event.id}.json")))
              assert_equal "question", envelope["kind"]
              assert_equal event.id, envelope["id"]
              assert_equal "lab01", envelope["sender"]
              assert_equal text, envelope["question"]
              assert_includes envelope["question"], "Reply-To: lab01/.ace-local/hitl/#{event.id}"
            end
          end

          def test_report_publishes_typed_body_without_reply
            with_hermes_dir do |folder|
              adapter = HitlAdapter.new(route(folder))
              event, text = report_event

              result = adapter.deliver(event: event, text: text, recipient: nil, reply_to: nil)

              assert result.delivered?
              envelope = JSON.parse(File.read(File.join(folder, "#{event.id}.json")))
              assert_includes envelope["question"], "[HITL report success]"
              refute_includes envelope["question"], "Reply-To:"
            end
          end

          def test_identical_resend_is_idempotent
            with_hermes_dir do |folder|
              adapter = HitlAdapter.new(route(folder))
              event, text = question_event

              first = adapter.deliver(event: event, text: text, recipient: nil, reply_to: nil)
              bytes = File.read(File.join(folder, "#{event.id}.json"))
              second = adapter.deliver(event: event, text: text, recipient: nil, reply_to: nil)

              assert first.delivered?
              assert second.delivered?
              assert_includes second.detail, "already pending"
              assert_equal bytes, File.read(File.join(folder, "#{event.id}.json"))
            end
          end

          def test_different_content_collision_fails_without_overwrite
            with_hermes_dir do |folder|
              adapter = HitlAdapter.new(route(folder))
              event, text = question_event
              adapter.deliver(event: event, text: text, recipient: nil, reply_to: nil)
              bytes = File.read(File.join(folder, "#{event.id}.json"))

              conflicting = adapter.deliver(event: event, text: "#{text}\nEXTRA",
                recipient: nil, reply_to: nil)

              assert_equal :failed, conflicting.status
              assert_includes conflicting.detail, "different content"
              assert_equal bytes, File.read(File.join(folder, "#{event.id}.json"))
            end
          end

          def test_missing_folder_is_unavailable
            with_hermes_dir do |tmp|
              ghost = File.join(tmp, "ghost-channel")
              adapter = HitlAdapter.new(route(ghost))
              event, text = question_event

              result = adapter.deliver(event: event, text: text, recipient: nil, reply_to: nil)

              assert_equal :unavailable, result.status
              assert_includes result.detail, tmp
            end
          end

          def test_missing_channel_is_a_route_config_error
            with_hermes_dir do |folder|
              bad = route(folder).reject { |key, _| key == "channel" }
              error = assert_raises(Ace::Hitl::Adapters::Error) do
                HitlAdapter.new(bad)
              end
              assert_includes error.message, "missing required 'channel'"
            end
          end

          def test_delivery_and_reply_flow_correlates_by_exact_id
            with_hermes_dir do |folder|
              adapter = HitlAdapter.new(route(folder))
              event, text = question_event
              adapter.deliver(event: event, text: text,
                recipient: event.recipient, reply_to: event.reply_to)

              # The Captain answers: an answer file with the SAME id,
              # written atomically into the channel folder.
              answer_envelope = {
                "schema" => "ace.hitl.hermes.message/v1",
                "id" => event.id,
                "kind" => "answer",
                "answer" => "Use Postgres",
                "sender" => "captain",
                "received_at" => ANSWER_TS
              }
              answer_path = File.join(folder, "#{event.id}.json")
              tmp_path = "#{answer_path}.tmp.#{Process.pid}"
              File.write(tmp_path, JSON.generate(answer_envelope))
              File.rename(tmp_path, answer_path)

              # The lab side polls the channel and correlates by exact id.
              polled = HermesBox.new(channel: "project",
                registry: channel_registry(folder)).poll.messages
              answer = polled.find { |message| message.id == event.id && message.answer? }
              refute_nil answer, "expected the answer correlated by exact id"
              assert_equal "Use Postgres", answer.body

              # Local binding: the answer updates the original case.
              # (Simulated manager update; binding is by exact event id.)
              assert_equal event.id, answer.id
            end
          end

          private

          def channel_registry(folder)
            registry = Molecules::HermesChannels::Registry.new
            registry.register("project", machine: "lab01", folder: folder)
            registry
          end
        end
      end
    end
  end
end
