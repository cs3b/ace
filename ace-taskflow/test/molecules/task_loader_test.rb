# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_loader"

class TaskLoaderTest < AceTaskflowTestCase
  def setup
    @loader = Ace::Taskflow::Molecules::TaskLoader.new
  end

  def test_load_task_from_file
    with_test_project do |dir|
      Dir.chdir(dir) do
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "001", "task.001.s.md")
        task = @loader.load_task(task_file)

        assert task
        assert_equal "v.0.9.0+task.001", task[:id]
        assert_equal "done", task[:status]
        assert_equal "medium", task[:priority]
      end
    end
  end

  def test_load_all_tasks_from_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create loader inside test block to use correct root path
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        tasks = loader.load_tasks_from_release(release_path)

        assert_equal 5, tasks.length
        assert tasks.all? { |t| t[:id].start_with?("v.0.9.0+task") }
      end
    end
  end

  def test_load_tasks_with_filter
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create loader inside test block to use correct root path
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        all_tasks = loader.load_tasks_from_release(release_path)
        pending_tasks = all_tasks.select { |task| task[:status] == "pending" }

        assert_equal 3, pending_tasks.length
        assert pending_tasks.all? { |t| t[:status] == "pending" }
      end
    end
  end

  def test_parse_task_metadata
    content = TestFactory.sample_task_content
    metadata = @loader.parse_metadata(content)

    assert metadata
    assert_equal "v.0.9.0+task.001", metadata[:id]
    assert_equal "pending", metadata[:status]
    assert_equal "medium", metadata[:priority]
    assert_equal "4h", metadata[:estimate]
    assert_equal [], metadata[:dependencies]
    assert_equal 100, metadata[:sort]
  end

  def test_load_invalid_task_file
    invalid_file = "/tmp/nonexistent_#{Process.pid}.md"
    task = @loader.load_task(invalid_file)

    assert_nil task
  end

  def test_load_malformed_task
    with_test_project do |dir|
      malformed_file = File.join(dir, "malformed.md")
      File.write(malformed_file, "This is not a valid task file")

      Dir.chdir(dir) do
        task = @loader.load_task(malformed_file)

        # Should handle gracefully
        assert_nil task[:id] if task
      end
    end
  end

  def test_extract_task_title
    # extract_title expects body content (without frontmatter)
    body_content = <<~CONTENT
      # This is the Task Title

      Description here
    CONTENT

    title = @loader.extract_title(body_content)
    assert_equal "This is the Task Title", title
  end

  def test_validate_task_structure
    valid_task = {
      id: "v.0.9.0+task.001",
      status: "pending",
      priority: "high"
    }

    assert @loader.valid_task?(valid_task)

    invalid_task = { status: "pending" } # Missing ID
    refute @loader.valid_task?(invalid_task)
  end

  # Test DocumentEditor-based status updates (frontmatter safety)
  def test_update_task_status_preserves_frontmatter
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create a task file with comprehensive frontmatter
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "099", "task.099.s.md")
        FileUtils.mkdir_p(File.dirname(task_file))
        File.write(task_file, <<~CONTENT)
          ---
          id: v.0.9.0+task.099
          status: pending
          priority: high
          estimate: 4h
          dependencies: []
          sort: 999
          custom_field: custom value
          ---

          # Test Task

          ## Description
          Task for testing frontmatter preservation
        CONTENT

        # Update status
        result = @loader.update_task_status(task_file, "in-progress")
        assert result, "Status update should succeed"

        # Verify file still exists and is readable
        assert File.exist?(task_file), "Task file should still exist"

        # Load and verify content
        updated_content = File.read(task_file)

        # Verify frontmatter is intact
        assert_match(/^---/, updated_content, "Frontmatter should start with ---")
        assert_match(/^id: v\.0\.9\.0\+task\.099/, updated_content, "ID should be preserved")
        assert_match(/^status: in-progress/, updated_content, "Status should be updated")
        assert_match(/^priority: high/, updated_content, "Priority should be preserved")
        assert_match(/^estimate: 4h/, updated_content, "Estimate should be preserved")
        assert_match(/^dependencies: \[\]/, updated_content, "Dependencies should be preserved")
        assert_match(/^sort: 999/, updated_content, "Sort should be preserved")
        assert_match(/^custom_field: custom value/, updated_content, "Custom fields should be preserved")

        # Verify body content is intact
        assert_match(/# Test Task/, updated_content, "Heading should be preserved")
        assert_match(/## Description/, updated_content, "Section should be preserved")

        # Verify file is NOT corrupted (should be more than 3 lines)
        line_count = updated_content.lines.count
        assert line_count > 10, "File should not be corrupted (has #{line_count} lines, expected > 10)"
      end
    end
  end

  def test_update_task_dependencies_preserves_frontmatter
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create a task file
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "098", "task.098.s.md")
        FileUtils.mkdir_p(File.dirname(task_file))
        File.write(task_file, <<~CONTENT)
          ---
          id: v.0.9.0+task.098
          status: pending
          priority: medium
          estimate: 2h
          dependencies: []
          sort: 998
          ---

          # Dependency Test Task

          Testing dependency updates
        CONTENT

        # Update dependencies
        new_deps = ["v.0.9.0+task.001", "v.0.9.0+task.002"]
        result = @loader.update_task_dependencies(task_file, new_deps)
        assert result, "Dependency update should succeed"

        # Load and verify content
        updated_content = File.read(task_file)

        # Verify dependencies are updated
        assert_match(/^dependencies:/, updated_content, "Dependencies field should exist")
        assert_match(/v\.0\.9\.0\+task\.001/, updated_content, "First dependency should be present")
        assert_match(/v\.0\.9\.0\+task\.002/, updated_content, "Second dependency should be present")

        # Verify other frontmatter is preserved
        assert_match(/^status: pending/, updated_content, "Status should be preserved")
        assert_match(/^priority: medium/, updated_content, "Priority should be preserved")

        # Verify file is not corrupted
        line_count = updated_content.lines.count
        assert line_count > 10, "File should not be corrupted (has #{line_count} lines)"
      end
    end
  end

  def test_update_task_status_creates_backup
    with_test_project do |dir|
      Dir.chdir(dir) do
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "097", "task.097.s.md")
        FileUtils.mkdir_p(File.dirname(task_file))
        original_content = TestFactory.sample_task_content(id: "v.0.9.0+task.097", status: "pending")
        File.write(task_file, original_content)

        # Update status
        result = @loader.update_task_status(task_file, "done")
        assert result, "Status update should succeed"

        # Verify backup was created (DocumentEditor creates .backup files)
        backup_files = Dir.glob("#{task_file}.backup*")
        assert backup_files.any?, "Backup file should be created"
      end
    end
  end

  def test_update_task_status_handles_invalid_file
    result = @loader.update_task_status("/nonexistent/file.md", "done")
    refute result, "Should return false for nonexistent file"
  end

  # ========== Hierarchical Task Tests (Subtask Support) ==========

  def test_classify_task_file_orchestrator_is_now_single
    # After removing .00 suffix, orchestrator files use NNN-orchestrator.s.md pattern
    # which classifies as :single. Promotion to orchestrator happens via build_task_relationships.
    loader = Ace::Taskflow::Molecules::TaskLoader.new
    assert_equal :single, loader.send(:classify_task_file, "121-orchestrator.s.md")
    assert_equal :single, loader.send(:classify_task_file, "001-main.s.md")
  end

  def test_classify_task_file_subtask
    loader = Ace::Taskflow::Molecules::TaskLoader.new
    assert_equal :subtask, loader.send(:classify_task_file, "121.01-archive.s.md")
    assert_equal :subtask, loader.send(:classify_task_file, "121.99-final.s.md")
    assert_equal :subtask, loader.send(:classify_task_file, "001.05-feature.s.md")
  end

  def test_classify_task_file_single
    loader = Ace::Taskflow::Molecules::TaskLoader.new
    assert_equal :single, loader.send(:classify_task_file, "119-feature.s.md")
    assert_equal :single, loader.send(:classify_task_file, "001-task.s.md")
  end

  def test_classify_task_file_unknown
    loader = Ace::Taskflow::Molecules::TaskLoader.new
    assert_equal :unknown, loader.send(:classify_task_file, "task.001.s.md")
    assert_equal :unknown, loader.send(:classify_task_file, "README.md")
  end

  def test_extract_parent_number
    loader = Ace::Taskflow::Molecules::TaskLoader.new
    assert_equal "121", loader.send(:extract_parent_number, "121.01-archive.s.md")
    # Orchestrator files (NNN-orchestrator.s.md) no longer match subtask pattern
    assert_nil loader.send(:extract_parent_number, "121-orchestrator.s.md")
    assert_nil loader.send(:extract_parent_number, "119-feature.s.md")
  end

  def test_extract_subtask_number
    loader = Ace::Taskflow::Molecules::TaskLoader.new
    assert_equal "01", loader.send(:extract_subtask_number, "121.01-archive.s.md")
    # Orchestrator files no longer use .00 pattern
    assert_nil loader.send(:extract_subtask_number, "121-orchestrator.s.md")
    assert_nil loader.send(:extract_subtask_number, "119-feature.s.md")
  end

  def test_load_task_includes_hierarchical_fields
    with_test_project do |dir|
      Dir.chdir(dir) do
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "001", "task.001.s.md")
        task = @loader.load_task(task_file)

        assert task
        # Should have hierarchical fields
        assert_includes task.keys, :parent_id
        assert_includes task.keys, :subtask_ids
        assert_includes task.keys, :is_orchestrator
        assert_includes task.keys, :file_type
      end
    end
  end

  def test_load_orchestrator_with_subtasks
    with_hierarchical_project do |dir|
      Dir.chdir(dir) do
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        tasks = loader.load_tasks_from_release(release_path)

        # Find orchestrator (now classified as :single, promoted by build_task_relationships)
        orchestrator = tasks.find { |t| t[:is_orchestrator] }
        assert orchestrator, "Should find orchestrator"
        assert orchestrator[:is_orchestrator], "Orchestrator should be marked as orchestrator"
        # Orchestrator files use NNN-orchestrator.s.md which classifies as :single
        assert_equal :single, orchestrator[:file_type]

        # Orchestrator should have subtask_ids populated
        refute_empty orchestrator[:subtask_ids], "Orchestrator should have subtask_ids"
      end
    end
  end

  def test_load_subtasks_have_parent_id
    with_hierarchical_project do |dir|
      Dir.chdir(dir) do
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        tasks = loader.load_tasks_from_release(release_path)

        # Find subtasks
        subtasks = tasks.select { |t| t[:file_type] == :subtask }
        assert subtasks.length >= 2, "Should find at least 2 subtasks"

        subtasks.each do |subtask|
          assert subtask[:parent_id], "Subtask should have parent_id"
          assert_equal :subtask, subtask[:file_type]
        end
      end
    end
  end

  # ========== find_task_by_reference Tests ==========
  # These tests verify hierarchical lookup through find_task_by_reference

  def test_find_task_by_reference_returns_orchestrator
    with_hierarchical_project do |dir|
      Dir.chdir(dir) do
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))

        # Preload tasks since find_task_by_reference uses load_all_tasks
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        tasks = loader.load_tasks_from_release(release_path)

        # Simple reference should find orchestrator
        task = loader.find_task_by_reference("121", tasks: tasks)
        assert task, "Should find task by simple reference"
        assert_equal "v.0.9.0+task.121", task[:id]
        assert task[:is_orchestrator], "Should return orchestrator for simple ref"
      end
    end
  end

  def test_find_task_by_reference_returns_subtask
    with_hierarchical_project do |dir|
      Dir.chdir(dir) do
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))

        # Preload tasks
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        tasks = loader.load_tasks_from_release(release_path)

        # Subtask reference
        subtask = loader.find_task_by_reference("121.01", tasks: tasks)
        assert subtask, "Should find subtask by reference"
        assert_equal "v.0.9.0+task.121.01", subtask[:id]
        assert_equal :subtask, subtask[:file_type]
      end
    end
  end

  def test_subtask_ids_syncs_with_actual_files
    # Test that subtask_ids includes both frontmatter and discovered subtasks
    # by modifying an existing test project
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        # Create test project structure
        taskflow_root = File.join(dir, ".ace-taskflow")
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), <<~YAML)
          taskflow:
            root: .ace-taskflow
            task_dir: t
          YAML

        # Create release directory
        release_dir = File.join(taskflow_root, "v.0.9.0")
        FileUtils.mkdir_p(release_dir)
        File.write(File.join(release_dir, ".active"), "")

        # Create orchestrator with explicit frontmatter subtasks
        orchestrator_dir = File.join(release_dir, "t", "999-test-orchestrator")
        FileUtils.mkdir_p(orchestrator_dir)

        orchestrator_content = <<~CONTENT
---
id: v.0.9.0+task.999
status: in-progress
priority: medium
subtasks:
  - v.0.9.0+task.999.01
  - v.0.9.0+task.999.02
---

# 999 - Test Orchestrator
        CONTENT
        File.write(File.join(orchestrator_dir, "999-orchestrator.s.md"), orchestrator_content)

        # Add subtask files (including one not in frontmatter)
        subtask01_content = <<~CONTENT
---
id: v.0.9.0+task.999.01
status: pending
parent: v.0.9.0+task.999
---

# 999.01 - First Subtask
        CONTENT
        File.write(File.join(orchestrator_dir, "999.01-first-subtask.s.md"), subtask01_content)

        subtask02_content = <<~CONTENT
---
id: v.0.9.0+task.999.02
status: pending
parent: v.0.9.0+task.999
---

# 999.02 - Second Subtask
        CONTENT
        File.write(File.join(orchestrator_dir, "999.02-second-subtask.s.md"), subtask02_content)

        # This subtask is NOT in frontmatter but exists as file
        subtask03_content = <<~CONTENT
---
id: v.0.9.0+task.999.03
status: pending
parent: v.0.9.0+task.999
---

# 999.03 - Third Subtask (not in frontmatter)
        CONTENT
        File.write(File.join(orchestrator_dir, "999.03-third-subtask.s.md"), subtask03_content)

        Dir.chdir(dir) do
          loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))
          release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
          tasks = loader.load_tasks_from_release(release_path)

          # Find the orchestrator
          orchestrator = tasks.find { |t| t[:id] == "v.0.9.0+task.999" }
          assert orchestrator, "Should find orchestrator"
          assert_equal true, orchestrator[:is_orchestrator]

          # subtask_ids should include ALL subtasks (frontmatter + discovered)
          expected_ids = [
            "v.0.9.0+task.999.01",  # In frontmatter and file
            "v.0.9.0+task.999.02",  # In frontmatter and file
            "v.0.9.0+task.999.03"   # Only in file, not in frontmatter
          ]
          assert_equal expected_ids, orchestrator[:subtask_ids].sort
        end
      end
    end
  end

  def test_subtask_ids_deduplicates_mixed_short_and_full_ids
    # When frontmatter uses short IDs (e.g., "999.02") alongside full IDs,
    # they should be normalized and deduplicated against discovered file IDs
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        taskflow_root = File.join(dir, ".ace-taskflow")
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), <<~YAML)
          taskflow:
            root: .ace-taskflow
            task_dir: t
        YAML

        release_dir = File.join(taskflow_root, "v.0.9.0")
        FileUtils.mkdir_p(release_dir)
        File.write(File.join(release_dir, ".active"), "")

        orchestrator_dir = File.join(release_dir, "t", "999-test-dedup")
        FileUtils.mkdir_p(orchestrator_dir)

        # Frontmatter mixes short ID (999.02) with full ID (v.0.9.0+task.999.01)
        orchestrator_content = <<~CONTENT
---
id: v.0.9.0+task.999
status: in-progress
priority: medium
subtasks:
  - v.0.9.0+task.999.01
  - 999.02
---

# 999 - Test Dedup Orchestrator
        CONTENT
        File.write(File.join(orchestrator_dir, "999-orchestrator.s.md"), orchestrator_content)

        subtask01_content = <<~CONTENT
---
id: v.0.9.0+task.999.01
status: pending
parent: v.0.9.0+task.999
---

# 999.01 - First Subtask
        CONTENT
        File.write(File.join(orchestrator_dir, "999.01-first-subtask.s.md"), subtask01_content)

        subtask02_content = <<~CONTENT
---
id: v.0.9.0+task.999.02
status: pending
parent: v.0.9.0+task.999
---

# 999.02 - Second Subtask
        CONTENT
        File.write(File.join(orchestrator_dir, "999.02-second-subtask.s.md"), subtask02_content)

        Dir.chdir(dir) do
          loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))
          release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
          tasks = loader.load_tasks_from_release(release_path)

          orchestrator = tasks.find { |t| t[:id] == "v.0.9.0+task.999" }
          assert orchestrator, "Should find orchestrator"

          # Each subtask should appear exactly once despite mixed ID formats in frontmatter
          expected_ids = ["v.0.9.0+task.999.01", "v.0.9.0+task.999.02"]
          assert_equal expected_ids, orchestrator[:subtask_ids].sort,
            "Short and full IDs should be deduplicated to canonical form"
        end
      end
    end
  end

  def test_find_task_by_reference_with_qualified_ref
    with_hierarchical_project do |dir|
      Dir.chdir(dir) do
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))

        # Preload tasks
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        tasks = loader.load_tasks_from_release(release_path)

        # Qualified reference
        task = loader.find_task_by_reference("v.0.9.0+task.121.01", tasks: tasks)
        assert task, "Should find by qualified reference"
        assert_equal "v.0.9.0+task.121.01", task[:id]
      end
    end
  end

  def test_find_task_by_reference_unknown_returns_nil
    with_hierarchical_project do |dir|
      Dir.chdir(dir) do
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))

        # Preload tasks
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        tasks = loader.load_tasks_from_release(release_path)

        task = loader.find_task_by_reference("999", tasks: tasks)
        assert_nil task, "Should return nil for unknown reference"
      end
    end
  end

  def test_derive_parent_id_uses_canonical_id_not_path
    with_hierarchical_project do |dir|
      Dir.chdir(dir) do
        loader = Ace::Taskflow::Molecules::TaskLoader.new(File.join(dir, ".ace-taskflow"))

        # Simulate an archived subtask with :release = "done" but :id still canonical
        subtask = {
          id: "v.0.9.0+task.121.01",
          release: "done",  # This is what PathBuilder returns for archived tasks
          path: "somewhere/_archive/121-test/121.01-subtask.s.md"
        }

        parent_id = loader.send(:derive_parent_id, subtask, "121")

        # Should use release from :id, not from :release field
        assert_equal "v.0.9.0+task.121", parent_id
        refute_equal "done+task.121", parent_id
      end
    end
  end

  private

  # Create a test project with hierarchical tasks (orchestrator + subtasks)
  def with_hierarchical_project
    Dir.mktmpdir do |dir|
      # Create directory structure (use "t" as default task directory when no config exists)
      task_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-hierarchical-test")
      FileUtils.mkdir_p(task_dir)

      # Create orchestrator file
      orchestrator_content = <<~CONTENT
---
id: v.0.9.0+task.121
status: in-progress
priority: high
estimate: 8h
dependencies: []
subtasks:
  - v.0.9.0+task.121.01
  - v.0.9.0+task.121.02
---

# 121 - Hierarchical Test Task (Orchestrator)

This is the orchestrator task.
      CONTENT
      File.write(File.join(task_dir, "121-orchestrator.s.md"), orchestrator_content)

      # Create subtask 01
      subtask01_content = <<~CONTENT
---
id: v.0.9.0+task.121.01
status: pending
priority: high
estimate: 2h
dependencies: []
parent: v.0.9.0+task.121
---

# 121.01 - First Subtask

First subtask description.
      CONTENT
      File.write(File.join(task_dir, "121.01-first-subtask.s.md"), subtask01_content)

      # Create subtask 02
      subtask02_content = <<~CONTENT
---
id: v.0.9.0+task.121.02
status: pending
priority: medium
estimate: 3h
dependencies:
  - v.0.9.0+task.121.01
parent: v.0.9.0+task.121
---

# 121.02 - Second Subtask

Second subtask description.
      CONTENT
      File.write(File.join(task_dir, "121.02-second-subtask.s.md"), subtask02_content)

      yield dir
    end
  end
end