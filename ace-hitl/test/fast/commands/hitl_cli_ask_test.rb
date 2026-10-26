# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module CLI
      module Commands
        # The ask contract: create + send + arm the asking agent's own answer
        # wake + END TURN. ask never blocks, never polls, and carries no
        # timeouts; the answer arrives as an ace-wake wake carrying the
        # content. The bridge contract (wake-request drop file) is consumed
        # by ace-wake's ask bridge (ace-wake/wake/ask-bridge.js).
        class HitlCliAskTest < AceHitlTestCase
          def setup
            Adapters.reset_registry!
          end

          def teardown
            Adapters.reset_registry!
          end

          def routes_config(root)
            {"hitl" => {"root_dir" => root, "machine" => "lab",
                        "recipients" => {"captain" => {"machine" => "lab", "panel" => "cap"}},
                        "adapters" => {"routes" => [{"route" => "captain", "adapter" => "fixture",
                                                     "recipients" => ["captain"]}]}}}
          end

          def register_fixture_adapter
            delivered_text = []
            Adapters.register(:fixture, ->(route) do
              adapter = Object.new
              adapter.define_singleton_method(:deliver) do |event:, text:, recipient:, reply_to:|
                delivered_text << text
                Adapters::RouteResult.new(route: route["route"], adapter: "fixture",
                  status: :delivered, detail: "fixture delivery")
              end
              adapter.define_singleton_method(:rendered_texts) { delivered_text }
              adapter
            end)
          end

          def test_ask_sends_arms_the_wake_and_ends_the_turn_without_blocking
            register_fixture_adapter
            with_hitl_dir do |root|
              config = routes_config(root)
              with_cli_root(root, config: config) do
                result = run_cli(["ask", "Continue with batch 2?", "--to", "captain",
                  "--kind", "approval", "--question", "Proceed?", "--task", "8xg.t.1"])
                assert_equal 0, result[:exit_code], result[:stderr]

                # ask ends after arming: the final stdout line is the case id.
                case_id = result[:stdout].lines.last&.strip
                assert_match(/\A[0-9a-z]{6}\z/, case_id, "final stdout line must be the case id")
                assert_includes result[:stdout], "HITL event created: #{case_id}"
                assert_includes result[:stdout], "captain (fixture): delivered"
                refute_includes result[:stdout], "Answer:", "ask must not wait for an answer"

                # The wake request drop file arms the asking agent's watch.
                request_path = File.join(root, "wake-requests", "#{case_id}.json")
                assert File.file?(request_path), "wake request must be dropped: #{request_path}"
                request = JSON.parse(File.read(request_path))
                assert_equal "ace.wake.ask/v1", request.fetch("schema")
                assert_equal "ask", request.fetch("kind")
                assert_equal case_id, request.fetch("case_id")
                assert File.file?(request.fetch("case_path")),
                  "the request must point at the real case file"

                # The fixture answer lands in exactly that case file: the wake
                # the bridge armed watches THIS file's fingerprint.
                manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: config)
                manager.accept_answer(case_id, answer: "Proceed with JWT")
                assert_includes File.read(request.fetch("case_path")), "Proceed with JWT"
              end
            end
          end

          def test_ask_text_carries_no_urgency_language_and_no_time_limits
            register_fixture_adapter
            with_hitl_dir do |root|
              config = routes_config(root)
              with_cli_root(root, config: config) do
                result = run_cli(["ask", "Which auth strategy?", "--to", "captain",
                  "--question", "JWT or sessions?"])
                assert_equal 0, result[:exit_code], result[:stderr]

                adapter = Adapters.resolve(:fixture, route: config.dig("hitl", "adapters", "routes").first)
                text = adapter.rendered_texts.join("\n")
                refute_empty text
                assert_no_urgency(text)
              end
            end
          end

          def test_ask_has_no_asker_side_timeout_or_poll_flags
            register_fixture_adapter
            with_hitl_dir do |root|
              with_cli_root(root, config: routes_config(root)) do
                ["--timeout", "--poll-every"].each do |flag|
                  result = run_cli(["ask", "Anyone?", "--to", "captain", flag, "5"])
                  assert_equal 1, result[:exit_code], "#{flag} must not exist on ask"
                  assert_match(/invalid option|Unexpected arguments/i, result[:stderr])
                end
              end
            end
          end

          def test_ask_requires_the_recipient
            with_hitl_dir do |root|
              with_cli_root(root) do
                result = run_cli(["ask", "Continue?"])
                assert_equal 1, result[:exit_code]
                assert_match(/Missing required options: .*to/, result[:stderr])
              end
            end
          end

          def test_ask_fails_closed_before_any_wake_request_when_delivery_fails
            with_hitl_dir do |root|
              with_cli_root(root) do
                result = run_cli(["ask", "Continue?", "--to", "captain"])
                assert_equal 1, result[:exit_code]
                assert_match(/Unknown HITL recipient 'captain'/, result[:stderr])
                assert_empty Dir.children(File.join(root, "wake-requests")).to_a rescue assert true
              end
            end
          end

          private

          def assert_no_urgency(text)
            urgency = %r{\b(reply immediately|urgent|asap|immediately|deadline|time limit|within \d+)\b}i
            refute_match(urgency, text, "ask text must carry no urgency language or time limits")
          end
        end
      end
    end
  end
end
