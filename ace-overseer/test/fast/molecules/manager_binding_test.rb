# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/overseer/molecules/manager_binding"
require "tmpdir"

class ManagerBindingTest < AceOverseerTestCase
  def setup
    super
    @root = Dir.mktmpdir("manager-binding")
    system("git", "init", "-q", @root, exception: true)
    File.write(File.join(@root, ".gitignore"), "/tasks/_overseer/\n")
    @tasks = Ace::Task::Organisms::TaskManager.new(root_dir: File.join(@root, "tasks"))
    @task = @tasks.create("Executable", status: "pending")
    @manager = @tasks.create("Manager", status: "in-progress")
    @tasks.update(@manager.id, move_to: "_overseer")
    @binding = Ace::Overseer::Molecules::ManagerBinding.new(task_manager: @tasks)
    @sequence = [{"role" => "worker", "assignment" => "a1"}, {"role" => "reviewer", "assignment" => "a2"}]
  end

  def teardown
    FileUtils.rm_rf(@root)
    super
  end

  def prepare(sequence = @sequence)
    @binding.prepare(manager_ref: @manager.id, task: @task, sequence: sequence,
      worktree_path: File.join(@root, ".ace-wt/task"), project_root: @root)
  end

  def test_retry_keeps_children_assignments_and_execution_references
    first = prepare
    @binding.record_execution(manager_ref: @manager.id, assignment: "a1",
      execution: {"agent" => "coworker-a1", "terminal_id" => "term123"})
    assert_equal first, prepare
    manager = @tasks.show(@manager.id)
    assert_equal @task.id, manager.metadata["project_task"]
    assert_equal 2, manager.subtasks.size
    assert_equal "term123", manager.subtasks.first.metadata["terminal"]
    assert_equal [manager.subtasks.first.id], manager.subtasks.last.dependencies
  end

  def test_recovers_child_created_before_reference_update
    child = @tasks.create_subtask(@manager.id, "worker", tags: ["overseer-role:worker"])
    rows = prepare
    assert_equal child.id, rows.first["step"]
    assert_equal 2, @tasks.show(@manager.id).subtasks.size
  end

  def test_conflicting_sequence_does_not_create_more_children
    prepare
    assert_raises(Ace::Overseer::Error) { prepare(@sequence.reverse) }
    assert_equal 2, @tasks.show(@manager.id).subtasks.size
  end

  def test_conflicting_manager_is_rejected
    prepare
    other = @tasks.create("Other manager", status: "in-progress")
    @tasks.update(other.id, move_to: "_overseer")
    error = assert_raises(Ace::Overseer::Error) do
      @binding.validate!(manager_ref: other.id, task: @task, roles: %w[worker reviewer])
    end
    assert_includes error.message, "already belongs"
  end

  def test_late_role_conflict_does_not_create_an_earlier_child
    2.times do
      child = @tasks.create_subtask(@manager.id, "review")
      @tasks.update(child.id, set: {"role" => "reviewer"})
    end
    original = @tasks.show(@manager.id).subtasks.map(&:id)
    assert_raises(Ace::Overseer::Error) { prepare }
    assert_equal original, @tasks.show(@manager.id).subtasks.map(&:id)
    assert_nil @tasks.show(@manager.id).metadata["project_task"]
  end

  def test_a_child_matching_two_roles_is_refused_before_binding
    child = @tasks.create_subtask(@manager.id, "mixed", tags: ["overseer-role:reviewer"])
    @tasks.update(child.id, set: {"role" => "worker"})
    assert_raises(Ace::Overseer::Error) { prepare }
    assert_nil @tasks.show(child.id).metadata["assignment"]
    assert_nil @tasks.show(@manager.id).metadata["project_task"]
  end

  def test_bootstrap_keeps_confirm_start_required_after_verification
    prepare([{"role" => "bootstrap-worker", "assignment" => "b1"},
      {"role" => "bootstrap-verifier", "assignment" => "b2"}])
    manager = @tasks.show(@manager.id)
    assert_equal %w[bootstrap-worker bootstrap-verifier confirm-start], manager.subtasks.map { |step| step.metadata["role"] }
    assert_equal [manager.subtasks[1].id], manager.subtasks.last.dependencies
    assert_equal "pending", manager.subtasks.last.status
  end

  def test_retry_preserves_external_dependency_and_refuses_dispatch
    prepare
    external = @tasks.create("External gate", status: "pending")
    child = @tasks.show(@manager.id).subtasks.first
    @tasks.update(child.id, set: {"dependencies" => [external.id]})
    prepare
    assert_equal [external.id], @tasks.show(child.id).dependencies
    assert_raises(Ace::Overseer::Error) { @binding.ready!(manager_ref: @manager.id, assignment: "a1") }
  end

  def test_failed_reference_write_is_not_success
    prepare
    @tasks.stub(:update, nil) do
      assert_raises(Ace::Overseer::Error) do
        @binding.record_execution(manager_ref: @manager.id, assignment: "a1", execution: {"terminal_id" => "term"})
      end
    end
  end

  def test_public_manager_is_rejected_before_any_child_is_created
    error = assert_raises(Ace::Overseer::Error) do
      @binding.validate!(manager_ref: @task.id, task: @task, roles: ["worker"])
    end
    assert_includes error.message, "Git-ignored"
    assert_empty @tasks.show(@task.id).subtasks
  end
end
