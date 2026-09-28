# frozen_string_literal: true

require "json"
require "time"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class TidyTest < Minitest::Test
          NOW = Time.iso8601("2026-09-28T12:00:00Z")

          def setup
            @executor = HerdrTestHelper::FakeExecutor.new
            @dir = Dir.mktmpdir("ace_herdr_tidy_cmd_test")
          end

          def teardown
            FileUtils.rm_rf(@dir)
          end

          def delivered(event_id, state: "delivered", updated_at: NOW.iso8601)
            Models::DeliveryRecord.new(
              event_id: event_id, session: "ws-1", pane: "p5", answer_digest: "d" * 64,
              state: state, updated_at: updated_at
            )
          end

          def config(retention_days: 7)
            {"tidy" => {"delivered_retention_days" => retention_days},
             "deliveries_dir" => File.join(@dir, "deliveries")}
          end

          def cmd(executor: @executor, cfg: config)
            Tidy.new(executor: executor, config: cfg)
          end

          def test_default_invocation_emits_dry_run_json
            out, = capture_io { cmd.call(apply: nil, quiet: nil) }

            parsed = JSON.parse(out)
            assert_equal false, parsed["apply"]
            assert_equal [], parsed["panes"]["candidates"]
            assert_equal [], parsed["deliveries"]["archived"]
          end

          def test_apply_closes_eligible_pane_and_archives_old_delivered_record
            Molecules::DeliveryRecordStore.save(
              delivered("evt-old", updated_at: (NOW - 8 * 86_400).iso8601), File.join(@dir, "deliveries")
            )
            outcomes = {
              pane_list: Molecules::ExecutionResult.new(
                stdout: JSON.generate(result: {panes: [{"pane_id" => "w5:p2"}]}),
                stderr: "", success: true, exit_code: 0
              ),
              agent_get: Molecules::ExecutionResult.new(
                stdout: JSON.generate(result: {agent: {"agent_status" => "done"}}),
                stderr: "", success: true, exit_code: 0
              )
            }
            executor = HerdrTestHelper::FakeExecutor.new(outcomes: outcomes)

            out, = capture_io { cmd(executor: executor).call(apply: true, quiet: nil) }

            parsed = JSON.parse(out)
            assert_equal true, parsed["apply"]
            assert_equal ["w5:p2"], parsed["panes"]["closed"].map { |e| e["id"] }
            assert_equal ["evt-old"], parsed["deliveries"]["archived"].map { |e| e["event_id"] }
          end

          def test_apply_keeps_failed_and_recent_records
            store_dir = File.join(@dir, "deliveries")
            Molecules::DeliveryRecordStore.save(delivered("evt-fail", state: "failed"), store_dir)
            Molecules::DeliveryRecordStore.save(delivered("evt-new"), store_dir)

            out, = capture_io { cmd.call(apply: true, quiet: nil) }

            parsed = JSON.parse(out)
            assert_equal [], parsed["deliveries"]["archived"]
            assert_equal %w[evt-fail evt-new], parsed["deliveries"]["protected"].map { |e| e["event_id"] }
          end

          def test_quiet_suppresses_output
            out, = capture_io { cmd.call(apply: nil, quiet: true) }

            assert_equal "", out
          end

          def test_missing_runtime_surfaces_translated_cli_error
            executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              pane_list: ExecutorUnavailableError.new("herdr CLI not found on PATH: herdr")
            })

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd(executor: executor).call(apply: nil, quiet: nil)
            end

            assert_match(/herdr CLI not found/, error.message)
          end

          def test_retention_override_from_config_changes_the_cutoff
            store_dir = File.join(@dir, "deliveries")
            Molecules::DeliveryRecordStore.save(delivered("evt-3d", updated_at: (NOW - 3 * 86_400).iso8601), store_dir)
            Molecules::DeliveryRecordStore.save(delivered("evt-1h", updated_at: (NOW - 3600).iso8601), store_dir)

            out, = capture_io { cmd(cfg: config(retention_days: 1)).call(apply: true, quiet: nil) }

            parsed = JSON.parse(out)
            assert_equal 1, parsed["retention_days"]
            assert_equal ["evt-3d"], parsed["deliveries"]["archived"].map { |e| e["event_id"] }
          end

          def test_invalid_retention_value_surfaces_cli_error
            error = assert_raises(Ace::Support::Cli::Error) do
              cmd(cfg: config(retention_days: "week")).call(apply: nil, quiet: nil)
            end

            assert_match(/non-negative integer/, error.message)
          end
        end
      end
    end
  end
end
