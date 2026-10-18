# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Molecules
      class TaskProbeTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-task")
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def test_resolves_real_task_folder_under_project_root
          CoworkerFixture.build_task(@dir, id: "8xh.t.aaa")
          probe = TaskProbe.new(project_root: @dir)
          expected = File.join(@dir, ".ace-tasks", "8xh.t.aaa-fixture-task")
          assert_equal expected, probe.resolve!("8xh.t.aaa")
        end

        def test_unresolvable_task_is_a_specific_error
          probe = TaskProbe.new(project_root: @dir)
          error = assert_raises(Error) { probe.resolve!("nope.t.xxx") }
          assert_equal "task 'nope.t.xxx' not found in this worktree", error.message
        end

        def test_injected_manager_is_used
          fake = Object.new
          def fake.show(ref) = nil
          probe = TaskProbe.new(project_root: @dir, task_manager: fake)
          assert_raises(Error) { probe.resolve!("anything") }
        end
      end
    end
  end
end
