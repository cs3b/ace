# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/folder_migrator"

class FolderMigratorTest < AceTaskflowTestCase
  # Helper to create a minimal test directory for migration tests
  # Does NOT create _archive or _backlog folders (so we can test migrating done/backlog)
  def with_minimal_project
    Dir.mktmpdir do |dir|
      taskflow_root = File.join(dir, ".ace-taskflow")
      FileUtils.mkdir_p(taskflow_root)
      yield dir, taskflow_root
    end
  end

  def test_migrates_top_level_done_folder
    with_minimal_project do |_dir, taskflow_root|
      # Create old "done" folder
      done_dir = File.join(taskflow_root, "done")
      FileUtils.mkdir_p(done_dir)
      File.write(File.join(done_dir, "test.txt"), "test content")

      # Run migration
      migrator = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results = migrator.migrate_all

      # Verify migration
      assert_equal 1, results[:total]
      assert_equal 1, results[:migrated].count
      assert_equal 0, results[:errors].count
      assert_equal 0, results[:skipped].count

      # Verify folder was renamed
      archive_dir = File.join(taskflow_root, "_archive")
      assert Dir.exist?(archive_dir), "Should have created _archive folder"
      refute Dir.exist?(done_dir), "Should have removed done folder"
      assert File.exist?(File.join(archive_dir, "test.txt")), "Should have moved contents"
    end
  end

  def test_migrates_top_level_backlog_folder
    with_minimal_project do |_dir, taskflow_root|
      # Create old "backlog" folder
      backlog_dir = File.join(taskflow_root, "backlog")
      FileUtils.mkdir_p(backlog_dir)
      File.write(File.join(backlog_dir, "test.txt"), "test content")

      # Run migration
      migrator = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results = migrator.migrate_all

      # Verify migration
      assert_equal 1, results[:total]
      assert_equal 1, results[:migrated].count

      # Verify folder was renamed
      new_backlog_dir = File.join(taskflow_root, "_backlog")
      assert Dir.exist?(new_backlog_dir), "Should have created _backlog folder"
      refute Dir.exist?(backlog_dir), "Should have removed backlog folder"
      assert File.exist?(File.join(new_backlog_dir, "test.txt")), "Should have moved contents"
    end
  end

  def test_migrates_nested_done_folders_in_releases
    with_minimal_project do |_dir, taskflow_root|
      # Create nested done folders in release
      release_dir = File.join(taskflow_root, "v.0.9.0")
      tasks_done = File.join(release_dir, "tasks", "done")
      ideas_done = File.join(release_dir, "ideas", "done")

      FileUtils.mkdir_p(tasks_done)
      FileUtils.mkdir_p(ideas_done)

      File.write(File.join(tasks_done, "task.txt"), "task content")
      File.write(File.join(ideas_done, "idea.txt"), "idea content")

      # Run migration
      migrator = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results = migrator.migrate_all

      # Verify migration
      assert_equal 2, results[:total]
      assert_equal 2, results[:migrated].count

      # Verify folders were renamed
      tasks_archive = File.join(release_dir, "tasks", "_archive")
      ideas_archive = File.join(release_dir, "ideas", "_archive")

      assert Dir.exist?(tasks_archive), "Should have created tasks/_archive"
      assert Dir.exist?(ideas_archive), "Should have created ideas/_archive"
      refute Dir.exist?(tasks_done), "Should have removed tasks/done"
      refute Dir.exist?(ideas_done), "Should have removed ideas/done"

      assert File.exist?(File.join(tasks_archive, "task.txt")), "Should have moved task content"
      assert File.exist?(File.join(ideas_archive, "idea.txt")), "Should have moved idea content"
    end
  end

  def test_dry_run_does_not_modify_folders
    with_minimal_project do |_dir, taskflow_root|
      # Create old "done" folder
      done_dir = File.join(taskflow_root, "done")
      FileUtils.mkdir_p(done_dir)
      File.write(File.join(done_dir, "test.txt"), "test content")

      # Run migration with dry-run
      migrator = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root, dry_run: true)
      results = migrator.migrate_all

      # Verify it found the folder but didn't migrate
      assert_equal 1, results[:total]
      assert_equal 1, results[:migrated].count

      # Verify folder was NOT renamed
      archive_dir = File.join(taskflow_root, "_archive")
      refute Dir.exist?(archive_dir), "Should NOT have created _archive folder in dry-run"
      assert Dir.exist?(done_dir), "Should NOT have removed done folder in dry-run"
    end
  end

  def test_skips_when_target_exists
    with_minimal_project do |_dir, taskflow_root|
      # Create both old and new folders
      done_dir = File.join(taskflow_root, "done")
      archive_dir = File.join(taskflow_root, "_archive")

      FileUtils.mkdir_p(done_dir)
      FileUtils.mkdir_p(archive_dir)

      File.write(File.join(done_dir, "test.txt"), "test content")
      File.write(File.join(archive_dir, "existing.txt"), "existing content")

      # Run migration
      migrator = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results = migrator.migrate_all

      # Verify it was skipped
      assert_equal 1, results[:total]
      assert_equal 0, results[:migrated].count
      assert_equal 1, results[:skipped].count

      # Verify both folders still exist
      assert Dir.exist?(done_dir), "Original folder should still exist"
      assert Dir.exist?(archive_dir), "Target folder should still exist"
      assert File.exist?(File.join(archive_dir, "existing.txt")), "Existing content preserved"
    end
  end

  def test_idempotent_running_twice_has_no_effect
    with_minimal_project do |_dir, taskflow_root|
      # Create old "done" folder
      done_dir = File.join(taskflow_root, "done")
      FileUtils.mkdir_p(done_dir)
      File.write(File.join(done_dir, "test.txt"), "test content")

      # Run migration first time
      migrator1 = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results1 = migrator1.migrate_all

      assert_equal 1, results1[:total]
      assert_equal 1, results1[:migrated].count

      # Run migration second time
      migrator2 = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results2 = migrator2.migrate_all

      # Should find no folders to migrate
      assert_equal 0, results2[:total]
      assert_equal 0, results2[:migrated].count
      assert_equal 0, results2[:skipped].count
    end
  end

  def test_migrates_multiple_folders_at_once
    with_minimal_project do |_dir, taskflow_root|
      # Create multiple old folders
      done_dir = File.join(taskflow_root, "done")
      backlog_dir = File.join(taskflow_root, "backlog")

      FileUtils.mkdir_p(done_dir)
      FileUtils.mkdir_p(backlog_dir)

      File.write(File.join(done_dir, "done.txt"), "done content")
      File.write(File.join(backlog_dir, "backlog.txt"), "backlog content")

      # Also create nested folders
      release_dir = File.join(taskflow_root, "v.0.9.0")
      tasks_done = File.join(release_dir, "tasks", "done")
      FileUtils.mkdir_p(tasks_done)
      File.write(File.join(tasks_done, "task.txt"), "task content")

      # Run migration
      migrator = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results = migrator.migrate_all

      # Verify all migrations
      assert_equal 3, results[:total]
      assert_equal 3, results[:migrated].count
      assert_equal 0, results[:errors].count

      # Verify all folders were renamed
      assert Dir.exist?(File.join(taskflow_root, "_archive"))
      assert Dir.exist?(File.join(taskflow_root, "_backlog"))
      assert Dir.exist?(File.join(release_dir, "tasks", "_archive"))

      refute Dir.exist?(done_dir)
      refute Dir.exist?(backlog_dir)
      refute Dir.exist?(tasks_done)
    end
  end

  def test_handles_releases_within_backlog
    with_minimal_project do |_dir, taskflow_root|
      # Create _backlog (new format) with nested release containing old done folders
      # This tests that migration works on releases inside the already-migrated backlog
      backlog_dir = File.join(taskflow_root, "_backlog")
      release_dir = File.join(backlog_dir, "v.1.0.0")
      tasks_done = File.join(release_dir, "tasks", "done")

      FileUtils.mkdir_p(tasks_done)
      File.write(File.join(tasks_done, "task.txt"), "task content")

      # Run migration
      migrator = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results = migrator.migrate_all

      # Verify nested done folder was found and migrated
      assert results[:total] >= 1, "Should find nested done folder"

      tasks_archive = File.join(release_dir, "tasks", "_archive")
      assert Dir.exist?(tasks_archive), "Should have created nested _archive"
      assert File.exist?(File.join(tasks_archive, "task.txt")), "Should have moved content"
    end
  end

  def test_no_folders_to_migrate
    with_minimal_project do |_dir, taskflow_root|
      # Create only new-style folders
      archive_dir = File.join(taskflow_root, "_archive")
      backlog_dir = File.join(taskflow_root, "_backlog")

      FileUtils.mkdir_p(archive_dir)
      FileUtils.mkdir_p(backlog_dir)

      # Run migration
      migrator = Ace::Taskflow::Organisms::FolderMigrator.new(taskflow_root)
      results = migrator.migrate_all

      # Should find nothing to migrate
      assert_equal 0, results[:total]
      assert_equal 0, results[:migrated].count
      assert_equal 0, results[:skipped].count
      assert_equal 0, results[:errors].count
    end
  end
end
