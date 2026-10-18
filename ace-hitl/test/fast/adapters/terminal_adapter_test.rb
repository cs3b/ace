# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/runtime"

module Ace
  module Hitl
    module Adapters
      class TerminalAdapterTest < AceHitlTestCase
        FakeRuntime = Struct.new(:calls, :outcome) do
          def send_text(pane:, text:)
            calls << {pane: pane, text: text}
            raise outcome if outcome
          end
        end

        def setup
          @original_registry = Ace::Runtime.registry
          @calls = []
          Ace::Runtime.reset_registry!
        end

        def teardown
          Ace::Runtime.instance_variable_set(:@registry, @original_registry)
        end

        def route(runtime: "fake", pane: "p5", outcome: nil)
          @calls.clear
          Ace::Runtime.register(:fake, -> { FakeRuntime.new(@calls, outcome) })
          TerminalAdapter.new({
            "route" => "lab-terminal", "adapter" => "terminal",
            "runtime" => runtime, "pane" => pane
          })
        end

        def deliver_event(adapter)
          event = Models::HitlEvent.new(id: "abc123", status: "pending", kind: nil,
            type: "question", result: nil, title: "Which DB?", tags: [],
            questions: ["Postgres?"], answer: nil, content: "", path: nil,
            file_path: nil, special_folder: nil, created_at: nil,
            metadata: {"reply_to_machine" => "lab01", "reply_to_folder" => ".ace-local/hitl", "reply_to_id" => "abc123"})
          adapter.deliver(event: event, text: "shared text", recipient: nil, reply_to: event.reply_to)
        end

        def test_delivered_pushes_shared_text_to_pane
          result = deliver_event(route)
          assert result.delivered?
          assert_equal "lab-terminal", result.route
          assert_equal "terminal", result.adapter
          assert_equal({pane: "p5", text: "shared text"}, @calls.first)
        end

        def test_runtime_unavailable_maps_to_unavailable
          result = deliver_event(route(outcome: Ace::Runtime::RuntimeUnavailableError.new("no session")))
          assert_equal :unavailable, result.status
          assert_includes result.detail, "no session"
        end

        def test_unknown_runtime_maps_to_unavailable
          result = deliver_event(route(runtime: "ghost"))
          assert_equal :unavailable, result.status
          assert_includes result.detail, "unknown runtime 'ghost'"
        end

        def test_target_not_found_maps_to_failed
          result = deliver_event(route(outcome: Ace::Runtime::TargetNotFoundError.new("pane gone")))
          assert_equal :failed, result.status
        end

        def test_missing_runtime_key_is_a_route_config_error
          error = assert_raises(Error) do
            TerminalAdapter.new({"route" => "r", "adapter" => "terminal", "pane" => "p"})
          end
          assert_includes error.message, "missing required 'runtime'"
        end

        def test_missing_pane_key_is_a_route_config_error
          error = assert_raises(Error) do
            TerminalAdapter.new({"route" => "r", "adapter" => "terminal", "runtime" => "tmux"})
          end
          assert_includes error.message, "missing required 'pane'"
        end

        def test_recipient_panel_steers_the_target_pane
          adapter = route(pane: "wrong-pane")
          adapter.deliver(event: nil, text: "work done",
            recipient: {"machine" => "other-host", "panel" => "right-pane"}, reply_to: nil)

          assert_equal 1, @calls.size
          assert_equal "right-pane", @calls.first[:pane], "recipient panel must steer delivery"
          refute_includes @calls.map { |c| c[:pane] }, "wrong-pane"
        end

        def test_two_recipients_each_get_their_own_pane_only
          adapter = route(pane: "wrong-pane")
          first = {"machine" => "host-a", "panel" => "pane-a"}
          second = {"machine" => "host-b", "panel" => "pane-b"}

          adapter.deliver(event: nil, text: "for a", recipient: first, reply_to: nil)
          adapter.deliver(event: nil, text: "for b", recipient: second, reply_to: nil)

          panes = @calls.map { |c| c[:pane] }
          assert_equal ["pane-a", "pane-b"], panes
          refute_includes panes, "wrong-pane", "no delivery to an unrelated route pane"
        end

        def test_folder_recipient_is_an_explicit_refusal_without_send
          adapter = route(pane: "wrong-pane")
          recipient = {"machine" => "other-host", "folder" => ".ace-local/hitl", "id" => "abc123"}

          result = adapter.deliver(event: nil, text: "work done", recipient: recipient, reply_to: nil)

          assert_equal :failed, result.status
          assert_includes result.detail, "cannot deliver to folder recipient"
          assert_empty @calls, "a refused recipient must not produce any terminal send"
        end
      end
    end
  end
end
