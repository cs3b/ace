# frozen_string_literal: true

require_relative "../../test_helper"

class AssignmentManagerTest < AceAssignTestCase
  def test_create_assignment
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      assignment = manager.create(
        name: "test-session",
        description: "A test",
        source_config: "job.yaml"
      )

      assert_match(/\A[a-z0-9]{6}\z/, assignment.id)
      assert_equal "test-session", assignment.name
      assert_equal "A test", assignment.description
      assert_equal "job.yaml", assignment.source_config
      assert File.directory?(assignment.cache_dir)
      assert File.directory?(assignment.steps_dir)
      assert File.exist?(assignment.assignment_file)
    end
  end

  def test_load_assignment
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      created = manager.create(
        name: "test-session",
        source_config: "job.yaml"
      )

      loaded = manager.load(created.id)

      assert_equal created.id, loaded.id
      assert_equal created.name, loaded.name
      assert_equal created.cache_dir, loaded.cache_dir
    end
  end

  def test_load_nonexistent_returns_nil
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      result = manager.load("nonexistent")

      assert_nil result
    end
  end

  def test_find_active
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      # Create two assignments
      manager.create(name: "first", source_config: "job.yaml")
      second = manager.create(name: "second", source_config: "job.yaml")

      active = manager.find_active

      assert_equal second.id, active.id
      assert_equal "second", active.name
    end
  end

  def test_find_active_none
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      active = manager.find_active

      assert_nil active
    end
  end

  def test_list_assignments
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      first = manager.create(name: "first", source_config: "job.yaml")
      second = manager.create(name: "second", source_config: "job.yaml")

      # Verify collision handling - IDs should be different
      refute_equal first.id, second.id

      assignments = manager.list

      assert_equal 2, assignments.size
    end
  end

  def test_update_assignment
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      created = manager.create(name: "test", source_config: "job.yaml")
      original_updated = created.updated_at

      updated = manager.update(created)

      assert updated.updated_at >= original_updated
    end
  end

  # === .current symlink tests ===

  def test_set_current_creates_symlink
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      first = manager.create(name: "first", source_config: "job.yaml")
      manager.create(name: "second", source_config: "job.yaml")

      result = manager.set_current(first.id)

      assert_equal first.id, result.id
      assert File.symlink?(File.join(cache_dir, ".current"))
      assert_equal first.id, manager.current_id
    end
  end

  def test_set_current_raises_for_nonexistent
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      error = assert_raises(Ace::Assign::AssignmentErrors::NotFound) do
        manager.set_current("nonexistent")
      end

      assert_includes error.message, "nonexistent"
    end
  end

  def test_find_active_prefers_current_over_latest
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      first = manager.create(name: "first", source_config: "job.yaml")
      manager.create(name: "second", source_config: "job.yaml")

      # .latest points to second (most recent), but set .current to first
      manager.set_current(first.id)

      active = manager.find_active
      assert_equal first.id, active.id
    end
  end

  def test_clear_current_removes_symlink
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      first = manager.create(name: "first", source_config: "job.yaml")
      manager.set_current(first.id)

      manager.clear_current

      assert_nil manager.current_id
      refute File.symlink?(File.join(cache_dir, ".current"))
    end
  end

  def test_clear_current_falls_back_to_latest
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      first = manager.create(name: "first", source_config: "job.yaml")
      second = manager.create(name: "second", source_config: "job.yaml")

      manager.set_current(first.id)
      manager.clear_current

      active = manager.find_active
      assert_equal second.id, active.id
    end
  end

  def test_current_id_nil_when_no_current
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      manager.create(name: "first", source_config: "job.yaml")

      assert_nil manager.current_id
    end
  end

  # === Delete tests ===

  def test_delete_removes_directory
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      assignment = manager.create(name: "to-delete", source_config: "job.yaml")
      assert File.directory?(assignment.cache_dir)

      result = manager.delete(assignment.id)

      assert_equal true, result
      refute File.directory?(assignment.cache_dir)
    end
  end

  def test_delete_returns_false_for_missing_id
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      result = manager.delete("nonexistent")

      assert_equal false, result
    end
  end

  def test_delete_cleans_up_current_symlink
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      assignment = manager.create(name: "to-delete", source_config: "job.yaml")
      manager.set_current(assignment.id)
      assert File.symlink?(File.join(cache_dir, ".current"))

      manager.delete(assignment.id)

      refute File.symlink?(File.join(cache_dir, ".current"))
    end
  end

  def test_delete_cleans_up_latest_symlink
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      assignment = manager.create(name: "to-delete", source_config: "job.yaml")
      assert File.symlink?(File.join(cache_dir, ".latest"))

      manager.delete(assignment.id)

      refute File.symlink?(File.join(cache_dir, ".latest"))
    end
  end

  def test_delete_preserves_symlinks_pointing_to_other_assignments
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      first = manager.create(name: "keep", source_config: "job.yaml")
      second = manager.create(name: "delete", source_config: "job.yaml")
      manager.set_current(first.id)

      manager.delete(second.id)

      # .current still points to first
      assert File.symlink?(File.join(cache_dir, ".current"))
      assert_equal first.id, manager.current_id
    end
  end

  # === Parent metadata tests ===

  def test_create_with_parent
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      parent = manager.create(name: "parent", source_config: "job.yaml")
      child = manager.create(name: "child", source_config: "job.yaml", parent: parent.id)

      assert_equal parent.id, child.parent
    end
  end

  def test_parent_survives_reload
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      parent = manager.create(name: "parent", source_config: "job.yaml")
      child = manager.create(name: "child", source_config: "job.yaml", parent: parent.id)

      reloaded = manager.load(child.id)

      assert_equal parent.id, reloaded.parent
    end
  end

  def test_parent_nil_when_absent
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      assignment = manager.create(name: "root", source_config: "job.yaml")
      reloaded = manager.load(assignment.id)

      assert_nil reloaded.parent
    end
  end

  def test_parent_preserved_through_update
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      parent = manager.create(name: "parent", source_config: "job.yaml")
      child = manager.create(name: "child", source_config: "job.yaml", parent: parent.id)

      updated = manager.update(child)

      assert_equal parent.id, updated.parent

      reloaded = manager.load(child.id)
      assert_equal parent.id, reloaded.parent
    end
  end

  def test_create_with_task_and_project_attachment
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      assignment = manager.create(
        name: "linked",
        source_config: "job.yaml",
        task_id: "8wr.t.qjl",
        project_id: "ace"
      )
      reloaded = manager.load(assignment.id)

      assert_equal "8wr.t.qjl", reloaded.task_id
      assert_equal "ace", reloaded.project_id
      assert reloaded.managed?
    end
  end

  def test_task_and_project_preserved_through_update
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)

      assignment = manager.create(name: "linked", source_config: "job.yaml", task_id: "148", project_id: "ace")
      updated = manager.update(assignment)

      assert_equal "148", updated.task_id
      assert_equal "ace", updated.project_id

      reloaded = manager.load(assignment.id)
      assert_equal "148", reloaded.task_id
      assert_equal "ace", reloaded.project_id
    end
  end

  def test_attempt_lookup_delegates_to_attempt_store
    with_temp_cache do |cache_dir|
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      assignment = manager.create(name: "linked", source_config: "job.yaml", task_id: "148")

      binding = Ace::Assign::Models::AttemptBinding.new(
        attempt_id: "atmgr01",
        assignment_id: assignment.id,
        scope: "010",
        project_id: "ace",
        actor: "mc",
        role: "coordinator",
        runtime: "local:test",
        base_head: "deadbeef",
        task_id: "148",
        created_at: Time.now.utc
      )
      attempt = Ace::Assign::Models::Attempt.new(binding: binding, state: "running")
      manager.attempt_store.save(attempt)
      manager.attempt_store.with_lock(assignment.id) do
        manager.attempt_store.claim(assignment.id, "010", attempt)
      end

      active = manager.active_attempt(assignment.id, "010")
      assert_equal "atmgr01", active.attempt_id

      listed = manager.attempts(assignment.id)
      assert_equal ["atmgr01"], listed.map(&:attempt_id)

      assert_nil manager.active_attempt(assignment.id, "020")
      assert_empty manager.attempts("8wrnope")
    end
  end
end
