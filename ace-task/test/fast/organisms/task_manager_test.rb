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

  # --- dependency-aware smart sort ---

  def test_list_smart_sort_orders_dependent_after_its_dependency
    dependent = @manager.create("Blocked dependent", priority: "high")
    dependency = @manager.create("Dependency root")
    @manager.update(dependent.id, add: {"dependencies" => dependency.id})

    tasks = @manager.list

    assert_equal [dependency.id, dependent.id], tasks.map(&:id)
    assert_empty @manager.last_list_cycle_ids
  end

  def test_list_smart_sort_keeps_task_with_archived_dependency_ready
    dependency = @manager.create("Soon archived")
    @manager.update(dependency.id, move_to: "archive")
    filler = @manager.create("Low priority filler", priority: "low")
    dependent = @manager.create("Ready dependent", priority: "high")
    @manager.update(dependent.id, add: {"dependencies" => dependency.id})

    tasks = @manager.list

    assert_equal [dependent.id, filler.id], tasks.map(&:id)
  end

  def test_list_smart_sort_with_missing_dependency_stays_listed_in_tail
    filler = @manager.create("Listed filler", priority: "low")
    orphan = @manager.create("Orphan dependent", priority: "high", dependencies: ["zzz.t.nope"])

    tasks = @manager.list

    assert_equal 2, tasks.length
    assert_equal [filler.id, orphan.id], tasks.map(&:id)
    assert_empty @manager.last_list_cycle_ids
  end

  def test_list_smart_sort_reports_dependency_cycles
    first = @manager.create("Cycle first")
    second = @manager.create("Cycle second")
    @manager.update(first.id, add: {"dependencies" => second.id})
    @manager.update(second.id, add: {"dependencies" => first.id})

    tasks = @manager.list

    assert_equal tasks.map(&:id).sort, @manager.last_list_cycle_ids.sort
    assert_equal 2, @manager.last_list_cycle_ids.length
  end

  def test_list_literal_sorts_ignore_dependencies
    dependent = @manager.create("High priority dependent", priority: "high")
    dependency = @manager.create("Pending dependency")
    @manager.update(dependent.id, add: {"dependencies" => dependency.id})

    assert_equal [dependent.id, dependency.id], @manager.list(sort: "priority").map(&:id)
    assert_equal [dependent.id, dependency.id], @manager.list(sort: "id").map(&:id)
    assert_equal [dependent.id, dependency.id], @manager.list(sort: "created").map(&:id)
    assert_equal [dependency.id, dependent.id], @manager.list(sort: "smart").map(&:id)
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

  def issue_identity(number = 276)
    {"server_name" => "lab", "provider" => "forgejo",
     "repository_url" => "https://forge.example/owner/repo", "number" => number,
     "url" => "https://forge.example/owner/repo/issues/#{number}"}
  end

  def fake_issue_adapter(&sync)
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) { |**args| sync.call(**args) }
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    adapter
  end

  def test_unlinked_task_create_never_loads_issue_adapter
    @manager.stub(:issue_adapter, -> { flunk "local task touched provider" }) do
      task = @manager.create("Local only")
      assert_equal "Local only", @manager.show(task.id).title
    end
  end

  def test_create_with_remote_issue_validates_and_syncs
    calls = []
    adapter = fake_issue_adapter { |task:| calls << task.metadata.fetch("remote_issue") }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      assert_equal issue_identity, task.metadata["remote_issue"]
    end
    assert_equal [issue_identity], calls
  end

  def test_generic_update_cannot_partially_retarget_remote_issue
    task = @manager.create("Local task")
    assert_raises(ArgumentError) do
      @manager.update(task.id, set: {"remote_issue.number" => "43"})
    end
    refute @manager.show(task.id).metadata.key?("remote_issue")
  end

  def test_offline_local_update_retains_link_and_pending_identity
    adapter = fake_issue_adapter { |task:| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      updated = @manager.update(task.id, set: {"status" => "blocked"})
      assert_equal issue_identity, updated.metadata["remote_issue"]
      assert @manager.show(task.id).metadata["issue_sync_pending"]
      assert_match(/issue-sync --pending/, @manager.last_update_note)
    end
  end

  def test_offline_create_persists_pending_in_link_write
    adapter = fake_issue_adapter { |task:| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      reloaded = @manager.show(task.id)
      assert_equal issue_identity, reloaded.metadata["remote_issue"]
      assert reloaded.metadata["issue_sync_pending"]
    end
  end

  def test_priority_only_update_does_not_set_pending_flag
    adapter = fake_issue_adapter { |task:| }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      @manager.update(task.id, set: {"priority" => "high"})
      refute @manager.show(task.id).metadata["issue_sync_pending"]
    end
  end

  def test_status_update_sets_pending_flag_for_linked_task
    adapter = fake_issue_adapter { |task:| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      @manager.update(task.id, set: {"status" => "blocked"})
      assert @manager.show(task.id).metadata["issue_sync_pending"]
    end
  end

  def test_bulk_sync_continues_after_failure
    adapter = fake_issue_adapter do |task:|
      raise Ace::Git::ProviderUnreachableError, "offline" if task.title == "First"
    end
    @manager.stub(:issue_adapter, adapter) do
      @manager.create("First", remote_issue: issue_identity(1))
      @manager.create("Second", remote_issue: issue_identity(2))
      result = @manager.issue_sync(all: true)
      assert_equal 1, result[:synced]
      assert_equal 1, result[:failed]
      assert_equal issue_identity(1), result[:failures].first[:remote_issues].first
    end
  end

  def test_bulk_sync_includes_linked_subtasks
    synced = []
    adapter = fake_issue_adapter { |task:| synced << task.id }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Linked child", remote_issue: issue_identity(9))
      result = @manager.issue_sync(all: true)
      assert_equal 1, result[:synced]
      assert_includes synced, child.id
    end
  end

  def test_create_rejects_duplicate_local_link_to_same_issue
    adapter = fake_issue_adapter { |task:| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      @manager.create("First", remote_issue: issue_identity)
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        @manager.create("Second", remote_issue: issue_identity)
      end
      assert_match(/already linked to task/, error.message)
    end
  end

  def test_duplicate_local_link_guard_ignores_other_issues
    adapter = fake_issue_adapter { |task:| }
    @manager.stub(:issue_adapter, adapter) do
      @manager.create("First", remote_issue: issue_identity)
      second = @manager.create("Second", remote_issue: issue_identity(277))
      assert_equal "Second", @manager.show(second.id).title
    end
  end

  def test_empty_pending_set_succeeds_with_zero_counts
    @manager.create("Local task")
    result = @manager.issue_sync(pending: true)
    assert_equal 0, result[:synced]
    assert_equal 0, result[:failed]
    assert_equal 0, result[:pending]
  end

  def test_unlinked_reference_sync_returns_complete_counts
    task = @manager.create("Local task")
    assert_equal({synced: 0, failed: 0, pending: 0, skipped: 1, task_id: task.id, failures: []},
      @manager.issue_sync(ref: task.id))
  end

  def test_identical_link_retries_pending_sync
    calls = 0
    adapter = fake_issue_adapter do |task:|
      calls += 1
      raise Ace::Git::ProviderUnreachableError, "offline" if calls == 1
    end
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      assert @manager.show(task.id).metadata["issue_sync_pending"]
      Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
        @manager.issue_link(task.id, issue: "276", server_name: "lab")
      end
      refute @manager.show(task.id).metadata["issue_sync_pending"]
      assert_equal 2, calls
    end
  end

  def test_explicit_link_rejects_other_owner_before_metadata_change
    task = @manager.create("Local task")
    adapter = fake_issue_adapter { |task:| }
    adapter.define_singleton_method(:validate_link!) do |**_args|
      raise Ace::Git::ProviderIdentityMismatchError, "owned elsewhere"
    end
    Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
      @manager.stub(:issue_adapter, adapter) do
        assert_raises(Ace::Git::ProviderIdentityMismatchError) do
          @manager.issue_link(task.id, issue: "276", server_name: "lab")
        end
      end
    end
    refute @manager.show(task.id).metadata.key?("remote_issue")
  end

  def test_clear_failure_keeps_recovery_identity_and_pending_flag
    adapter = fake_issue_adapter { |task:| }
    adapter.define_singleton_method(:clear_task) do |**_args|
      raise Ace::Git::ProviderUnreachableError, "offline"
    end
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      assert_raises(Ace::Git::ProviderUnreachableError) { @manager.issue_link(task.id, clear: true) }
      reloaded = @manager.show(task.id)
      assert_equal issue_identity, reloaded.metadata["remote_issue"]
      assert reloaded.metadata["issue_sync_pending"]
      assert_equal "clear", reloaded.metadata["issue_sync_operation"]
    end
  end

  def test_pending_clear_replays_clear_without_recreating_tracking
    sync_calls = 0
    clear_calls = 0
    adapter = fake_issue_adapter { |task:| sync_calls += 1 }
    adapter.define_singleton_method(:clear_task) do |**_args|
      clear_calls += 1
      raise Ace::Git::ProviderUnknownOutcomeError, "label removal unknown" if clear_calls == 1
    end
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      assert_raises(Ace::Git::ProviderUnknownOutcomeError) { @manager.issue_link(task.id, clear: true) }
      assert_equal "clear", @manager.show(task.id).metadata["issue_sync_operation"]
      result = @manager.issue_sync(pending: true)
      assert_equal 1, result[:synced]
      assert_equal 0, result[:failed]
      assert_nil @manager.show(task.id).metadata["remote_issue"]
      assert_equal 1, sync_calls
      assert_equal 2, clear_calls
    end
  end

  def test_different_link_conflicts_until_successful_clear
    adapter = fake_issue_adapter { |task:| }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity(277)) do
        assert_raises(Ace::Git::ProviderIdentityMismatchError) do
          @manager.issue_link(task.id, issue: "277", server_name: "lab")
        end
      end
      cleared = @manager.issue_link(task.id, clear: true)
      refute cleared.metadata["remote_issue"]
    end
  end

end
