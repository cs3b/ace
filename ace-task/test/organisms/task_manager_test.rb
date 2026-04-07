# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TaskManagerTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-manager-test")
    @manager = Ace::Task::Organisms::TaskManager.new(root_dir: @tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # --- create ---

  def test_create_returns_task_with_full_metadata
    task = @manager.create("Build API endpoint", priority: "high", tags: ["api"])

    assert task.id.match?(/^[0-9a-z]{3}\.t\.[0-9a-z]{3}$/)
    assert_equal "Build API endpoint", task.title
    assert_equal "pending", task.status
    assert_equal "high", task.priority
    assert_equal ["api"], task.tags
    assert File.exist?(task.file_path)
  end

  def test_create_with_custom_status
    task = @manager.create("Urgent fix", status: "in-progress")

    assert_equal "in-progress", task.status
  end

  def test_create_with_dependencies
    task = @manager.create("Dependent task", dependencies: ["8pp.t.abc"])

    assert_equal ["8pp.t.abc"], task.dependencies
  end

  def test_create_raises_for_empty_title
    assert_raises(ArgumentError) { @manager.create("") }
    assert_raises(ArgumentError) { @manager.create(nil) }
  end

  # --- show ---

  def test_show_by_full_id
    created = @manager.create("Showable task")

    found = @manager.show(created.id)

    assert_equal created.id, found.id
    assert_equal "Showable task", found.title
  end

  def test_show_by_shortcut
    created = @manager.create("Shortcut task")
    suffix = created.id[-3..]

    found = @manager.show(suffix)

    assert_equal created.id, found.id
  end

  def test_show_returns_nil_for_unknown_ref
    result = @manager.show("zzz")

    assert_nil result
  end

  def test_show_loads_subtasks
    parent = @manager.create("Parent task")
    @manager.create_subtask(parent.id, "Subtask one")

    loaded = @manager.show(parent.id)

    assert loaded.has_subtasks?
    assert_equal 1, loaded.subtasks.length
    assert_equal "Subtask one", loaded.subtasks.first.title
  end

  # --- list ---

  def test_list_returns_all_tasks
    @manager.create("Task A")
    @manager.create("Task B")

    tasks = @manager.list

    assert_equal 2, tasks.length
  end

  def test_list_filters_by_status
    @manager.create("Pending task")
    @manager.create("Done task", status: "done")

    pending_tasks = @manager.list(status: "pending")
    done_tasks = @manager.list(status: "done")

    assert_equal 1, pending_tasks.length
    assert_equal "Pending task", pending_tasks.first.title
    assert_equal 1, done_tasks.length
    assert_equal "Done task", done_tasks.first.title
  end

  def test_list_filters_by_tags
    @manager.create("API task", tags: ["api"])
    @manager.create("UI task", tags: ["ui"])

    api_tasks = @manager.list(tags: ["api"])

    assert_equal 1, api_tasks.length
    assert_equal "API task", api_tasks.first.title
  end

  def test_list_returns_empty_array_when_no_tasks
    tasks = @manager.list

    assert_equal [], tasks
  end

  def test_list_with_generic_filters
    @manager.create("High priority", priority: "high")
    @manager.create("Low priority", priority: "low")

    tasks = @manager.list(filters: ["priority:high"])

    assert_equal 1, tasks.length
    assert_equal "High priority", tasks.first.title
  end

  # --- update ---

  def test_update_sets_fields
    task = @manager.create("Updatable task")

    updated = @manager.update(task.id, set: {"status" => "done"})

    assert_equal "done", updated.status
  end

  def test_update_adds_to_arrays
    task = @manager.create("Taggable task", tags: ["api"])

    updated = @manager.update(task.id, add: {"tags" => "urgent"})

    assert_includes updated.tags, "api"
    assert_includes updated.tags, "urgent"
  end

  def test_update_removes_from_arrays
    task = @manager.create("Removable task", tags: ["api", "urgent"])

    updated = @manager.update(task.id, remove: {"tags" => "urgent"})

    assert_includes updated.tags, "api"
    refute_includes updated.tags, "urgent"
  end

  def test_update_with_nested_dot_key
    task = @manager.create("Nested update task")

    updated = @manager.update(task.id, set: {"update.frequency" => "weekly"})

    assert_equal "weekly", updated.metadata.dig("update", "frequency")
  end

  def test_update_returns_nil_for_unknown_ref
    result = @manager.update("zzz", set: {"status" => "done"})

    assert_nil result
  end

  # --- move via update --move-to ---

  def test_update_move_to_special_folder
    task = @manager.create("Movable task")

    moved = @manager.update(task.id, move_to: "_backlog")

    assert_equal "_backlog", moved.special_folder
    assert moved.path.include?("_backlog")
  end

  def test_update_move_to_root
    task = @manager.create("Root-bound task")
    @manager.update(task.id, move_to: "_backlog")

    moved = @manager.update(task.id, move_to: "root")

    assert_nil moved.special_folder
  end

  def test_update_move_to_returns_nil_for_unknown_ref
    result = @manager.update("zzz", move_to: "_backlog")

    assert_nil result
  end

  def test_update_subtask_move_to_archive_soft_blocks_when_siblings_not_terminal
    parent = @manager.create("Parent task")
    first = @manager.create_subtask(parent.id, "Subtask one", status: "done")
    @manager.create_subtask(parent.id, "Subtask two", status: "pending")

    updated = @manager.update(first.id, move_to: "archive")

    assert_equal first.id, updated.id
    assert_nil updated.special_folder
    assert_match(/not archived because sibling subtasks are not all terminal/i, @manager.last_update_note)
    refute Dir.exist?(File.join(@tmpdir, "_archive")), "Archive folder should not be created"
  end

  def test_update_subtask_move_to_archive_moves_parent_when_all_subtasks_terminal
    parent = @manager.create("Parent task")
    first = @manager.create_subtask(parent.id, "Subtask one", status: "done")
    @manager.create_subtask(parent.id, "Subtask two", status: "skipped")

    updated = @manager.update(first.id, move_to: "archive")

    assert_equal first.id, updated.id
    assert_equal "_archive", updated.special_folder
    assert_match(/Archived parent task #{parent.id}/, @manager.last_update_note)

    archived_parent_dirs = Dir.glob(File.join(@tmpdir, "_archive", "**", "#{parent.id}-*"))
      .select { |path| File.directory?(path) }
    assert_equal 1, archived_parent_dirs.length

    reloaded_parent = @manager.show(parent.id)
    assert_equal "_archive", reloaded_parent.special_folder
  end

  # --- create_subtask ---

  def test_create_subtask_allocates_char
    parent = @manager.create("Parent for subtask")

    subtask = @manager.create_subtask(parent.id, "First subtask")

    assert subtask.id.match?(/^[0-9a-z]{3}\.t\.[0-9a-z]{3}\.0$/)
    assert_equal "First subtask", subtask.title
    assert_equal "pending", subtask.status
  end

  def test_create_subtask_sequential_allocation
    parent = @manager.create("Parent with many subtasks")

    sub_a = @manager.create_subtask(parent.id, "Subtask A")
    sub_b = @manager.create_subtask(parent.id, "Subtask B")

    assert sub_a.id.end_with?(".0")
    assert sub_b.id.end_with?(".1")
  end

  def test_create_subtask_with_priority_and_tags
    parent = @manager.create("Parent task")

    subtask = @manager.create_subtask(parent.id, "Tagged subtask", priority: "high", tags: ["urgent"])

    assert_equal "high", subtask.priority
    assert_equal ["urgent"], subtask.tags
  end

  def test_create_subtask_returns_nil_for_unknown_parent
    result = @manager.create_subtask("zzz", "Orphan subtask")

    assert_nil result
  end

  # --- root_dir ---

  def test_root_dir_returns_configured_path
    assert_equal @tmpdir, @manager.root_dir
  end

  def test_create_with_github_issue_triggers_sync
    sync_calls = []
    fake_sync = Object.new
    fake_sync.define_singleton_method(:validate_link!) { |**_payload| }
    fake_sync.define_singleton_method(:sync_task) do |**payload|
      sync_calls << payload
      {synced: 1}
    end

    Ace::Task::Molecules::GithubIssueSyncAdapter.stub(:new, fake_sync) do
      @manager.create("Linked task", github_issue: 276)
    end

    assert_equal 1, sync_calls.length
    assert_equal "create", sync_calls.first[:reason]
    assert_equal 276, sync_calls.first[:task].metadata["github_issue"]
  end

  def test_github_sync_all_only_processes_linked_tasks
    sync_calls = []
    fake_sync = Object.new
    fake_sync.define_singleton_method(:validate_link!) { |**_payload| }
    fake_sync.define_singleton_method(:sync_task) do |**payload|
      sync_calls << payload
      {synced: 1}
    end

    Ace::Task::Molecules::GithubIssueSyncAdapter.stub(:new, fake_sync) do
      @manager.create("Unlinked task")
      @manager.create("Linked task A", github_issue: 276)
      @manager.create("Linked task B", github_issue: 278)
      sync_calls.clear
      result = @manager.github_sync(all: true)
      assert_equal 2, result[:synced]
    end

    assert_equal 2, sync_calls.length
    assert sync_calls.all? { |call| call[:reason] == "manual-sync" }
  end

  def test_github_sync_all_reports_failures
    calls = 0
    fake_sync = Object.new
    fake_sync.define_singleton_method(:validate_link!) { |**_payload| }
    fake_sync.define_singleton_method(:sync_task) do |**payload|
      calls += 1
      raise "gh unavailable for #{payload[:task]&.id}" if calls == 2

      {synced: 1}
    end

    result = nil
    Ace::Task::Molecules::GithubIssueSyncAdapter.stub(:new, fake_sync) do
      @manager.create("Linked task A", github_issue: 276)
      @manager.create("Linked task B", github_issue: 278)
      calls = 0
      result = @manager.github_sync(all: true)
    end

    assert_equal 1, result[:synced]
    assert_equal 1, result[:failed]
    assert_equal 0, result[:skipped]
    assert_equal 1, result[:failures].length
  end

  def test_create_records_sync_warning_instead_of_raising
    fake_sync = Object.new
    fake_sync.define_singleton_method(:validate_link!) { |**_payload| }
    fake_sync.define_singleton_method(:sync_task) do |**_payload|
      raise "gh unavailable"
    end

    task = nil
    Ace::Task::Molecules::GithubIssueSyncAdapter.stub(:new, fake_sync) do
      task = @manager.create("Linked task", github_issue: 276)
    end

    assert_equal "Linked task", task.title
    assert_match(/GitHub sync warning/i, @manager.last_update_note)
    assert_match(/gh unavailable/, @manager.last_update_note)
  end

  def test_update_syncs_removed_linked_issues_using_previous_task_context
    sync_calls = []
    fake_sync = Object.new
    fake_sync.define_singleton_method(:validate_link!) { |**_payload| }
    fake_sync.define_singleton_method(:sync_task) do |**payload|
      sync_calls << payload
      {synced: 1}
    end

    Ace::Task::Molecules::GithubIssueSyncAdapter.stub(:new, fake_sync) do
      task = @manager.create("Linked task", github_issue: 276)
      sync_calls.clear
      @manager.update(task.id, set: {"github_issue" => nil})
    end

    assert_equal 1, sync_calls.length
    assert_equal "update", sync_calls.first[:reason]
    assert_equal 276, sync_calls.first[:previous_task].metadata["github_issue"]
  end
end
