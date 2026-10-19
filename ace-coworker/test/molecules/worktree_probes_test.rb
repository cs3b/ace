# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Molecules
      class WorktreeProvisionProbeTest < AceCoworkerTestCase
        FakeWorktree = Struct.new(:path, :branch, :task_id)

        # Mirrors the real WorktreeManager contract: switch NEVER succeeds
        # for a worktree whose directory is missing (it fails instead), and
        # list_all exposes the association inventory for stale detection.
        FakeManager = Struct.new(:switch_result, :create_results, :prune_calls, :worktrees,
          :reattach_result, :prune_result) do
          def initialize(switch_result:, create_results:, worktrees: [], reattach_result: nil,
            prune_result: nil)
            super(switch_result, create_results, [], worktrees, reattach_result, prune_result)
          end

          def switch(_ref)
            switch_result
          end

          def list_all
            {success: true, worktrees: worktrees}
          end

          def create_task(ref, options = {})
            return {success: true, would_create: {worktree_path: "/proj/.ace-wt/t.fixture", branch: "b"}} if options[:dry_run]

            create_results.shift || {success: true, worktree_path: "/proj/.ace-wt/t.fixture", branch: "b"}
          end

          def prune
            prune_calls << true
            prune_result || {success: true}
          end

          attr_reader :reattach_calls

          def create(branch, options = {})
            (@reattach_calls ||= []) << [branch, options]
            reattach_result || {success: true, worktree_path: options[:path], branch: branch}
          end
        end

        def probe(switch_result:, create_results:, worktrees: [])
          WorktreeProvisionProbe.new(project_root: "/proj",
            manager: FakeManager.new(switch_result: switch_result,
              create_results: create_results, worktrees: worktrees))
        end

        def with_directory(existing)
          Dir.mktmpdir("coworker-provision") do |dir|
            path = File.join(dir, "wt")
            FileUtils.mkdir(path) if existing
            yield path
          end
        end

        def test_reuse_path_performs_no_writes
          with_directory(true) do |path|
            instance = probe(
              switch_result: {success: true, worktree_path: path, branch: "b", task_id: "8xg.t.aaa"},
              create_results: [])
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :reuse, result[:disposition]
            assert_empty instance.instance_variable_get(:@manager).prune_calls
          end
        end

        def test_foreign_task_switch_is_conflict_mismatch
          with_directory(true) do |path|
            result = probe(
              switch_result: {success: true, worktree_path: path, branch: "b", task_id: "8xg.t.bbb"},
              create_results: []
            ).ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :conflict_mismatch, result[:disposition]
            assert_includes result[:reason], "8xg.t.bbb"
          end
        end

        def test_miss_creates_worktree
          with_directory(true) do |path|
            created = {success: true, worktree_path: path, branch: "b", message: "created"}
            result = probe(
              switch_result: {success: false, error: "Worktree not found"},
              create_results: [created]
            ).ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :created, result[:disposition]
          end
        end

        def test_miss_dry_run_would_create_without_touching_manager
          with_directory(false) do |_path|
            instance = probe(
              switch_result: {success: false, error: "Worktree not found"},
              create_results: [])
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa",
              expected_task_id: "8xg.t.aaa", dry_run: true)

            assert_equal :would_create, result[:disposition]
            assert_empty instance.instance_variable_get(:@manager).prune_calls
          end
        end

        def test_stale_registration_prunes_and_recovers
          Dir.mktmpdir("coworker-stale") do |dir|
            missing = File.join(dir, "gone")
            recreated = {success: true, worktree_path: missing, branch: "8xg-aaa-branch",
                         message: "recreated"}
            instance = probe(
              switch_result: {success: false,
                error: "Worktree directory does not exist: #{missing}"},
              create_results: [recreated],
              worktrees: [FakeWorktree.new(missing, "8xg-aaa-branch", "aaa")])
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :recovered, result[:disposition]
            assert_equal 1, instance.instance_variable_get(:@manager).prune_calls.length
          end
        end

        def test_stale_registration_dry_run_reports_would_recover_without_prune
          Dir.mktmpdir("coworker-stale") do |dir|
            missing = File.join(dir, "gone")
            instance = probe(
              switch_result: {success: false,
                error: "Worktree directory does not exist: #{missing}"},
              create_results: [],
              worktrees: [FakeWorktree.new(missing, "8xg-aaa-branch", "aaa")])
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa",
              expected_task_id: "8xg.t.aaa", dry_run: true)

            assert_equal :would_recover, result[:disposition]
            assert_empty instance.instance_variable_get(:@manager).prune_calls
          end
        end

        def test_stale_recovery_reattaches_surviving_branch_when_create_task_trips_on_it
          # Recreating mints a fresh branch, but the stale worktree's branch
          # survives its directory; recovery must reattach it.
          Dir.mktmpdir("coworker-stale") do |dir|
            missing = File.join(dir, "gone")
            instance = probe(
              switch_result: {success: false,
                error: "Worktree directory does not exist: #{missing}"},
              create_results: [{success: false,
                error: "Failed to create worktree: a branch named 'x' already exists"}],
              worktrees: [FakeWorktree.new(missing, "8xg-aaa-branch", "aaa")])
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :recovered, result[:disposition]
            manager = instance.instance_variable_get(:@manager)
            assert_equal [["8xg-aaa-branch", {path: missing}]], manager.reattach_calls
          end
        end

        def test_registration_with_existing_directory_is_not_stale
          # A failed switch whose registration still points at an existing
          # directory (e.g. unusable worktree) is not stale metadata; the
          # idempotent create resolves it without pruning.
          with_directory(true) do |path|
            instance = probe(
              switch_result: {success: false, error: "Worktree is not usable: #{path}"},
              create_results: [{success: true, existing: true, worktree_path: path, branch: "b"}],
              worktrees: [FakeWorktree.new(path, "b", "aaa")])
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :reuse, result[:disposition]
            assert_empty instance.instance_variable_get(:@manager).prune_calls
          end
        end

        def test_foreign_registration_is_ignored_for_stale_detection
          # Stale recovery only prunes metadata registered to THIS task.
          Dir.mktmpdir("coworker-stale") do |dir|
            missing = File.join(dir, "gone")
            created = File.join(dir, "fresh")
            FileUtils.mkdir(created)
            result = probe(
              switch_result: {success: false, error: "Worktree not found"},
              create_results: [{success: true, worktree_path: created,
                                branch: "b", message: "created"}],
              worktrees: [FakeWorktree.new(missing, "8xg-bbb-branch", "bbb")]
            ).ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :created, result[:disposition]
          end
        end

        def test_create_failure_with_occupied_expected_directory_is_conflict
          Dir.mktmpdir("coworker-occupied") do |dir|
            occupied = File.join(dir, "wt")
            FileUtils.mkdir(occupied)
            instance = WorktreeProvisionProbe.new(project_root: "/proj",
              manager: FakeManager.new(
                switch_result: {success: false, error: "Worktree not found"},
                create_results: [{success: false, error: "target path already exists"}]))
            # The dry-run preview points at the occupied directory.
            def instance.expected_directory_exists?(_ref)
              true
            end

            result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :conflict_mismatch, result[:disposition]
          end
        end

        def test_create_with_existing_registration_but_missing_directory_prunes_and_recovers
          # create_with_verification's recovery sub-path: the idempotent
          # create reports existing:true, but the directory is gone.
          Dir.mktmpdir("coworker-recovery") do |dir|
            missing = File.join(dir, "gone")
            instance = probe(
              switch_result: {success: false, error: "Worktree not found"},
              create_results: [
                {success: true, existing: true, worktree_path: missing, branch: "8xg-aaa-branch"},
                {success: true, worktree_path: missing, branch: "8xg-aaa-branch", message: "recreated"}
              ])
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :recovered, result[:disposition]
            manager = instance.instance_variable_get(:@manager)
            assert_equal 1, manager.prune_calls.length
            assert_nil manager.reattach_calls
          end
        end

        def test_recovery_retry_failure_with_occupied_directory_is_conflict
          # After pruning, a foreign occupant of the expected directory is
          # a mismatched_worktree conflict — same rule as the miss path.
          Dir.mktmpdir("coworker-occupied-recovery") do |dir|
            occupied = File.join(dir, "wt")
            FileUtils.mkdir(occupied)
            instance = probe(
              switch_result: {success: false, error: "Worktree not found"},
              create_results: [
                {success: true, existing: true, worktree_path: occupied, branch: "b"},
                {success: false, error: "target path already exists"}
              ])
            # The registration's directory is missing at the verification
            # check, then occupied after prune — the foreign-occupant case.
            checks = 0
            instance.define_singleton_method(:path_exists?) { |_path| (checks += 1) > 1 }
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :conflict_mismatch, result[:disposition]
            manager = instance.instance_variable_get(:@manager)
            assert_equal 1, manager.prune_calls.length
            assert_nil manager.reattach_calls
          end
        end

        def test_recovery_prune_failure_is_error_without_create
          Dir.mktmpdir("coworker-prune-fail") do |dir|
            missing = File.join(dir, "gone")
            instance = WorktreeProvisionProbe.new(project_root: "/proj",
              manager: FakeManager.new(
                switch_result: {success: false, error: "Worktree not found"},
                create_results: [
                  {success: true, existing: true, worktree_path: missing, branch: "b"}
                ],
                prune_result: {success: false, error: "prune exploded"}))
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

            assert_equal :error, result[:disposition]
            assert_includes result[:reason], "prune exploded"
            manager = instance.instance_variable_get(:@manager)
            assert_equal 1, manager.prune_calls.length
            assert_empty manager.create_results # retry create never ran
          end
        end

        def test_create_failure_without_occupant_is_error
          instance = probe(
            switch_result: {success: false, error: "Worktree not found"},
            create_results: [{success: false, error: "boom"}])
          def instance.expected_directory_exists?(_ref)
            false
          end

          result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")

          assert_equal :error, result[:disposition]
          assert_equal "boom", result[:reason]
        end
      end
    end
  end
end
