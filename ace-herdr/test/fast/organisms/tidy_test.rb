# frozen_string_literal: true

require "json"
require "time"
require "test_helper"

module Ace
  module Herdr
    module Organisms
      class TidyTest < Minitest::Test
        NOW = Time.iso8601("2026-09-28T12:00:00Z")
        CUTOFF_7D = NOW - 7 * 86_400

        # FakeExecutor whose outcomes are consumed once per call, in order —
        # for probe sequences that differ between discovery and revalidation
        class ScriptedExecutor < HerdrTestHelper::FakeExecutor
          def initialize(script = {})
            @script = script.transform_keys(&:to_sym)
            super()
          end

          private

          def call(operation, args)
            @calls << {operation: operation, args: args}
            outcome = Array(@script[operation]).shift
            raise outcome if outcome.is_a?(Exception)
            return outcome if outcome.is_a?(Molecules::ExecutionResult)

            success
          end
        end

        def setup
          @dir = Dir.mktmpdir("ace_herdr_tidy_test")
          @clock = Object.new
          @clock.define_singleton_method(:now) { NOW }
        end

        def teardown
          FileUtils.rm_rf(@dir)
        end

        def agent_result(status)
          Molecules::ExecutionResult.new(
            stdout: JSON.generate(result: {agent: {"agent_status" => status}, type: "agent_info"}),
            stderr: "", success: true, exit_code: 0
          )
        end

        def pane_list_result(ids)
          Molecules::ExecutionResult.new(
            stdout: JSON.generate(result: {panes: ids.map { |id| {"pane_id" => id} }, type: "pane_list"}),
            stderr: "", success: true, exit_code: 0
          )
        end

        def tidy(executor, retention_days: Tidy::DEFAULT_RETENTION_DAYS)
          Tidy.new(
            executor: executor, deliveries_dir: @dir,
            retention_days: retention_days, clock: @clock
          )
        end

        def record(event_id, state:, updated_at:)
          Models::DeliveryRecord.new(
            event_id: event_id, session: "ws-1", pane: "p5", answer_digest: "d" * 64,
            state: state, updated_at: updated_at
          )
        end

        def save_record(record)
          Molecules::DeliveryRecordStore.save(record, @dir)
        end

        def dead_pane_script
          {
            pane_list: pane_list_result(%w[w5:p2]),
            agent_get: [agent_result("done"), agent_result("done")]
          }
        end

        # --- discovery / dry run ------------------------------------------------

        def test_dry_run_reports_candidates_without_any_mutation
          save_record(record("evt-old", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: pane_list_result(%w[w5:p2]),
            agent_get: agent_result("done")
          })

          report = tidy(executor).run

          assert_equal false, report[:apply]
          assert_equal [{id: "w5:p2", evidence: "agent_done"}], report[:panes][:candidates]
          assert_equal [], report[:panes][:closed]
          assert_equal [{event_id: "evt-old", updated_at: (CUTOFF_7D - 60).iso8601}],
            report[:deliveries][:candidates]
          assert_equal [], report[:deliveries][:archived]
          refute executor.calls.any? { |c| %i[pane_rename pane_close].include?(c[:operation]) }
          refute Dir.exist?(File.join(@dir, "archive"))
        end

        def test_unknown_and_unreadable_panes_reported_as_preserved
          # FakeExecutor outcomes are keyed by operation; use scripted per-call outcomes
          executor = ScriptedExecutor.new(
            pane_list: pane_list_result(%w[w5:pa w5:pu w5:pe]),
            agent_get: [agent_result("idle"), agent_result("unknown"), CommandError.new("boom")]
          )

          report = tidy(executor).run

          assert_equal [], report[:panes][:candidates]
          assert_equal(
            [
              {id: "w5:pa", reason: "active"},
              {id: "w5:pe", reason: "unreadable"},
              {id: "w5:pu", reason: "unknown"}
            ],
            report[:panes][:preserved]
          )
        end

        def test_no_candidates_is_an_explicit_empty_success
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: pane_list_result([])
          })

          report = tidy(executor).run

          assert_equal(
            {candidates: [], preserved: [], closed: [], excluded: []},
            report[:panes]
          )
          assert_equal({candidates: [], protected: [], archived: [], preserved: []}, report[:deliveries])
        end

        def test_missing_runtime_aborts_before_any_mutation
          save_record(record("evt-old", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: ExecutorUnavailableError.new("herdr CLI not found on PATH")
          })

          assert_raises(ExecutorUnavailableError) { tidy(executor).run(apply: true) }

          assert_equal [:pane_list], executor.calls.map { |c| c[:operation] }
          refute Dir.exist?(File.join(@dir, "archive"))
        end

        # --- apply: panes ---------------------------------------------------------

        def test_apply_closes_revalidated_pane_rename_before_close
          executor = ScriptedExecutor.new(dead_pane_script)

          report = tidy(executor).run(apply: true)

          assert_equal [{id: "w5:p2"}], report[:panes][:closed]
          assert_equal [:pane_list, :agent_get, :agent_get, :pane_rename, :pane_close],
            executor.calls.map { |c| c[:operation] }
          rename = executor.calls_of(:pane_rename).first
          assert_equal({pane: "w5:p2", label: "done"}, rename[:args])
        end

        def test_apply_excludes_candidate_that_revived_between_probes
          executor = ScriptedExecutor.new(
            pane_list: pane_list_result(%w[w5:p2]),
            agent_get: [agent_result("done"), agent_result("working")]
          )

          report = tidy(executor).run(apply: true)

          assert_equal [], report[:panes][:closed]
          assert_equal [{id: "w5:p2", reason: "active"}], report[:panes][:excluded]
          refute executor.calls.any? { |c| %i[pane_rename pane_close].include?(c[:operation]) }
        end

        def test_apply_excludes_candidate_whose_probe_became_unreadable
          executor = ScriptedExecutor.new(
            pane_list: pane_list_result(%w[w5:p2]),
            agent_get: [agent_result("done"), CommandError.new("boom")]
          )

          report = tidy(executor).run(apply: true)

          assert_equal [], report[:panes][:closed]
          assert_equal [{id: "w5:p2", reason: "unreadable"}], report[:panes][:excluded]
        end

        def test_apply_skips_preserved_panes_entirely
          # discovery: p1 active (preserved), p2 done (candidate); re-probe: p2 done
          executor = ScriptedExecutor.new(
            pane_list: pane_list_result(%w[w5:p1 w5:p2]),
            agent_get: [agent_result("idle"), agent_result("done"), agent_result("done")]
          )

          report = tidy(executor).run(apply: true)

          assert_equal [{id: "w5:p2"}], report[:panes][:closed]
          assert_equal [{id: "w5:p1", reason: "active"}], report[:panes][:preserved]
          assert_equal 3, executor.calls_of(:agent_get).length
        end

        # --- discovery: deliveries --------------------------------------------------

        def test_delivered_older_than_retention_is_candidate
          save_record(record("evt-old", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))

          report = tidy(HerdrTestHelper::FakeExecutor.new).run

          assert_equal [{event_id: "evt-old", updated_at: (CUTOFF_7D - 60).iso8601}],
            report[:deliveries][:candidates]
        end

        def test_delivered_exactly_at_retention_boundary_is_protected
          save_record(record("evt-edge", state: "delivered", updated_at: CUTOFF_7D.iso8601))

          report = tidy(HerdrTestHelper::FakeExecutor.new).run

          assert_equal [], report[:deliveries][:candidates]
          assert_equal [{event_id: "evt-edge", state: "delivered"}], report[:deliveries][:protected]
        end

        def test_non_delivered_records_are_protected
          %w[pending retryable failed].each_with_index do |state, index|
            save_record(record("evt-#{state}", state: state, updated_at: (CUTOFF_7D - index - 1).iso8601))
          end

          report = tidy(HerdrTestHelper::FakeExecutor.new).run

          assert_equal [], report[:deliveries][:candidates]
          assert_equal(
            %w[evt-failed evt-pending evt-retryable],
            report[:deliveries][:protected].map { |entry| entry[:event_id] }
          )
        end

        def test_delivered_without_valid_timestamp_is_preserved
          save_record(record("evt-noage", state: "delivered", updated_at: "not-a-time"))
          File.write(File.join(@dir, "evt-bad.json"), "{not json")

          report = tidy(HerdrTestHelper::FakeExecutor.new).run

          assert_equal [], report[:deliveries][:candidates]
          assert_equal(
            [
              {event_id: "evt-bad", reason: "unreadable"},
              {event_id: "evt-noage", reason: "invalid_updated_at"}
            ],
            report[:deliveries][:preserved]
          )
        end

        def test_delivery_entries_are_ordered_by_event_id
          save_record(record("evt-b", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))
          save_record(record("evt-a", state: "delivered", updated_at: (CUTOFF_7D - 120).iso8601))
          save_record(record("evt-c", state: "failed", updated_at: (CUTOFF_7D - 60).iso8601))

          report = tidy(HerdrTestHelper::FakeExecutor.new).run

          assert_equal %w[evt-a evt-b], report[:deliveries][:candidates].map { |e| e[:event_id] }
          assert_equal %w[evt-c], report[:deliveries][:protected].map { |e| e[:event_id] }
        end

        # --- apply: deliveries -------------------------------------------------------

        def test_apply_archives_eligible_delivered_record
          save_record(record("evt-old", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))

          report = tidy(HerdrTestHelper::FakeExecutor.new).run(apply: true)

          assert_equal(
            [{event_id: "evt-old", archive_path: File.join(@dir, "archive", "evt-old.json")}],
            report[:deliveries][:archived]
          )
          assert File.exist?(File.join(@dir, "archive", "evt-old.json"))
          refute File.exist?(File.join(@dir, "evt-old.json"))
          # the archived copy stays readable: delivery idempotency survives
          assert_equal "delivered", Molecules::DeliveryRecordStore.load(@dir, "evt-old").state
        end

        def test_apply_retention_override_changes_the_cutoff
          save_record(record("evt-3d", state: "delivered", updated_at: (NOW - 3 * 86_400).iso8601))

          report = tidy(HerdrTestHelper::FakeExecutor.new, retention_days: 2).run(apply: true)

          assert_equal 2, report[:retention_days]
          assert_equal %w[evt-3d], report[:deliveries][:archived].map { |e| e[:event_id] }
        end

        def test_apply_preserves_record_changed_after_discovery
          save_record(record("evt-old", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))
          changed = record("evt-old", state: "retryable", updated_at: NOW.iso8601)
          probe_calls = 0
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: pane_list_result(%w[w5:p2]),
            agent_get: proc {
              probe_calls += 1
              save_record(changed) if probe_calls == 2 # mutate during the apply phase
              agent_result("done")
            }
          })

          report = tidy(executor).run(apply: true)

          assert_equal [{id: "w5:p2"}], report[:panes][:closed]
          assert_equal [], report[:deliveries][:archived]
          assert_equal [{event_id: "evt-old", reason: "changed"}], report[:deliveries][:preserved]
          assert_equal "retryable", Molecules::DeliveryRecordStore.load(@dir, "evt-old").state
        end

        def test_apply_preserves_record_turned_unreadable_after_discovery_and_continues
          save_record(record("evt-a", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))
          save_record(record("evt-b", state: "delivered", updated_at: (CUTOFF_7D - 120).iso8601))
          probe_calls = 0
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: pane_list_result(%w[w5:p2]),
            agent_get: proc {
              probe_calls += 1
              File.write(File.join(@dir, "evt-a.json"), "{corrupted") if probe_calls == 2
              agent_result("done")
            }
          })

          report = tidy(executor).run(apply: true)

          assert_equal [{id: "w5:p2"}], report[:panes][:closed]
          assert_equal [{event_id: "evt-a", reason: "unreadable"}], report[:deliveries][:preserved]
          assert_equal ["evt-b"], report[:deliveries][:archived].map { |e| e[:event_id] }
        end

        def test_apply_preserves_non_object_json_turned_candidate_and_continues
          save_record(record("evt-a", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))
          save_record(record("evt-b", state: "delivered", updated_at: (CUTOFF_7D - 120).iso8601))
          probe_calls = 0
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: pane_list_result(%w[w5:p2]),
            agent_get: proc {
              probe_calls += 1
              File.write(File.join(@dir, "evt-a.json"), "null") if probe_calls == 2
              agent_result("done")
            }
          })

          report = tidy(executor).run(apply: true)

          assert_equal [{id: "w5:p2"}], report[:panes][:closed]
          assert_equal [{event_id: "evt-a", reason: "unreadable"}], report[:deliveries][:preserved]
          assert_equal ["evt-b"], report[:deliveries][:archived].map { |e| e[:event_id] }
        end

        def test_discovery_preserves_non_object_json_files
          File.write(File.join(@dir, "evt-null.json"), "null")
          File.write(File.join(@dir, "evt-arr.json"), "[1,2]")
          save_record(record("evt-ok", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))

          report = tidy(HerdrTestHelper::FakeExecutor.new).run

          assert_equal ["evt-ok"], report[:deliveries][:candidates].map { |e| e[:event_id] }
          assert_equal(
            [
              {event_id: "evt-arr", reason: "unreadable"},
              {event_id: "evt-null", reason: "unreadable"}
            ],
            report[:deliveries][:preserved]
          )
        end

        def test_apply_rechecks_eligibility_under_the_event_lock
          # The competing writer lands its state change while holding the
          # event lock, before tidy's reload runs: a reload outside the lock
          # would observe the stale delivered record and archive the
          # replacement — the assertions below pin the lock ordering
          save_record(record("evt-old", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))
          replaced = record("evt-old", state: "retryable", updated_at: NOW.iso8601)
          racing_store = Object.new
          racing_store.define_singleton_method(:list_records) { |*args| Molecules::DeliveryRecordStore.list_records(*args) }
          racing_store.define_singleton_method(:with_lock) do |dir, event_id, &block|
            Molecules::DeliveryRecordStore.with_lock(dir, event_id) do
              Molecules::DeliveryRecordStore.save(replaced, dir) # writer wins the lock first
              block.call
            end
          end
          racing_store.define_singleton_method(:load_revalidated) { |*args| Molecules::DeliveryRecordStore.load_revalidated(*args) }
          racing_store.define_singleton_method(:archive) { |*args| Molecules::DeliveryRecordStore.archive(*args) }

          report = Tidy.new(
            executor: HerdrTestHelper::FakeExecutor.new,
            record_store: racing_store, deliveries_dir: @dir,
            retention_days: Tidy::DEFAULT_RETENTION_DAYS, clock: @clock
          ).run(apply: true)

          assert_equal [], report[:deliveries][:archived]
          assert_equal [{event_id: "evt-old", reason: "changed"}], report[:deliveries][:preserved]
          assert_equal "retryable", Molecules::DeliveryRecordStore.load(@dir, "evt-old").state
        end

        def test_apply_tolerates_record_archived_concurrently_after_discovery
          save_record(record("evt-old", state: "delivered", updated_at: (CUTOFF_7D - 60).iso8601))
          probe_calls = 0
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: pane_list_result(%w[w5:p2]),
            agent_get: proc {
              probe_calls += 1
              Molecules::DeliveryRecordStore.archive(@dir, "evt-old") if probe_calls == 2
              agent_result("done")
            }
          })

          report = tidy(executor).run(apply: true)

          assert_equal(
            [{event_id: "evt-old", archive_path: File.join(@dir, "archive", "evt-old.json")}],
            report[:deliveries][:archived]
          )
        end

        def test_negative_retention_is_rejected
          error = assert_raises(ValidationError) do
            tidy(HerdrTestHelper::FakeExecutor.new, retention_days: -1)
          end

          assert_match(/non-negative integer/, error.message)
        end

        def test_non_integer_retention_is_rejected
          assert_raises(ValidationError) { tidy(HerdrTestHelper::FakeExecutor.new, retention_days: "week") }
        end
      end
    end
  end
end
