# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module CLI
      module Commands
        class HitlCliSendTest < AceHitlTestCase
          def setup
            Adapters.reset_registry!
          end

          def teardown
            Adapters.reset_registry!
          end

          def routes_config(*routes)
            {"hitl" => {"root_dir" => ".ace-local/hitl", "adapters" => {"routes" => routes}}}
          end

          def register_adapter(name, status:, detail: "ok")
            Adapters.register(name, ->(route) do
              adapter = Object.new
              adapter.define_singleton_method(:deliver) do |event:, text:, recipient:, reply_to:|
                Adapters::RouteResult.new(route: route["route"], adapter: name,
                  status: status, detail: detail)
              end
              adapter
            end)
          end

          def with_send_root(*routes, &block)
            with_hitl_dir do |root|
              config = {"hitl" => {"root_dir" => root, "adapters" => {"routes" => routes}}}
              with_cli_root(root, config: config, &block)
            end
          end

          def test_all_delivered_prints_per_route_lines_and_exits_zero
            register_adapter(:alpha, status: :delivered)
            register_adapter(:beta, status: :delivered)

            with_send_root(
              {"route" => "r1", "adapter" => "alpha"},
              {"route" => "r2", "adapter" => "beta"}
            ) do
              created = run_cli(["create", "Q?", "--question", "A?"])
              id = created[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]

              result = run_cli(["send", id])
              assert_equal 0, result[:exit_code], "#{result[:stderr]} --- stdout: #{result[:stdout]}"
              assert_match(/sent through 2 route\(s\):/, result[:stdout])
              assert_match(/r1 \(alpha\): delivered - ok/, result[:stdout])
              assert_match(/r2 \(beta\): delivered - ok/, result[:stdout])
            end
          end

          def test_failing_route_prints_alongside_success_and_exits_one
            register_adapter(:alpha, status: :delivered)
            register_adapter(:beta, status: :unavailable, detail: "folder missing")

            with_send_root(
              {"route" => "good", "adapter" => "alpha"},
              {"route" => "bad", "adapter" => "beta"}
            ) do
              created = run_cli(["create", "Q?", "--question", "A?"])
              id = created[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]

              result = run_cli(["send", id])
              assert_equal 1, result[:exit_code]
              assert_match(/good \(alpha\): delivered/, result[:stdout])
              assert_match(/bad \(beta\): unavailable - folder missing/, result[:stdout])
              assert_match(/not delivered on all routes/, result[:stderr])
            end
          end

          def test_no_routes_is_a_concrete_error
            with_hitl_dir do |root|
              with_cli_root(root) do
                created = run_cli(["create", "Q?", "--question", "A?"])
                id = created[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]

                result = run_cli(["send", id])
                assert_equal 1, result[:exit_code]
                assert_match(/no adapter routes configured/, result[:stderr])
                assert_match(/hitl\.adapters\.routes/, result[:stderr])
              end
            end
          end

          def test_unknown_ref_errors_without_delivery
            register_adapter(:alpha, status: :delivered)

            with_send_root({"route" => "r1", "adapter" => "alpha"}) do
              result = run_cli(["send", "zzz999"])
              assert_equal 1, result[:exit_code]
              assert_match(/not found/, result[:stderr])
            end
          end
        end
      end
    end
  end
end
