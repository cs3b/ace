# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Assign
    class AttemptStoreTest < AceAssignTestCase
      def build_attempt(attempt_id:, assignment_id: "8wrtest", scope: "010", project_id: "proj-1")
        binding = Models::AttemptBinding.new(
          attempt_id: attempt_id,
          assignment_id: assignment_id,
          scope: scope,
          project_id: project_id,
          actor: "mc",
          role: "coordinator",
          runtime: "local:test",
          base_head: "deadbeef00000000000000000000000000000000",
          task_id: "148",
          evidence_git_ref: "refs/ace/execution",
          created_at: Time.now.utc
        )
        Models::Attempt.new(binding: binding)
      end

      def test_save_and_reload_roundtrip_survives_new_store_instance
        with_temp_cache do |cache_dir|
          store = Molecules::AttemptStore.new(cache_base: cache_dir)
          attempt = build_attempt(attempt_id: "at1111")
          running = attempt.transition("running")

          store.save(running)

          reloaded = Molecules::AttemptStore.new(cache_base: cache_dir)
            .load(running.binding.assignment_id, running.attempt_id)

          assert_equal "running", reloaded.state
          assert_equal "at1111", reloaded.attempt_id
          assert_equal "010", reloaded.binding.scope
          assert_equal "proj-1", reloaded.binding.project_id
          assert_equal "148", reloaded.binding.task_id
          assert reloaded.managed?
          assert_equal "git", reloaded.recovery_mode
        end
      end

      def test_claim_and_active_lookup_keyed_by_normalized_scope
        with_temp_cache do |cache_dir|
          store = Molecules::AttemptStore.new(cache_base: cache_dir)
          attempt = build_attempt(attempt_id: "at2222")
          store.save(attempt)

          store.with_lock(attempt.binding.assignment_id) do
            store.claim(attempt.binding.assignment_id, "010", attempt)
          end

          found = store.active(attempt.binding.assignment_id, " 010 ")
          assert_equal "at2222", found.attempt_id
          assert_nil store.active(attempt.binding.assignment_id, "020")
        end
      end

      def test_release_clears_pointer_only_for_owning_attempt
        with_temp_cache do |cache_dir|
          store = Molecules::AttemptStore.new(cache_base: cache_dir)
          attempt = build_attempt(attempt_id: "at3333")
          store.save(attempt)

          store.with_lock(attempt.binding.assignment_id) do
            store.claim(attempt.binding.assignment_id, "010", attempt)
            store.release(attempt.binding.assignment_id, "010", "at9999")
          end
          refute_nil store.active(attempt.binding.assignment_id, "010")

          store.with_lock(attempt.binding.assignment_id) do
            store.release(attempt.binding.assignment_id, "010", "at3333")
          end
          assert_nil store.active(attempt.binding.assignment_id, "010")
        end
      end

      def test_concurrent_claims_cannot_create_competing_active_owners
        with_temp_cache do |cache_dir|
          store = Molecules::AttemptStore.new(cache_base: cache_dir)
          winners = []
          assignment_id = "8wrconc"

          threads = Array.new(8) do |index|
            Thread.new do
              attempt = build_attempt(attempt_id: "atc#{index.to_s(36).rjust(4, "0")}", assignment_id: assignment_id)
              store.save(attempt)
              store.with_lock(assignment_id) do
                if store.active(assignment_id, "010").nil?
                  store.claim(assignment_id, "010", attempt)
                  winners << attempt.attempt_id
                end
              end
            end
          end
          threads.each(&:join)

          assert_equal 1, winners.size
          assert_equal winners.first, store.active(assignment_id, "010").attempt_id
        end
      end

      def test_list_returns_records_newest_first
        with_temp_cache do |cache_dir|
          store = Molecules::AttemptStore.new(cache_base: cache_dir)
          base = Time.utc(2026, 9, 28, 12, 0, 0)
          older = build_attempt(attempt_id: "atold1")
          newer = build_attempt(attempt_id: "atnew1")
          older = Models::Attempt.new(binding: older.binding, state: "succeeded", updated_at: base)
          newer = Models::Attempt.new(binding: newer.binding, state: "running", updated_at: base + 3600)

          store.save(older)
          store.save(newer)

          listed = store.list("8wrtest")
          assert_equal ["atnew1", "atold1"], listed.map(&:attempt_id)
        end
      end

      def test_list_breaks_updated_at_ties_deterministically_by_attempt_id
        with_temp_cache do |cache_dir|
          store = Molecules::AttemptStore.new(cache_base: cache_dir)
          base = Time.utc(2026, 9, 28, 12, 0, 0)
          first = build_attempt(attempt_id: "attie01")
          second = build_attempt(attempt_id: "attie02")
          first = Models::Attempt.new(binding: first.binding, state: "running", updated_at: base)
          second = Models::Attempt.new(binding: second.binding, state: "running", updated_at: base)

          store.save(first)
          store.save(second)

          listed = store.list("8wrtest")
          assert_equal ["attie02", "attie01"], listed.map(&:attempt_id)
        end
      end

      def test_corrupt_record_loads_as_nil
        with_temp_cache do |cache_dir|
          store = Molecules::AttemptStore.new(cache_base: cache_dir)
          attempt = build_attempt(attempt_id: "atbad1")
          store.save(attempt)
          File.write(File.join(cache_dir, "8wrtest", "attempts", "records", "atbad1.json"), "{broken")

          assert_nil store.load("8wrtest", "atbad1")
          assert_empty store.list("8wrtest")
        end
      end

      def test_taskless_attempt_reports_local_only_recovery
        with_temp_cache do |cache_dir|
          store = Molecules::AttemptStore.new(cache_base: cache_dir)
          binding = Models::AttemptBinding.new(
            attempt_id: "atless1",
            assignment_id: "8wrtest",
            scope: "010",
            project_id: "proj-1",
            actor: "mc",
            role: "coordinator",
            runtime: "local:test",
            base_head: "deadbeef",
            task_id: nil,
            created_at: Time.now.utc
          )
          attempt = Models::Attempt.new(binding: binding)
          store.save(attempt)

          reloaded = store.load("8wrtest", "atless1")
          refute reloaded.managed?
          assert_equal "local_only", reloaded.recovery_mode
        end
      end
    end
  end
end
