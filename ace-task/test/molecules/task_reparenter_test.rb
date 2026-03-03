# frozen_string_literal: true

require "test_helper"
require "ace/task/molecules/task_reparenter"

class TaskReparenterTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-reparenter-test")
    @tasks_dir = File.join(@tmpdir, ".ace-tasks")
    FileUtils.mkdir_p(@tasks_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # --- promote to standalone ---

  def test_promote_subtask_to_standalone
    parent_dir = create_task_dir("8pp.t.q7w", "parent-task")
    create_spec(parent_dir, "8pp.t.q7w-parent-task", status: "in-progress")

    subtask_dir = File.join(parent_dir, "8pp.t.q7w.a-child-task")
    FileUtils.mkdir_p(subtask_dir)
    create_spec(subtask_dir, "8pp.t.q7w.a-child-task", id: "8pp.t.q7w.a", status: "pending", parent: "8pp.t.q7w")

    subtask = load_task(subtask_dir, "8pp.t.q7w.a")

    reparenter = Ace::Task::Molecules::TaskReparenter.new(root_dir: @tasks_dir)
    result = reparenter.reparent(subtask, target: "none", resolve_ref: ->(_) { nil })

    # Should now be at root level with base ID
    assert_equal "8pp.t.q7w", result.id
    assert Dir.exist?(File.join(@tasks_dir, "8pp.t.q7w-child-task"))
    assert_nil result.parent_id

    # Verify frontmatter
    content = File.read(result.file_path)
    refute_match(/parent:/, content)
  end

  def test_promote_raises_for_standalone_task
    task_dir = create_task_dir("8pp.t.q7w", "standalone")
    create_spec(task_dir, "8pp.t.q7w-standalone", status: "pending")

    task = load_task(task_dir, "8pp.t.q7w")

    reparenter = Ace::Task::Molecules::TaskReparenter.new(root_dir: @tasks_dir)
    assert_raises(ArgumentError) do
      reparenter.reparent(task, target: "none", resolve_ref: ->(_) { nil })
    end
  end

  # --- convert to orchestrator ---

  def test_convert_to_orchestrator
    task_dir = create_task_dir("8pp.t.q7w", "my-task")
    create_spec(task_dir, "8pp.t.q7w-my-task", status: "pending")

    task = load_task(task_dir, "8pp.t.q7w")

    reparenter = Ace::Task::Molecules::TaskReparenter.new(root_dir: @tasks_dir)
    result = reparenter.reparent(task, target: "self", resolve_ref: ->(_) { nil })

    # Should now have a subtask dir
    assert_equal "8pp.t.q7w", result.id
    assert result.has_subtasks?, "Expected task to have subtasks after convert to orchestrator"

    # Orchestrator spec should exist
    orch_spec = File.join(task_dir, "8pp.t.q7w-my-task.s.md")
    assert File.exist?(orch_spec), "Orchestrator spec should exist"

    # Subtask spec should exist
    subtask_dir = File.join(task_dir, "8pp.t.q7w.a-my-task")
    assert Dir.exist?(subtask_dir), "Subtask directory should exist"

    subtask_spec = File.join(subtask_dir, "8pp.t.q7w.a-my-task.s.md")
    assert File.exist?(subtask_spec), "Subtask spec should exist"

    subtask_content = File.read(subtask_spec)
    assert_match(/id: 8pp\.t\.q7w\.a/, subtask_content)
    assert_match(/parent: 8pp\.t\.q7w/, subtask_content)
  end

  def test_convert_raises_for_subtask
    parent_dir = create_task_dir("8pp.t.q7w", "parent")
    create_spec(parent_dir, "8pp.t.q7w-parent", status: "pending")

    subtask_dir = File.join(parent_dir, "8pp.t.q7w.a-child")
    FileUtils.mkdir_p(subtask_dir)
    create_spec(subtask_dir, "8pp.t.q7w.a-child", id: "8pp.t.q7w.a", parent: "8pp.t.q7w")

    subtask = load_task(subtask_dir, "8pp.t.q7w.a")

    reparenter = Ace::Task::Molecules::TaskReparenter.new(root_dir: @tasks_dir)
    assert_raises(ArgumentError) do
      reparenter.reparent(subtask, target: "self", resolve_ref: ->(_) { nil })
    end
  end

  # --- demote to subtask ---

  def test_demote_to_subtask
    # Create parent task
    parent_dir = create_task_dir("8pp.t.abc", "parent-task")
    create_spec(parent_dir, "8pp.t.abc-parent-task", id: "8pp.t.abc", status: "in-progress")

    # Create standalone task to demote
    task_dir = create_task_dir("8pp.t.q7w", "demotable-task")
    create_spec(task_dir, "8pp.t.q7w-demotable-task", status: "pending")

    parent_task = load_task(parent_dir, "8pp.t.abc")
    task = load_task(task_dir, "8pp.t.q7w")

    resolve_fn = ->(ref) { ref == "abc" ? parent_task : nil }

    reparenter = Ace::Task::Molecules::TaskReparenter.new(root_dir: @tasks_dir)
    result = reparenter.reparent(task, target: "abc", resolve_ref: resolve_fn)

    # Should now be inside parent dir with subtask ID
    assert_equal "8pp.t.abc.0", result.id
    assert_equal "8pp.t.abc", result.parent_id
    assert result.path.start_with?(parent_dir)

    # Old dir should not exist
    refute Dir.exist?(task_dir), "Original standalone dir should be moved"
  end

  def test_demote_raises_for_missing_parent
    task_dir = create_task_dir("8pp.t.q7w", "task")
    create_spec(task_dir, "8pp.t.q7w-task", status: "pending")

    task = load_task(task_dir, "8pp.t.q7w")

    reparenter = Ace::Task::Molecules::TaskReparenter.new(root_dir: @tasks_dir)
    assert_raises(ArgumentError) do
      reparenter.reparent(task, target: "zzz", resolve_ref: ->(_) { nil })
    end
  end

  def test_demote_raises_for_self_reference
    task_dir = create_task_dir("8pp.t.q7w", "task")
    create_spec(task_dir, "8pp.t.q7w-task", status: "pending")

    task = load_task(task_dir, "8pp.t.q7w")

    reparenter = Ace::Task::Molecules::TaskReparenter.new(root_dir: @tasks_dir)
    assert_raises(ArgumentError) do
      reparenter.reparent(task, target: "q7w", resolve_ref: ->(_) { task })
    end
  end

  private

  def create_task_dir(id, slug)
    dir = File.join(@tasks_dir, "#{id}-#{slug}")
    FileUtils.mkdir_p(dir)
    dir
  end

  def create_spec(dir, folder_name, id: nil, status: "pending", parent: nil)
    spec_id = id || folder_name.split("-").first
    file = File.join(dir, "#{folder_name}.s.md")
    fm_lines = ["---", "id: #{spec_id}", "status: #{status}"]
    fm_lines << "parent: #{parent}" if parent
    fm_lines << "priority: medium"
    fm_lines << "tags: []"
    fm_lines << "---"
    slug = folder_name.sub(/^[^-]+-/, "")
    title = slug.split("-").map(&:capitalize).join(" ")
    File.write(file, fm_lines.join("\n") + "\n\n# #{title}\n")
    file
  end

  def load_task(dir, id)
    loader = Ace::Task::Molecules::TaskLoader.new
    loader.load(dir, id: id)
  end
end
