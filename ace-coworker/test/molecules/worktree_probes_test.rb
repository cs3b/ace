# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Molecules
      class WorktreeProvisionProbeTest < AceCoworkerTestCase
        FakeManager = Struct.new(:switch_result, :create_results, :prune_calls) do
          def initialize(switch_result:, create_results:)
            super(switch_result, create_results, [])
          end

          def switch(_ref)
            switch_result
          end

          def create_task(ref, options = {})
            return {success: true, would_create: {worktree_path: "/proj/.ace-wt/t.fixture", branch: "b"}} if options[:dry_run]

            create_results.shift || {success: true, worktree_path: "/proj/.ace-wt/t.fixture", branch: "b"}
          end

          def prune
            prune_calls << true
            {success: true}
          end
        end

        def probe(switch_result:, create_results:)
          WorktreeProvisionProbe.new(project_root: "/proj",
            manager: FakeManager.new(switch_result: switch_result, create_results: create_results))
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

        def test_stale_directory_prunes_and_recovers
          with_directory(true) do |path|
            # After prune, the directory exists again (git recreates it).
            instance = probe(
              switch_result: {success: true, worktree_path: path, branch: "b", task_id: "8xg.t.aaa"},
              create_results: [])
            # Simulate stale: switch resolves, directory missing at decision time.
            result = nil
            Dir.mktmpdir("coworker-stale") do |stale_dir|
              missing = File.join(stale_dir, "gone")
              instance.instance_variable_get(:@manager).switch_result[:worktree_path] = missing
              result = instance.ensure_prepared(task_ref: "8xg.t.aaa", expected_task_id: "8xg.t.aaa")
            end

            assert_equal :recovered, result[:disposition]
            assert_equal 1, instance.instance_variable_get(:@manager).prune_calls.length
          end
        end

        def test_stale_dry_run_reports_would_recover_without_prune
          Dir.mktmpdir("coworker-stale") do |stale_dir|
            missing = File.join(stale_dir, "gone")
            instance = probe(
              switch_result: {success: true, worktree_path: missing, branch: "b", task_id: "8xg.t.aaa"},
              create_results: [])
            result = instance.ensure_prepared(task_ref: "8xg.t.aaa",
              expected_task_id: "8xg.t.aaa", dry_run: true)

            assert_equal :would_recover, result[:disposition]
            assert_empty instance.instance_variable_get(:@manager).prune_calls
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
