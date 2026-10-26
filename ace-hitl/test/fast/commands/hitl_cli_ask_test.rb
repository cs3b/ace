# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module CLI
      module Commands
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
                        "adapters" => {"routes" => [{"route" => "captain", "adapter" => "fixture", "recipients" => ["captain"]}]}}}
          end

          def register_fixture_adapter
            Adapters.register(:fixture, ->(route) do
              adapter = Object.new
              adapter.define_singleton_method(:deliver) do |event:, text:, recipient:, reply_to:|
                Adapters::RouteResult.new(route: route["route"], adapter: "fixture",
                  status: :delivered, detail: "fixture delivery")
              end
              adapter
            end)
          end

          def test_ask_returns_a_real_answer_end_to_end_on_a_fixture_route
            register_fixture_adapter
            with_hitl_dir do |root|
              config = routes_config(root)
              with_cli_root(root, config: config) do
                answerer = Thread.new do
                  sleep 0.2
                  manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: config)
                  event = manager.list(in_folder: "all").first
                  manager.accept_answer(event.id, answer: "Proceed with JWT")
                end

                result = run_cli(["ask", "Continue with batch 2?", "--to", "captain",
                  "--kind", "approval", "--question", "Proceed?", "--task", "8xg.t.1",
                  "--poll-every", "1", "--timeout", "10"])
                answerer.join
                assert_equal 0, result[:exit_code], result[:stderr]
                assert_includes result[:stdout], "HITL event created:"
                assert_includes result[:stdout], "captain (fixture): delivered"
                assert_includes result[:stdout], "Answer: Proceed with JWT"
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

          def test_ask_times_out_with_a_clear_error
            register_fixture_adapter
            with_hitl_dir do |root|
              config = routes_config(root)
              with_cli_root(root, config: config) do
                result = run_cli(["ask", "Anyone there?", "--to", "captain",
                  "--poll-every", "1", "--timeout", "1"])
                assert_equal 1, result[:exit_code]
                assert_match(/Timed out waiting for HITL event/, result[:stderr])
              end
            end
          end

          def test_ask_fails_fast_when_no_route_delivers
            with_hitl_dir do |root|
              with_cli_root(root) do
                result = run_cli(["ask", "Continue?", "--to", "captain"])
                assert_equal 1, result[:exit_code]
                assert_match(/Unknown HITL recipient 'captain'/, result[:stderr])
              end
            end
          end
        end
      end
    end
  end
end
