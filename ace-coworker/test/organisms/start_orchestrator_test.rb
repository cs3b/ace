# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Organisms
      class StartOrchestratorTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-start")
          CoworkerFixture.build_task(@dir, id: "8xh.t.aaa")
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "8xh.t.aaa")
          CoworkerFixture.build_config(@dir, assignment: "abc123", task: "8xh.t.aaa")
          @probe_runner = ->(_argv, _cwd) {
            [CoworkerFixture.status_json(state: "running", steps: [{number: 1, name: "step one", status: "pending"}]),
              "", CoworkerFixture::SuccessStatus.ok]
          }
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def orchestrator
          StartOrchestrator.new(
            project_root: @dir,
            assignment_probe: Molecules::AssignmentProbe.new(project_root: @dir, runner: @probe_runner)
          )
        end

        def test_start_renders_brief_with_all_context
          brief = orchestrator.call
          assert_equal "worker", brief.config.role
          assert_equal File.join(@dir, "roles", "worker.md"), brief.instructions_source
          assert_equal File.join(@dir, ".ace-tasks", "8xh.t.aaa-fixture-task"), brief.task_path
          assert_equal "abc123", brief.config.assignment
          assert_equal "running", brief.assignment_snapshot.state
          assert_equal "overseer@lab", brief.config.overseer
          assert_equal "report", brief.config.on_failure

          table = Atoms::BriefFormatter.format_table(brief)
          assert_includes table, "role:              worker"
          assert_includes table, "--assignment abc123"
          assert_includes table, "overseer@lab"
        end

        def test_start_writes_nothing
          before = snapshot_tree(@dir)
          orchestrator.call
          assert_equal before, snapshot_tree(@dir)
        end

        def test_missing_config_is_not_ready_error
          File.delete(File.join(@dir, ".ace-local", "coworker", "config.yml"))
          error = assert_raises(Error) { orchestrator.call }
          assert_equal "not ready: .ace-local/coworker/config.yml not found", error.message
        end

        def test_task_not_in_worktree_is_specific_error
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          File.write(path, File.read(path).gsub("8xh.t.aaa", "nope.t.xxx"))
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "nope.t.xxx")
          error = assert_raises(Error) { orchestrator.call }
          assert_equal "task 'nope.t.xxx' not found in this worktree", error.message
        end

        def test_assignment_task_mismatch_is_specific_error
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          File.write(path, File.read(path).gsub("8xh.t.aaa", "oth.t.err"))
          CoworkerFixture.build_task(@dir, id: "oth.t.err")
          error = assert_raises(Error) { orchestrator.call }
          assert_equal "assignment 'abc123' belongs to task '8xh.t.aaa', not 'oth.t.err'", error.message
        end

        def test_unknown_assignment_is_specific_error_without_substitute
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          File.write(path, File.read(path).gsub("abc123", "nope99"))
          error = assert_raises(Error) { orchestrator.call }
          assert_equal "assignment 'nope99' not found under .ace-local/assign/nope99", error.message
          refute Dir.exist?(File.join(@dir, ".ace-local", "assign", "nope99"))
        end

        def test_unresolvable_instructions_are_specific
          path = File.join(@dir, ".ace-local", "coworker", "config.yml")
          File.write(path, File.read(path).gsub("roles/worker.md", "roles/ghost.md"))
          error = assert_raises(Error) { orchestrator.call }
          assert_equal "instruction file 'roles/ghost.md' not found in this worktree", error.message
        end

        private

        def snapshot_tree(root)
          Dir.glob(File.join(root, "**", "*")).select { |f| File.file?(f) }.sort.map { |f| [f, File.mtime(f)] }
        end
      end
    end
  end
end
