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
    adapter.define_singleton_method(:reconcile_comment) { |**args| sync.call(**args) }
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
    adapter = fake_issue_adapter { |task:, **_| calls << task.metadata.fetch("remote_issue") }
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
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      updated = @manager.update(task.id, set: {"status" => "blocked"})
      assert_equal issue_identity, updated.metadata["remote_issue"]
      assert @manager.show(task.id).metadata["issue_sync_pending"]
      assert_match(/issue-sync --pending/, @manager.last_update_note)
    end
  end

  def test_offline_create_persists_pending_in_link_write
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      reloaded = @manager.show(task.id)
      assert_equal issue_identity, reloaded.metadata["remote_issue"]
      assert reloaded.metadata["issue_sync_pending"]
    end
  end

  def test_priority_only_update_does_not_set_pending_flag
    adapter = fake_issue_adapter { |task:, **_| }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      @manager.update(task.id, set: {"priority" => "high"})
      refute @manager.show(task.id).metadata["issue_sync_pending"]
    end
  end

  def test_status_update_sets_pending_flag_for_linked_task
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      @manager.update(task.id, set: {"status" => "blocked"})
      assert @manager.show(task.id).metadata["issue_sync_pending"]
    end
  end

  def test_move_sets_pending_before_relocating_linked_task
    synced = []
    adapter = fake_issue_adapter { |task:, **_| synced << [task.id, task.metadata["issue_sync_pending"]] }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      @manager.update(task.id, move_to: "archive")
      # The sync that follows the move observes the durable pending flag
      # written before the relocation; verified sync then clears it.
      assert_equal [task.id, true], synced.last
      refute @manager.show(task.id).metadata["issue_sync_pending"]
    end
  end

  def test_successful_sync_clears_pending_in_returned_metadata
    adapter = fake_issue_adapter { |task:, **_| }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      updated = @manager.update(task.id, set: {"status" => "blocked"})
      refute updated.metadata["issue_sync_pending"]
      assert @manager.show(task.id).metadata["issue_sync_pending"].nil?
    end
  end

  def test_reparent_passes_previous_id_for_ownership_transfer
    captured = []
    adapter = fake_issue_adapter { |task:, previous_task_id: nil, **_| captured << [task.id, previous_task_id] }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      task = @manager.create("Linked task", remote_issue: issue_identity)
      reparented = @manager.update(task.id, move_as_child_of: parent.id)
      refute_equal task.id, reparented.id
      assert_equal [reparented.id, task.id], captured.last
    end
  end

  def test_reparent_persists_pending_and_previous_id_before_transfer
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      task = @manager.create("Linked task", remote_issue: issue_identity)
      reparented = @manager.update(task.id, move_as_child_of: parent.id)
      reloaded = @manager.show(reparented.id)
      assert reloaded.metadata["issue_sync_pending"]
      assert_equal task.id, reloaded.metadata["issue_sync_previous_id"]
    end
  end

  def test_reparent_saves_previous_id_for_pending_clear
    # A pending clear defers the pending write, but its replay still needs
    # the outgoing ID to prove ownership of the marker written under the
    # previous task ID.
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      task = @manager.create("Linked task", remote_issue: issue_identity)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"issue_sync_operation" => "clear", "issue_sync_pending" => true}
      )
      reparented = @manager.update(task.id, move_as_child_of: parent.id)
      reloaded = @manager.show(reparented.id)
      assert_equal "clear", reloaded.metadata["issue_sync_operation"]
      assert_equal task.id, reloaded.metadata["issue_sync_previous_id"]
    end
  end

  def test_failed_clear_reconcile_persists_intent_and_replay_clears
    calls = []
    fail_reconcile = true
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, before_create: nil, **_|
      before_create&.call
      calls << :sync
    end
    adapter.define_singleton_method(:reconcile_comment) do |task:, **_|
      raise Ace::Git::ProviderUnreachableError, "forge offline" if fail_reconcile

      calls << :reconcile
    end
    adapter.define_singleton_method(:clear_task) do |task:, previous_task_id: nil, **_|
      calls << :clear
    end
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Guarded task", remote_issue: issue_identity)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
      )

      # The clear fails during reconciliation — but the clear intent must
      # survive so a pending replay cannot silently restore tracking.
      assert_raises(Ace::Git::ProviderUnreachableError) do
        @manager.issue_link(task.id, clear: true)
      end
      fresh = @manager.show(task.id)
      assert_equal "clear", fresh.metadata["issue_sync_operation"]
      assert fresh.metadata["issue_sync_reconcile_create"]
      assert fresh.metadata["issue_sync_pending"]

      # The pending retry reconciles first, then clears the link without
      # changing issue state.
      fail_reconcile = false
      @manager.issue_sync(pending: true)
      fresh = @manager.show(task.id)
      refute fresh.metadata["remote_issue"]
      refute fresh.metadata["issue_sync_pending"]
      refute fresh.metadata["issue_sync_reconcile_create"]
      assert_equal [:sync, :reconcile, :clear], calls
    end
  end

  def test_clear_intent_is_persisted_before_reconciliation_runs
    sequence = []
    recorder = Module.new do
      define_method(:update) do |*args, **kwargs|
        sequence << :write
        super(*args, **kwargs)
      end
    end
    Ace::Support::Items::Molecules::FieldUpdater.singleton_class.prepend(recorder)
    adapter = fake_issue_adapter { |task:, **_| sequence << :sync }
    adapter.define_singleton_method(:reconcile_comment) do |task:, **_|
      sequence << :reconcile
    end
    adapter.define_singleton_method(:clear_task) do |task:, previous_task_id: nil, **_|
      sequence << :clear
    end
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Guarded task", remote_issue: issue_identity)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
      )
      sequence.clear
      @manager.issue_link(task.id, clear: true)
      # The intent write lands before reconciliation touches the remote, so
      # a stop mid-reconciliation still replays as a clear.
      assert_equal :write, sequence.first
      assert sequence.index(:write) < sequence.index(:reconcile)
      assert_includes sequence, :clear
    end
  end

  def test_concurrent_linked_creates_serialize_on_issue_lock
    adapter = fake_issue_adapter { |task:, **_| {success: true} }
    @manager.stub(:issue_adapter, adapter) do
      first = @manager.create("First", remote_issue: issue_identity)
      pending_create = nil
      @manager.send(:with_issue_identity_lock, issue_identity) do
        thread = Thread.new { @manager.create("Second", remote_issue: issue_identity) }
        sleep 0.3
        # The second create cannot have written while the lock is held.
        specs = Dir.glob(File.join(@manager.root_dir, "**", "*.s.md"))
        assert_equal 1, specs.length
        pending_create = thread
      end
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) { pending_create.value }
      assert_match(/already linked/, error.message)
      # The rejected create leaves no artifact behind.
      specs = Dir.glob(File.join(@manager.root_dir, "**", "*.s.md"))
      assert_equal 1, specs.length
    end
  end

  def test_generic_updates_reject_issue_sync_control_fields
    adapter = fake_issue_adapter { |task:, **_| {success: true} }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      %w[remote_issue issue_sync_pending issue_sync_operation issue_sync_previous_id
         issue_sync_reconcile_create].each do |key|
        error = assert_raises(ArgumentError) do
          @manager.update(task.id, set: {key => nil})
        end
        assert_match(/issue-link/, error.message)
      end
    end
  end

  def test_pending_clear_completes_when_guarded_create_never_committed
    # Authoritative absence during a clear's reconciliation proves the
    # guarded create never committed: there is no marker to remove, so the
    # clear must complete instead of replaying the absence forever.
    calls = []
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) { |task:, before_create: nil, **_| calls << :sync }
    adapter.define_singleton_method(:reconcile_comment) do |task:, **_|
      calls << :reconcile
      raise Ace::Git::ProviderReconcileAbsenceError, "tracking comment create still unresolved"
    end
    adapter.define_singleton_method(:clear_task) { |task:, previous_task_id: nil, **_| calls << :clear }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Guarded task", remote_issue: issue_identity)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
      )
      @manager.issue_link(task.id, clear: true)
      fresh = @manager.show(task.id)
      refute fresh.metadata["remote_issue"]
      refute fresh.metadata["issue_sync_pending"]
      refute fresh.metadata["issue_sync_reconcile_create"]
      assert_includes calls, :clear
    end
  end

  def test_relocation_rejects_link_changed_under_the_participant_lock
    adapter = fake_issue_adapter { |task:, **_| {success: true} }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      other_identity = issue_identity(279)
      original_show = @manager.method(:show)
      show_calls = 0
      @manager.define_singleton_method(:show) do |ref|
        shown = original_show.call(ref)
        if shown&.id == task.id && (show_calls += 1) == 1
          # The first in-lock reload is the deferred-write reload: it now
          # names a different issue than the participant lock acquired.
          duped = shown.dup
          duped.define_singleton_method(:metadata) do
            shown.metadata.merge("remote_issue" => other_identity)
          end
          next duped
        end
        shown
      end
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        @manager.update(task.id, move_to: "maybe")
      end
      assert_match(/link changed during update/, error.message)
    ensure
      @manager.define_singleton_method(:show, original_show)
    end
  end

  def test_update_sync_rejects_link_changed_under_the_lock
    adapter = fake_issue_adapter { |task:, **_| {success: true} }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      other_identity = issue_identity(279)
      original_show = @manager.method(:show)
      show_calls = 0
      @manager.define_singleton_method(:show) do |ref|
        shown = original_show.call(ref)
        if shown&.id == task.id && (show_calls += 1) == 2
          # The second reload is the tail's in-lock reload: it now names a
          # different issue than the lock acquired.
          duped = shown.dup
          duped.define_singleton_method(:metadata) do
            shown.metadata.merge("remote_issue" => other_identity)
          end
          next duped
        end
        shown
      end
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        @manager.update(task.id, set: {"status" => "blocked"})
      end
      assert_match(/link changed during update/, error.message)
    ensure
      @manager.define_singleton_method(:show, original_show)
    end
  end

  def test_pending_replay_uses_persisted_previous_id
    captured = []
    offline = true
    adapter = fake_issue_adapter do |task:, previous_task_id: nil, **_|
      raise Ace::Git::ProviderUnreachableError, "offline" if offline

      captured << [task.id, previous_task_id]
    end
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      task = @manager.create("Linked task", remote_issue: issue_identity)
      reparented = @manager.update(task.id, move_as_child_of: parent.id)
      offline = false
      captured.clear
      result = @manager.issue_sync(pending: true)
      assert_equal 1, result[:synced]
      assert_equal [reparented.id, task.id], captured.last
      refute @manager.show(reparented.id).metadata["issue_sync_previous_id"]
    end
  end

  def test_chained_reparents_preserve_original_previous_id
    captured = []
    offline = true
    adapter = fake_issue_adapter do |task:, previous_task_id: nil, **_|
      raise Ace::Git::ProviderUnreachableError, "offline" if offline

      captured << [task.id, previous_task_id]
    end
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      grandparent = @manager.create("Grandparent")
      task = @manager.create("Linked task", remote_issue: issue_identity)
      first = @manager.update(task.id, move_as_child_of: parent.id)
      second = @manager.update(first.id, move_as_child_of: grandparent.id)
      offline = false
      @manager.issue_sync(pending: true)
      # The remote marker still names the ORIGINAL task ID; replay must prove
      # ownership against it, not the intermediate local ID.
      assert_equal [second.id, task.id], captured.last
      refute @manager.show(second.id).metadata["issue_sync_previous_id"]
    end
  end

  def test_parent_move_syncs_linked_child
    captured = []
    adapter = fake_issue_adapter { |task:, **_| captured << [task.id, task.metadata["issue_sync_pending"]] }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Linked child", remote_issue: issue_identity(9))
      @manager.update(parent.id, move_to: "archive")
      # The relocated child's sync observes the durable pending flag written
      # before the move; verified sync then clears it.
      assert_equal [child.id, true], captured.last
    end
  end

  def test_reparent_syncs_linked_descendants
    captured = []
    adapter = fake_issue_adapter { |task:, **_| captured << [task.id, task.metadata["issue_sync_pending"]] }
    @manager.stub(:issue_adapter, adapter) do
      target = @manager.create("Target")
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Linked child", remote_issue: issue_identity(9))
      @manager.update(parent.id, move_as_child_of: target.id)
      # The demoted parent's linked child was flagged pre-move and synced
      # from its new location.
      assert_includes captured, [child.id, true]
    end
  end

  def test_parent_move_syncs_linked_grandchild
    captured = []
    adapter = fake_issue_adapter { |task:, **_| captured << [task.id, task.metadata["issue_sync_pending"]] }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Child")
      grandchild = @manager.create_subtask(child.id, "Grandchild", remote_issue: issue_identity(9))
      @manager.update(parent.id, move_to: "archive")
      # The linked grandchild beneath the unlinked child is flagged and synced.
      assert_includes captured, [grandchild.id, true]
    end
  end

  def test_nested_subtask_refs_resolve_for_sync_and_clear
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) { |task:, **_| nil }
    adapter.define_singleton_method(:clear_task) { |**_args| nil }
    adapter.define_singleton_method(:reconcile_comment) { |task:, **_| nil }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Child")
      grandchild = @manager.create_subtask(child.id, "Grandchild", remote_issue: issue_identity(9))
      # A linked grandchild is manageable by its own reference.
      result = @manager.issue_sync(ref: grandchild.id)
      assert_equal 1, result[:synced]
      @manager.issue_link(grandchild.id, clear: true)
      refute @manager.show(grandchild.id).metadata["remote_issue"]
    end
  end

  def test_pending_replay_traverses_linked_grandchildren
    captured = []
    offline = true
    adapter = fake_issue_adapter do |task:, **_|
      raise Ace::Git::ProviderUnreachableError, "offline" if offline

      captured << task.id
    end
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Child")
      grandchild = @manager.create_subtask(child.id, "Grandchild", remote_issue: issue_identity(9))
      offline = false
      captured.clear
      result = @manager.issue_sync(pending: true)
      assert_equal 1, result[:synced]
      assert_includes captured, grandchild.id
    end
  end

  def test_failed_validation_retains_reconcile_create_guard
    adapter = fake_issue_adapter { |task:, **_| }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
      )
      assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity(999)) do
          @manager.issue_link(task.id, issue: "999", server_name: "lab")
        end
      end
      assert_equal "reconcile-create", @manager.show(task.id).metadata["issue_sync_operation"]
    end
  end

  def test_reparent_records_descendant_previous_ids
    offline_adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, offline_adapter) do
      target = @manager.create("Target")
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Linked child", remote_issue: issue_identity(9))
      @manager.update(parent.id, move_as_child_of: target.id)
      # The descendant's local ID changed with the parent; the persisted
      # previous ID preserves ownership of the remote marker.
      spec = Dir.glob(File.join(@manager.root_dir, "**", "*.s.md"))
        .find { |file| File.read(file).include?("issue_sync_previous_id") }
      assert spec, "expected a descendant carrying issue_sync_previous_id"
      content = File.read(spec)
      assert_match(/issue_sync_previous_id: #{Regexp.escape(child.id)}/, content)
      assert_match(/issue_sync_pending: true/, content)
    end
  end

  def test_identical_retry_reconciles_before_authorizing_create
    phases = []
    reconcile_reads = 0
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, previous_task_id: nil, before_create: nil|
      if task.metadata["issue_sync_operation"] == "reconcile-create"
        # Extended internal reads succeeded; the marker never appeared:
        # authoritative absence.
        phases << :reconcile
        raise Ace::Git::ProviderReconcileAbsenceError, "tracking comment create still unresolved"
      else
        phases << :create
        before_create&.call
        nil
      end
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
      )
      Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
        @manager.issue_link(task.id, issue: "276", server_name: "lab")
      end
      # The retry reconciles the guarded create first; only after the
      # reconcile window finds no marker does it authorize a fresh create.
      # The leading :create is the original link-time sync.
      assert_equal %i[create reconcile create], phases
      refute @manager.show(task.id).metadata["issue_sync_operation"]
    end
  end

  def test_identical_retry_keeps_guard_after_reconciliation_read_failure
    phases = []
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, previous_task_id: nil, before_create: nil|
      if task.metadata["issue_sync_operation"] == "reconcile-create"
        # A read failure mid-reconciliation is NOT authoritative absence:
        # the guard must survive and no fresh create may be authorized.
        phases << :reconcile
        raise Ace::Git::ProviderUnknownOutcomeError, "reconciliation reads failed"
      else
        phases << :create
        before_create&.call
        nil
      end
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
      )
      Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
        assert_raises(Ace::Git::ProviderUnreachableError) do
          @manager.issue_link(task.id, issue: "276", server_name: "lab")
        end
      end
      assert_equal %i[create reconcile], phases
      assert_equal "reconcile-create", @manager.show(task.id).metadata["issue_sync_operation"]
    end
  end

  def test_pending_clear_create_guard_sets_create_pending_on_sync
    captured = []
    adapter = @manager.send(:issue_adapter)
    adapter.define_singleton_method(:tracking) do |server|
      Object.new.tap do |service|
        service.define_singleton_method(:sync) do |**kwargs|
          captured << kwargs[:create_pending]
          {issue: nil, comments: [], labels: []}
        end
      end
    end
    Ace::Task::Molecules::IssueLink.stub(:validate!, issue_identity) do
      adapter.define_singleton_method(:validate_link!) { |**_args| true }
      @manager.stub(:issue_adapter, adapter) do
        task = @manager.create("Linked task", remote_issue: issue_identity)
        Ace::Support::Items::Molecules::FieldUpdater.update(
          task.file_path, set: {"issue_sync_operation" => "clear", "issue_sync_pending" => true,
                                "issue_sync_reconcile_create" => true}
        )
        fresh = @manager.show(task.id)
        adapter.sync_task(task: fresh, previous_task_id: nil, before_create: nil)
        # A sync of a clear-flagged task must reconcile the original create
        # (create_pending) instead of risking a duplicate POST before the
        # original comment appears.
        assert captured.last == true
      end
    end
  end

  def test_chained_descendant_reparents_preserve_original_owner_id
    offline = true
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnreachableError, "offline" if offline }
    @manager.stub(:issue_adapter, adapter) do
      target = @manager.create("Target")
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Linked child", remote_issue: issue_identity(9))
      first = @manager.update(parent.id, move_as_child_of: target.id)
      # Locate the linked child's spec under the demoted parent.
      child_spec = Dir.glob(File.join(@manager.root_dir, "**", "*.s.md"))
        .find { |file| File.basename(file).start_with?("#{first.id}.0-") }
      assert child_spec, "expected the linked child under the demoted parent"
      content = File.read(child_spec)
      assert_match(/issue_sync_previous_id: #{Regexp.escape(child.id)}/, content)
      assert_match(/issue_sync_pending: true/, content)

      # A deeper chained reparent is driven through the reparenter (depth-3
      # refs are not resolvable by update); the identity rewrite it performs
      # must preserve the recorded outgoing owner ID.
      loader = Ace::Task::Molecules::TaskLoader.new
      child_dir = File.dirname(child_spec)
      demoted = loader.load(child_dir, id: "#{first.id}.0")
      second = Ace::Task::Molecules::TaskReparenter.new(root_dir: @manager.root_dir)
        .reparent(demoted, target: target.id, resolve_ref: ->(r) { @manager.show(r) })
      rewritten = File.read(Dir.glob(File.join(second.path, "**", "*.s.md"))
        .find { |file| File.basename(file).start_with?("#{second.id}-") })
      assert_match(/issue_sync_previous_id: #{Regexp.escape(child.id)}/, rewritten)
      assert_match(/issue_sync_pending: true/, rewritten)
    end
  end

  def test_definitive_rejection_clears_guard_for_retry
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    attempts = 0
    adapter.define_singleton_method(:sync_task) do |task:, **_|
      if attempts.zero?
        attempts += 1
        raise Ace::Git::ProviderAuthenticationError, "credentials expired"
      end
      nil
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      # The auth rejection is definitive: the guard does not survive it.
      refute @manager.show(task.id).metadata["issue_sync_operation"]
      # Pending replay retries the create (now succeeding).
      result = @manager.issue_sync(pending: true)
      assert_equal 1, result[:synced]
      refute @manager.show(task.id).metadata["issue_sync_pending"]
    end
  end

  def test_reparent_rewrites_stale_dependency_references
    adapter = fake_issue_adapter { |task:, **_| }
    @manager.stub(:issue_adapter, adapter) do
      dependent = @manager.create("Dependent")
      target = @manager.create("Target")
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Linked child")
      @manager.update(dependent.id, set: {}, add: {dependencies: child.id})
      demoted = @manager.update(parent.id, move_as_child_of: target.id)
      spec = File.read(Dir.glob(File.join(@manager.root_dir, "**", "*.s.md"))
        .find { |file| File.read(file).include?("Dependent") })
      # The child reference follows the reparented parent's new ID.
      assert_match(/dependencies: \[#{Regexp.escape(demoted.id)}\.0\]/, spec)
    end
  end

  def test_unknown_create_with_unreachable_reconcile_retains_guard_in_call
    calls = 0
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, before_create: nil, **_|
      calls += 1
      before_create&.call
      # The reconciliation read inside the creating call fails unreachable.
      raise Ace::Git::ProviderUnreachableError, "reconciliation read failed"
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      @manager.issue_sync(pending: true) rescue nil
      # Create attempt + one reconcile-only replay; no third (create) call.
      assert_equal 2, calls
      assert_equal "reconcile-create", @manager.show(task.id).metadata["issue_sync_operation"]
    end
  end

  def test_unknown_create_then_unreachable_reconcile_retains_guard
    state = :unknown_create
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, before_create: nil, **_|
      if state == :unknown_create
        before_create&.call
        state = :unreachable_reconcile
        raise Ace::Git::ProviderUnknownOutcomeError, "create send outcome unknown"
      end
      raise Ace::Git::ProviderUnreachableError, "reconciliation read failed"
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      @manager.issue_sync(pending: true) rescue nil
      # The unreachable reconciliation read must retain the guard.
      assert_equal "reconcile-create", @manager.show(task.id).metadata["issue_sync_operation"]
    end
  end

  def test_offline_reconcile_retains_creation_guard
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, **_|
      if task.metadata["issue_sync_operation"] == "reconcile-create"
        raise Ace::Git::ProviderUnreachableError, "forge offline"
      end
      raise Ace::Git::ProviderUnknownOutcomeError, "unknown send"
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"issue_sync_operation" => "reconcile-create"}
      )
      Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
        assert_raises(Ace::Git::ProviderUnreachableError) do
          @manager.issue_link(task.id, issue: "276", server_name: "lab")
        end
      end
      # The unreadable forge keeps the guard: pending replay may still adopt
      # a slow commit, so the retry must not authorize a second create.
      assert_equal "reconcile-create", @manager.show(task.id).metadata["issue_sync_operation"]
    end
  end

  def test_clear_after_uncertain_state_update_skips_reconcile
    seen = []
    adapter = fake_issue_adapter { |task:, **_| seen << :sync }
    adapter.define_singleton_method(:reconcile_comment) do |task:, **_|
      seen << :comment_only
      nil
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      @manager.update(task.id, set: {"status" => "blocked"})
      @manager.issue_link(task.id, clear: true)
      # An uncertain label/state update does not arm the create guard, so the
      # clear runs no lifecycle reconciliation at all - issue state untouched.
      # The two syncs are the create-time and status-update syncs only.
      assert_equal %i[sync sync], seen
      refute @manager.show(task.id).metadata["remote_issue"]
    end
  end

  def test_issue_identity_lock_serializes_operations
    identity = issue_identity
    key = @manager.send(:canonical_issue_key, identity)
    lock_path = File.join(Dir.tmpdir, "ace-task-issue-#{key}.lock")
    marker = File.join(Dir.tmpdir, "\#{key}.held")
    File.delete(marker) if File.exist?(marker)

    child_pid = fork do
      holder = File.open(lock_path, File::CREAT | File::RDWR)
      holder.flock(File::LOCK_EX)
      File.write(marker, "held")
      sleep 0.3
      holder.flock(File::LOCK_UN)
      exit!(0)
    end
    deadline = Time.now + 5
    sleep 0.05 until File.exist?(marker) || Time.now > deadline
    assert File.exist?(marker), "child did not take the lock"

    started = Time.now
    entered = false
    @manager.send(:with_issue_identity_lock, identity) { entered = true }
    assert entered
    # Cross-process flock conflicts, so the operation could only proceed
    # after the child released - proving serialization by identity.
    assert Time.now - started >= 0.2, "operation ran while the identity lock was held elsewhere"
    Process.wait(child_pid)
  end

  def test_update_move_runs_while_issue_identity_lock_is_held
    identity = issue_identity
    key = @manager.send(:canonical_issue_key, identity)
    lock_path = File.join(Dir.tmpdir, "ace-task-issue-#{key}.lock")
    lock_probe = File.join(Dir.tmpdir, "qk12-move-lock-probe")
    File.delete(lock_probe) if File.exist?(lock_probe)

    # At the moment the relocation moves the spec file, a non-blocking flock
    # from another thread can only fail if the update itself holds the
    # identity lock - proving the move runs under the same hold that wrote
    # the pending flag, so no replay can clear it mid-move.
    Ace::Support::Items::Molecules::FolderMover.prepend(Module.new do
      define_method(:move) do |*args, **kwargs|
        contender = Thread.new do
          fd = File.open(lock_path, File::CREAT | File::RDWR)
          acquired = fd.flock(File::LOCK_EX | File::LOCK_NB) != false
          fd.flock(File::LOCK_UN) if acquired
          fd.close
          acquired
        end
        File.write(lock_probe, contender.value ? "free" : "held")
        super(*args, **kwargs)
      end
    end)

    adapter = fake_issue_adapter { |**_args| {success: true} }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Movable task", remote_issue: identity)
      @manager.update(task.id, move_to: "archive")
    end
    assert_equal "held", File.read(lock_probe),
      "relocation must run while the linked issue's identity lock is held"
  end

  def test_unlinked_parent_move_holds_linked_descendant_locks
    identity = issue_identity(277)
    key = @manager.send(:canonical_issue_key, identity)
    lock_path = File.join(Dir.tmpdir, "ace-task-issue-#{key}.lock")
    lock_probe = File.join(Dir.tmpdir, "qk12-desc-lock-probe")
    File.delete(lock_probe) if File.exist?(lock_probe)

    Ace::Support::Items::Molecules::FolderMover.prepend(Module.new do
      define_method(:move) do |*args, **kwargs|
        contender = Thread.new do
          fd = File.open(lock_path, File::CREAT | File::RDWR)
          acquired = fd.flock(File::LOCK_EX | File::LOCK_NB) != false
          fd.flock(File::LOCK_UN) if acquired
          fd.close
          acquired
        end
        File.write(lock_probe, contender.value ? "free" : "held")
        super(*args, **kwargs)
      end
    end)

    adapter = fake_issue_adapter { |**_args| {success: true} }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Unlinked parent")
      @manager.create_subtask(parent.id, "Linked subtask", remote_issue: identity)
      @manager.update(parent.id, move_to: "maybe")
    end
    assert_equal "held", File.read(lock_probe),
      "descendant locks must span a relocation even when the parent is unlinked"
  end

  def test_aliased_server_identity_rejects_duplicate_link_of_same_issue
    identity = issue_identity(276)
    alias_identity = identity.merge(
      "server_name" => "mirror",
      "repository_url" => "ssh://git@forge.example/owner/repo.git",
      "url" => "https://forge.example/owner/repo/issues/276"
    )
    adapter = fake_issue_adapter { |**_args| {success: true} }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: identity)
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        @manager.create("Aliased task", remote_issue: alias_identity)
      end
      assert_includes error.message, task.id
      # A different issue on the same repository stays linkable.
      other = @manager.create("Other issue task", remote_issue: identity.merge("number" => 278,
        "url" => "https://forge.example/owner/repo/issues/278"))
      assert other.metadata["remote_issue"]
    end
  end

  def test_aliased_server_identities_share_one_issue_lock
    identity = issue_identity(276)
    alias_identity = identity.merge("server_name" => "mirror",
      "repository_url" => "ssh://git@forge.example/owner/repo.git")
    key = @manager.send(:canonical_issue_key, identity)
    lock_path = File.join(Dir.tmpdir, "ace-task-issue-#{key}.lock")
    marker = File.join(Dir.tmpdir, "alias-lock-held")
    File.delete(marker) if File.exist?(marker)

    child_pid = fork do
      holder = File.open(lock_path, File::CREAT | File::RDWR)
      holder.flock(File::LOCK_EX)
      File.write(marker, "held")
      sleep 0.3
      holder.flock(File::LOCK_UN)
      exit!(0)
    end
    deadline = Time.now + 5
    sleep 0.05 until File.exist?(marker) || Time.now > deadline
    assert File.exist?(marker), "child did not take the lock"

    started = Time.now
    entered = false
    @manager.send(:with_issue_identity_lock, alias_identity) { entered = true }
    assert entered
    # The alias normalizes to the same canonical lock, so the operation could
    # only proceed after the child released the primary identity's lock.
    assert Time.now - started >= 0.2, "aliased identity bypassed the canonical issue lock"
    Process.wait(child_pid)
  end

  def test_canonical_issue_key_folds_case_and_scheme_variants
    base = issue_identity(276)
    variant = base.merge("server_name" => "other",
      "repository_url" => "SSH://GIT@FORGE.EXAMPLE/OWNER/REPO.GIT")
    refute_equal base["server_name"], variant["server_name"]
    assert_equal @manager.send(:canonical_issue_key, base),
      @manager.send(:canonical_issue_key, variant)
  end

  def test_canonical_issue_key_keeps_distinct_repositories_unambiguous
    first = issue_identity(276).merge("repository_url" => "https://forge.example/a/b_c")
    second = issue_identity(276).merge("repository_url" => "https://forge.example/a_b/c")
    refute_equal @manager.send(:canonical_issue_key, first),
      @manager.send(:canonical_issue_key, second)
  end

  def test_subtask_archive_never_holds_child_lock_while_waiting_for_parent
    parent_identity = issue_identity(280)
    child_identity = issue_identity(282)
    child_key = @manager.send(:canonical_issue_key, child_identity)
    child_lock_path = File.join(Dir.tmpdir, "ace-task-issue-#{child_key}.lock")

    adapter = fake_issue_adapter { |**_args| {success: true} }
    updater = nil
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Archivable parent", remote_issue: parent_identity)
      child = @manager.create_subtask(parent.id, "Terminal subtask", status: "done",
        remote_issue: child_identity)

      # With the parent's identity lock held elsewhere, the child archive must
      # block on the parent lock BEFORE holding the child lock: holding both
      # directions at once is the parent/child ABBA deadlock hazard.
      @manager.send(:with_issue_identity_lock, parent_identity) do
        updater = Thread.new { @manager.update(child.id, move_to: "archive") }
        sleep 0.4
        contender = File.open(child_lock_path, File::CREAT | File::RDWR)
        acquired = contender.flock(File::LOCK_EX | File::LOCK_NB) != false
        contender.flock(File::LOCK_UN) if acquired
        contender.close
        assert acquired, "child archive held the child lock while waiting for the parent lock"
      end
      assert updater.join(10), "child archive deadlocked on the parent identity lock"
    end
  end

  def test_bulk_sync_fails_for_pending_tasks_without_identity
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnknownOutcomeError, "unknown" }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      task = @manager.show(task.id)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"remote_issue" => nil}
      )
      result = @manager.issue_sync(all: true)
      # The inconsistent task is reported as a failure (never a silent skip)
      # and the CLI exits nonzero on its pending count.
      assert_equal 0, result[:skipped]
      assert_equal 1, result[:failed] + result[:pending]
      assert_equal 1, result[:failures].length
      assert_match(/no remote_issue recovery identity/, result[:failures].first[:error])
    end
  end

  def test_rejected_linked_creation_leaves_no_task_artifact
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) do |**args|
      raise Ace::Git::ProviderIdentityMismatchError, "remote owner conflict" if args[:task_id].nil?
      true
    end
    adapter.define_singleton_method(:sync_task) { |task:, **_| }
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    adapter.define_singleton_method(:reconcile_comment) { |task:, **_| }
    @manager.stub(:issue_adapter, adapter) do
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        @manager.create("Rejected", remote_issue: issue_identity)
      end
      assert_match(/remote owner conflict/, error.message)
      # No task artifact survives a rejected linked creation.
      assert_empty Dir.glob(File.join(@manager.root_dir, "**", "*.s.md"))
    end
  end

  def test_post_create_identity_mismatch_retains_task_and_pending_flag
    # A mismatch that surfaces after the create guard was armed (e.g. a
    # concurrent external marker during post-POST verification) means the
    # tracking comment may have committed: the task and its pending identity
    # are the cleanup record and must survive.
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, before_create: nil, **_|
      before_create&.call
      raise Ace::Git::ProviderIdentityMismatchError, "Multiple ACE tracking comments on issue #276"
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    adapter.define_singleton_method(:reconcile_comment) { |task:, **_| }
    @manager.stub(:issue_adapter, adapter) do
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        @manager.create("Committed marker", remote_issue: issue_identity)
      end
      assert_match(/Multiple ACE tracking comments/, error.message)
      specs = Dir.glob(File.join(@manager.root_dir, "**", "*.s.md"))
      assert_equal 1, specs.length
      frontmatter = YAML.safe_load_file(specs.first, permitted_classes: [Time, Date])
      assert frontmatter["remote_issue"]
      assert frontmatter["issue_sync_pending"]
    end
  end

  def test_post_create_identity_mismatch_retains_fresh_link_mapping
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, before_create: nil, **_|
      before_create&.call
      raise Ace::Git::ProviderIdentityMismatchError, "Multiple ACE tracking comments on issue #276"
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    adapter.define_singleton_method(:reconcile_comment) { |task:, **_| }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Plain task")
      Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
        assert_raises(Ace::Git::ProviderIdentityMismatchError) do
          @manager.issue_link(task.id, issue: "276", server_name: "lab")
        end
      end
      linked = @manager.show(task.id)
      assert linked.metadata["remote_issue"]
      assert linked.metadata["issue_sync_pending"]
    end
  end

  def test_post_create_identity_mismatch_retains_linked_subtask
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, before_create: nil, **_|
      before_create&.call
      raise Ace::Git::ProviderIdentityMismatchError, "Multiple ACE tracking comments on issue #276"
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    adapter.define_singleton_method(:reconcile_comment) { |task:, **_| }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent for subtask")
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        @manager.create_subtask(parent.id, "Committed subtask", remote_issue: issue_identity)
      end
      assert_match(/Multiple ACE tracking comments/, error.message)
      specs = Dir.glob(File.join(@manager.root_dir, "**", "*.s.md"))
      assert_equal 2, specs.length
      subtask_specs = specs.select { |path| File.basename(path).include?("committed-subtask") }
      assert_equal 1, subtask_specs.length
      frontmatter = YAML.safe_load_file(subtask_specs.first, permitted_classes: [Time, Date])
      assert frontmatter["remote_issue"]
      assert frontmatter["issue_sync_pending"]
    end
  end

  def test_ref_sync_fails_for_pending_task_without_identity
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnknownOutcomeError, "unknown" }
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      # Simulate the inconsistent state: pending without an identity.
      task = @manager.show(task.id)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task.file_path, set: {"remote_issue" => nil}
      )
      result = @manager.issue_sync(ref: task.id)
      assert_equal 1, result[:failed]
      assert_equal 0, result[:skipped]
      assert_match(/no remote_issue recovery identity/, result[:failures].first[:error])
    end
  end

  def test_clear_rejects_unresolved_create_and_replay_completes_clear
    create_attempts = 0
    reconcile_ok = false
    adapter = Object.new
    adapter.define_singleton_method(:validate_link!) { |**_args| true }
    adapter.define_singleton_method(:sync_task) do |task:, previous_task_id: nil, **_|
      reconcile = task.metadata["issue_sync_operation"] == "reconcile-create"
      if reconcile
        # The marker never committed: authoritative absence after reads.
        raise Ace::Git::ProviderUnknownOutcomeError, "tracking comment create still unresolved"
      end
      create_attempts += 1
    end
    adapter.define_singleton_method(:clear_task) { |**_args| true }
    adapter.define_singleton_method(:reconcile_comment) do |task:, **_|
      raise Ace::Git::ProviderUnknownOutcomeError, "tracking comment create still unresolved" unless reconcile_ok
    end
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      task = @manager.create("Linked task", remote_issue: issue_identity)
      # First sync create ended unknown (flag set by the rescue path below).
      task2 = nil
      begin
        @manager.update(task.id, set: {"status" => "blocked"})
      rescue Ace::Git::ProviderUnreachableError
        nil
      end
      # ...simulate the flagged state explicitly:
      task2 = @manager.show(task.id)
      Ace::Support::Items::Molecules::FieldUpdater.update(
        task2.file_path, set: {"issue_sync_operation" => "reconcile-create"}
      )
      # Clear during an unresolved create fails (the reconciliation outcome
      # surfaces) without dropping the link — and the clear intent is
      # persisted so replay completes the clear instead of restoring.
      assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        @manager.issue_link(task2.id, clear: true)
      end
      cleared = @manager.show(task2.id)
      assert_equal issue_identity, cleared.metadata["remote_issue"]
      assert_equal "clear", cleared.metadata["issue_sync_operation"]
      assert cleared.metadata["issue_sync_reconcile_create"]
      # An identical-link retry must not silently undo the requested clear.
      assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
          @manager.issue_link(task2.id, issue: "276", server_name: "lab")
        end
      end
      # The pending replay reconciles the unresolved create first, then
      # completes the clear.
      reconcile_ok = true
      @manager.issue_sync(pending: true)
      cleared = @manager.show(task2.id)
      refute cleared.metadata["remote_issue"]
      refute cleared.metadata["issue_sync_pending"]
      refute cleared.metadata["issue_sync_reconcile_create"]
      # Re-linking after the completed clear works.
      Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
        linked = @manager.issue_link(task2.id, issue: "276", server_name: "lab")
        assert_equal issue_identity, linked.metadata["remote_issue"]
      end
    end
  end

  def test_orchestrator_conversion_syncs_linked_child_with_previous_id
    captured = []
    adapter = fake_issue_adapter do |task:, previous_task_id: nil, **_|
      captured << [task.id, previous_task_id]
    end
    @manager.stub(:issue_adapter, adapter) do
      task = @manager.create("Linked task", remote_issue: issue_identity)
      converted = @manager.update(task.id, move_as_child_of: "self")
      # The first capture is the create-time sync; the second is the
      # conversion sync targeting the child that retained the mapping.
      assert_equal 2, captured.length
      child_id, previous_id = captured.last
      # update returns the converted child; it differs from the original task
      refute_equal task.id, child_id
      refute_equal converted.id, task.id
      assert_equal task.id, previous_id
      assert_equal issue_identity, @manager.show(child_id).metadata["remote_issue"]
      refute @manager.show(child_id).metadata["issue_sync_pending"]
    end
  end

  def test_clear_after_pending_reparent_removes_previous_id
    adapter = fake_issue_adapter do |task:, **_|
      raise Ace::Git::ProviderUnreachableError, "offline" if @offline
    end
    @offline = true
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      task = @manager.create("Linked task", remote_issue: issue_identity)
      reparented = @manager.update(task.id, move_as_child_of: parent.id)
      @offline = false
      @manager.issue_link(reparented.id, clear: true)
      cleared = @manager.show(reparented.id)
      refute cleared.metadata["remote_issue"]
      refute cleared.metadata["issue_sync_previous_id"]
    end
  end

  def test_same_link_retry_validates_persisted_previous_id
    validate_calls = []
    offline = true
    adapter = fake_issue_adapter do |task:, **_|
      raise Ace::Git::ProviderUnreachableError, "offline" if offline
    end
    adapter.define_singleton_method(:validate_link!) do |**args|
      validate_calls << args.slice(:task_id, :previous_task_id)
      true
    end
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      task = @manager.create("Linked task", remote_issue: issue_identity)
      reparented = @manager.update(task.id, move_as_child_of: parent.id)
      offline = false
      Ace::Task::Molecules::IssueLink.stub(:from_input, issue_identity) do
        @manager.issue_link(reparented.id, issue: "276", server_name: "lab")
      end
      # The retry must prove ownership against the persisted outgoing ID.
      assert_equal({task_id: reparented.id, previous_task_id: task.id}, validate_calls.last)
    end
  end

  def test_bulk_sync_continues_after_failure
    adapter = fake_issue_adapter do |task:, **_|
      raise Ace::Git::ProviderUnreachableError, "offline" if task.title == "First"
    end
    @manager.stub(:issue_adapter, adapter) do
      @manager.create("First", remote_issue: issue_identity(1))
      @manager.create("Second", remote_issue: issue_identity(2))
      result = @manager.issue_sync(all: true)
      assert_equal 1, result[:synced]
      assert_equal 0, result[:failed]
      assert_equal 1, result[:pending]
      assert_equal issue_identity(1), result[:failures].first[:remote_issues].first
    end
  end

  def test_bulk_sync_includes_linked_subtasks
    synced = []
    adapter = fake_issue_adapter { |task:, **_| synced << task.id }
    @manager.stub(:issue_adapter, adapter) do
      parent = @manager.create("Parent")
      child = @manager.create_subtask(parent.id, "Linked child", remote_issue: issue_identity(9))
      result = @manager.issue_sync(all: true)
      assert_equal 1, result[:synced]
      assert_includes synced, child.id
    end
  end

  def test_create_rejects_duplicate_local_link_to_same_issue
    adapter = fake_issue_adapter { |task:, **_| raise Ace::Git::ProviderUnreachableError, "offline" }
    @manager.stub(:issue_adapter, adapter) do
      @manager.create("First", remote_issue: issue_identity)
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        @manager.create("Second", remote_issue: issue_identity)
      end
      assert_match(/already linked to task/, error.message)
    end
  end

  def test_duplicate_local_link_guard_ignores_other_issues
    adapter = fake_issue_adapter { |task:, **_| }
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
    adapter = fake_issue_adapter do |task:, **_|
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
    adapter = fake_issue_adapter { |task:, **_| }
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
    adapter = fake_issue_adapter { |task:, **_| }
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
    adapter = fake_issue_adapter { |task:, **_| sync_calls += 1 }
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
    adapter = fake_issue_adapter { |task:, **_| }
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
