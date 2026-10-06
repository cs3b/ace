# frozen_string_literal: true

require "test_helper"
require "ace/task/molecules/task_family_completion"

class TaskFamilyCompletionTest < AceTaskTestCase
  def test_empty_child_set_does_not_trigger_completion_but_allows_explicit_move
    with_tasks_dir do |root|
      manager = Ace::Task::Organisms::TaskManager.new(root_dir: root)
      parent = manager.create("Standalone")
      policy = Ace::Task::Molecules::TaskFamilyCompletion.new(root)
      refute policy.complete?(parent.path, id: parent.id)
      assert policy.descendants_terminal?(parent.path, id: parent.id)
      assert_equal "_archive", manager.update(parent.id, move_to: "archive").special_folder
    end
  end

  def test_non_task_evidence_is_excluded_and_nested_task_status_is_checked
    with_tasks_dir do |root|
      manager = Ace::Task::Organisms::TaskManager.new(root_dir: root)
      parent = manager.create("Parent")
      child = manager.create_subtask(parent.id, "Child", status: "cancelled")
      grandchild = manager.create_subtask(child.id, "Grandchild", status: "blocked")
      evidence = File.join(parent.path, "evidence")
      FileUtils.mkdir_p(evidence)
      File.write(File.join(evidence, "historical.s.md"), "---\nstatus: pending\n---\n")
      policy = Ace::Task::Molecules::TaskFamilyCompletion.new(root)
      refute policy.complete?(parent.path, id: parent.id)
      Ace::Support::Items::Molecules::FieldUpdater.update(grandchild.file_path, set: {"status" => "done"})
      assert policy.complete?(parent.path, id: parent.id)
      assert_equal "pending", manager.show(parent.id).status
    end
  end
end
