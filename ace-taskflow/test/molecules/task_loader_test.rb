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
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "tasks", "001", "task.001.s.md")
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
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        tasks = @loader.load_tasks_from_release(release_path)

        assert_equal 5, tasks.length
        assert tasks.all? { |t| t[:id].start_with?("v.0.9.0+task") }
      end
    end
  end

  def test_load_tasks_with_filter
    with_test_project do |dir|
      Dir.chdir(dir) do
        release_path = File.join(dir, ".ace-taskflow", "v.0.9.0")
        all_tasks = @loader.load_tasks_from_release(release_path)
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
    with_test_project do |dir|
      Dir.chdir(dir) do
        invalid_file = File.join(dir, "nonexistent.md")
        task = @loader.load_task(invalid_file)

        assert_nil task
      end
    end
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
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "tasks", "099", "task.099.s.md")
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
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "tasks", "098", "task.098.s.md")
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
        task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "tasks", "097", "task.097.s.md")
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
end