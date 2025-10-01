# frozen_string_literal: true

require_relative "../test_helper"

class TestFactoryTest < AceTaskflowTestCase
  def test_with_clean_project_creates_minimal_structure
    with_clean_project do |dir|
      taskflow_root = File.join(dir, ".ace-taskflow")

      assert Dir.exist?(taskflow_root)
      assert Dir.exist?(File.join(taskflow_root, "backlog"))
      assert Dir.exist?(File.join(taskflow_root, "done"))

      # Should NOT have default v.0.9.0 release
      refute Dir.exist?(File.join(taskflow_root, "v.0.9.0"))
    end
  end

  def test_create_release_with_active_status
    with_clean_project do |dir|
      release_path = TestFactory.create_release(dir, "v.1.0.0", status: "active")

      assert Dir.exist?(release_path)
      assert File.exist?(File.join(release_path, ".active"))
      assert File.exist?(File.join(release_path, "release.md"))
      assert Dir.exist?(File.join(release_path, "t"))
    end
  end

  def test_create_release_with_tasks
    with_clean_project do |dir|
      tasks = [
        { num: "001", status: "pending" },
        { num: "002", status: "done" }
      ]

      TestFactory.create_release(dir, "v.1.0.0", status: "active", tasks: tasks)

      taskflow_root = File.join(dir, ".ace-taskflow")
      assert File.exist?(File.join(taskflow_root, "v.1.0.0", "t", "001", "task.001.md"))
      assert File.exist?(File.join(taskflow_root, "v.1.0.0", "t", "002", "task.002.md"))
    end
  end

  def test_create_known_tasks
    with_clean_project do |dir|
      TestFactory.create_release(dir, "v.1.0.0", status: "active")
      TestFactory.create_known_tasks(dir, "v.1.0.0", ["001", "002", "003"],
                                       statuses: { "001" => "done", "002" => "in-progress" })

      taskflow_root = File.join(dir, ".ace-taskflow")
      task_001_content = File.read(File.join(taskflow_root, "v.1.0.0", "t", "001", "task.001.md"))
      task_002_content = File.read(File.join(taskflow_root, "v.1.0.0", "t", "002", "task.002.md"))

      assert_match(/status: done/, task_001_content)
      assert_match(/status: in-progress/, task_002_content)
    end
  end

  def test_create_known_ideas
    with_clean_project do |dir|
      TestFactory.create_release(dir, "v.1.0.0", status: "active")
      TestFactory.create_known_ideas(dir, "v.1.0.0", 3)

      taskflow_root = File.join(dir, ".ace-taskflow")
      assert File.exist?(File.join(taskflow_root, "v.1.0.0", "i", "001.md"))
      assert File.exist?(File.join(taskflow_root, "v.1.0.0", "i", "002.md"))
      assert File.exist?(File.join(taskflow_root, "v.1.0.0", "i", "003.md"))
    end
  end
end
