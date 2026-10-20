# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module CLI
      module Commands
        class HitlCliSendRetentionTest < AceHitlTestCase
          def setup
            Adapters.reset_registry!
          end

          def teardown
            Adapters.reset_registry!
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

          def with_retention_root(*routes)
            with_hitl_dir do |root|
              config = {"hitl" => {"root_dir" => root,
                "machine" => "lab01",
                "recipients" => {"overseer" => {"machine" => "lab01", "folder" => root}},
                "adapters" => {"routes" => routes.map { |route| {"recipients" => ["overseer"]}.merge(route) }}}}
              with_cli_root(root, config: config) do
                yield root
              end
            end
          end

          def create_report
            created = run_cli(["create", "Work done", "--type", "report", "--result", "success",
              "--to", "overseer", "--task", "8xg.t.sbz.1.3", "--body", "done"])
            created[:stdout].match(/HITL event created: ([0-9a-z]{6})/)[1]
          end

          def test_retry_skips_delivered_route_and_exits_zero
            register_adapter(:alpha, status: :delivered)
            register_adapter(:beta, status: :unavailable, detail: "folder missing")

            with_retention_root(
              {"route" => "good", "adapter" => "alpha"},
              {"route" => "bad", "adapter" => "beta"}
            ) do
              id = create_report

              first = run_cli(["send", id])
              assert_equal 1, first[:exit_code]

              # beta "recovers"
              register_adapter(:beta, status: :delivered)
              second = run_cli(["send", id])

              assert_equal 0, second[:exit_code], second[:stderr]
              assert_match(/good \(alpha\): skipped - already delivered/, second[:stdout])
              assert_match(/bad \(beta\): delivered/, second[:stdout])
            end
          end

          def test_already_delivered_noop_message_and_exit_zero
            register_adapter(:alpha, status: :delivered)

            with_retention_root({"route" => "r1", "adapter" => "alpha"}) do
              id = create_report
              run_cli(["send", id])

              result = run_cli(["send", id])
              assert_equal 0, result[:exit_code], result[:stderr]
              assert_match(/r1 \(alpha\): skipped/, result[:stdout])
              assert_match(/nothing to retry \(use --force to redeliver\)/, result[:stdout])
            end
          end

          def test_force_redelivers_delivered_route
            register_adapter(:alpha, status: :delivered)

            with_retention_root({"route" => "r1", "adapter" => "alpha"}) do
              id = create_report
              run_cli(["send", id])

              result = run_cli(["send", id, "--force"])
              assert_equal 0, result[:exit_code], result[:stderr]
              refute_match(/skipped/, result[:stdout])
              assert_match(/r1 \(alpha\): delivered/, result[:stdout])
            end
          end

          def test_dry_run_prints_decisions_without_delivering
            register_adapter(:alpha, status: :delivered)

            with_retention_root({"route" => "r1", "adapter" => "alpha"}) do
              id = create_report

              result = run_cli(["send", id, "--dry-run"])
              assert_equal 0, result[:exit_code], result[:stderr]
              assert_match(/r1 \(alpha\): dry_run - undelivered - will retry/, result[:stdout])

              # Nothing was written: a real send still attempts the route.
              real = run_cli(["send", id])
              assert_equal 0, real[:exit_code], real[:stderr]
              assert_match(/r1 \(alpha\): delivered/, real[:stdout])
            end
          end

          def test_show_prints_delivery_block_with_failure_reason
            register_adapter(:alpha, status: :unavailable, detail: "herdr socket missing")

            with_retention_root({"route" => "r1", "adapter" => "alpha"}) do
              id = create_report
              run_cli(["send", id])

              result = run_cli(["show", id])
              assert_equal 0, result[:exit_code], result[:stderr]
              assert_match(/Delivery: r1 \(alpha\): unavailable - herdr socket missing/, result[:stdout])
            end
          end

          def test_list_filters_by_delivery_state
            register_adapter(:alpha, status: :delivered)

            with_retention_root({"route" => "r1", "adapter" => "alpha"}) do
              delivered_id = create_report
              run_cli(["send", delivered_id])

              # A second event whose delivery fails is retained as undelivered.
              register_adapter(:alpha, status: :unavailable, detail: "down")
              undelivered_id = create_report
              run_cli(["send", undelivered_id])

              undelivered = run_cli(["list", "--delivery", "undelivered", "--in", "all"])
              assert_equal 0, undelivered[:exit_code], undelivered[:stderr]
              assert_match(/#{undelivered_id}/, undelivered[:stdout])
              refute_match(/#{delivered_id}/, undelivered[:stdout])

              delivered = run_cli(["list", "--delivery", "delivered", "--in", "all"])
              assert_equal 0, delivered[:exit_code], delivered[:stderr]
              assert_match(/#{delivered_id}/, delivered[:stdout])
              refute_match(/#{undelivered_id}/, delivered[:stdout])

              invalid = run_cli(["list", "--delivery", "bogus"])
              assert_equal 1, invalid[:exit_code]
              assert_match(/Invalid delivery filter/, invalid[:stderr])
            end
          end
        end
      end
    end
  end
end
