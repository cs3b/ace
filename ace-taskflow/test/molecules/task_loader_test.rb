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
        task_file = File.join(dir, "v.0.9.0", "t", "001", "task.md")
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
        tasks = @loader.load_all_tasks("v.0.9.0")

        assert_equal 5, tasks.length
        assert tasks.all? { |t| t[:id].start_with?("v.0.9.0+task") }
      end
    end
  end

  def test_load_tasks_with_filter
    with_test_project do |dir|
      Dir.chdir(dir) do
        pending_tasks = @loader.load_all_tasks("v.0.9.0") do |task|
          task[:status] == "pending"
        end

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
    content = <<~CONTENT
      ---
      id: test
      ---

      # This is the Task Title

      Description here
    CONTENT

    title = @loader.extract_title(content)
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
end