# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe CodingAgentTools::Organisms::TaskManagement::TaskManager do
  let(:temp_dir) { Dir.mktmpdir }
  let(:task_manager) { described_class.new(base_path: temp_dir) }

  # Helper to create a mock task file
  def create_task_file(path, id:, status:, title: "Test Task", dependencies: [])
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir)

    deps_yaml = if dependencies.is_a?(Array)
      dependencies.empty? ? "[]" : "[#{dependencies.map { |d| "\"#{d}\"" }.join(", ")}]"
    else
      dependencies.to_s
    end

    content = <<~TASK
      ---
      id: #{id}
      status: #{status}
      priority: high
      estimate: 5h
      dependencies: #{deps_yaml}
      ---
      
      # #{title}
      
      ## Objective
      Test task for unit testing
    TASK

    File.write(path, content)
  end

  # Helper to create a release directory structure
  def create_release_structure(release_name = "v.0.1.0-test")
    release_dir = File.join(temp_dir, "dev-taskflow", "current", release_name)
    tasks_dir = File.join(release_dir, "tasks")
    FileUtils.mkdir_p(tasks_dir)

    {release_dir: release_dir, tasks_dir: tasks_dir}
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "initializes with default base path" do
      manager = described_class.new
      expect(manager).to be_a(described_class)
    end

    it "initializes with custom base path" do
      manager = described_class.new(base_path: "/custom/path")
      expect(manager).to be_a(described_class)
    end
  end

  describe "#find_next_task" do
    context "with valid release structure" do
      let(:structure) { create_release_structure }

      it "finds next actionable task" do
        # Create tasks with dependencies
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "pending",
          title: "First Task"
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task2.md"),
          id: "v.0.1.0+task.2",
          status: "pending",
          title: "Second Task",
          dependencies: ["v.0.1.0+task.1"]
        )

        result = task_manager.find_next_task
        expect(result.success?).to be true
        expect(result.found?).to be true
        expect(result.task.id).to eq("v.0.1.0+task.1")
        expect(result.task.title).to eq("First Task")
      end

      it "prioritizes in-progress tasks over pending" do
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "pending",
          title: "Pending Task"
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task2.md"),
          id: "v.0.1.0+task.2",
          status: "in-progress",
          title: "In Progress Task"
        )

        result = task_manager.find_next_task

        expect(result.success?).to be true
        expect(result.task.id).to eq("v.0.1.0+task.2")
        expect(result.task.status).to eq("in-progress")
      end

      it "respects task sequential ordering" do
        create_task_file(
          File.join(structure[:tasks_dir], "task3.md"),
          id: "v.0.1.0+task.3",
          status: "pending",
          title: "Third Task"
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "pending",
          title: "First Task"
        )

        result = task_manager.find_next_task

        expect(result.success?).to be true
        expect(result.task.id).to eq("v.0.1.0+task.1")
      end

      it "skips done tasks" do
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "done",
          title: "Done Task"
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task2.md"),
          id: "v.0.1.0+task.2",
          status: "pending",
          title: "Pending Task"
        )

        result = task_manager.find_next_task

        expect(result.success?).to be true
        expect(result.task.id).to eq("v.0.1.0+task.2")
      end

      it "handles unmet dependencies" do
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "pending",
          title: "First Task"
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task2.md"),
          id: "v.0.1.0+task.2",
          status: "pending",
          title: "Second Task",
          dependencies: ["v.0.1.0+task.1"]
        )

        result = task_manager.find_next_task

        expect(result.success?).to be true
        expect(result.task.id).to eq("v.0.1.0+task.1")
      end

      it "returns message when no actionable tasks found" do
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "done",
          title: "Done Task"
        )

        result = task_manager.find_next_task

        expect(result.success?).to be true
        expect(result.found?).to be false
        expect(result.message).to eq("No actionable tasks found")
      end
    end

    context "with invalid release structure" do
      it "returns error when no release directory found" do
        result = task_manager.find_next_task

        expect(result.success?).to be false
        expect(result.message).to include("No current release directory found")
      end
    end
  end

  describe "#find_recent_tasks" do
    let(:structure) { create_release_structure }

    it "finds recent tasks within time window" do
      # Create task files
      task1_path = File.join(structure[:tasks_dir], "task1.md")
      task2_path = File.join(structure[:tasks_dir], "task2.md")

      create_task_file(task1_path, id: "v.0.1.0+task.1", status: "done", title: "Done Task")
      create_task_file(task2_path, id: "v.0.1.0+task.2", status: "in-progress", title: "In Progress Task")

      # Set modification times (simulate recent updates)
      recent_time = Time.now - 1800  # 30 minutes ago
      File.utime(recent_time, recent_time, task1_path)
      File.utime(recent_time, recent_time, task2_path)

      result = task_manager.find_recent_tasks(since_seconds: 3600)  # 1 hour

      expect(result.success?).to be true
      expect(result.count).to eq(2)
      expect(result.tasks.map(&:id)).to contain_exactly("v.0.1.0+task.1", "v.0.1.0+task.2")
    end

    it "filters by status" do
      task1_path = File.join(structure[:tasks_dir], "task1.md")
      task2_path = File.join(structure[:tasks_dir], "task2.md")

      create_task_file(task1_path, id: "v.0.1.0+task.1", status: "done", title: "Done Task")
      create_task_file(task2_path, id: "v.0.1.0+task.2", status: "pending", title: "Pending Task")

      recent_time = Time.now - 1800
      File.utime(recent_time, recent_time, task1_path)
      File.utime(recent_time, recent_time, task2_path)

      result = task_manager.find_recent_tasks(since_seconds: 3600, statuses: ["done"])

      expect(result.success?).to be true
      expect(result.count).to eq(1)
      expect(result.tasks.first.id).to eq("v.0.1.0+task.1")
    end

    it "excludes tasks outside time window" do
      task_path = File.join(structure[:tasks_dir], "task1.md")
      create_task_file(task_path, id: "v.0.1.0+task.1", status: "done", title: "Old Task")

      # Set modification time to 2 hours ago
      old_time = Time.now - 7200
      File.utime(old_time, old_time, task_path)

      result = task_manager.find_recent_tasks(since_seconds: 3600)  # 1 hour

      expect(result.success?).to be true
      expect(result.count).to eq(0)
    end

    it "sorts by modification time (newest first)" do
      task1_path = File.join(structure[:tasks_dir], "task1.md")
      task2_path = File.join(structure[:tasks_dir], "task2.md")

      create_task_file(task1_path, id: "v.0.1.0+task.1", status: "done", title: "Older Task")
      create_task_file(task2_path, id: "v.0.1.0+task.2", status: "done", title: "Newer Task")

      older_time = Time.now - 3600  # 1 hour ago
      newer_time = Time.now - 1800  # 30 minutes ago

      File.utime(older_time, older_time, task1_path)
      File.utime(newer_time, newer_time, task2_path)

      result = task_manager.find_recent_tasks(since_seconds: 7200)  # 2 hours

      expect(result.success?).to be true
      expect(result.tasks.first.id).to eq("v.0.1.0+task.2")  # Newer task first
      expect(result.tasks.last.id).to eq("v.0.1.0+task.1")   # Older task last
    end
  end

  describe "#get_all_tasks" do
    let(:structure) { create_release_structure }

    it "returns all tasks in topological order" do
      create_task_file(
        File.join(structure[:tasks_dir], "task1.md"),
        id: "v.0.1.0+task.1",
        status: "done",
        title: "First Task"
      )
      create_task_file(
        File.join(structure[:tasks_dir], "task2.md"),
        id: "v.0.1.0+task.2",
        status: "pending",
        title: "Second Task",
        dependencies: ["v.0.1.0+task.1"]
      )
      create_task_file(
        File.join(structure[:tasks_dir], "task3.md"),
        id: "v.0.1.0+task.3",
        status: "pending",
        title: "Third Task",
        dependencies: ["v.0.1.0+task.2"]
      )

      result = task_manager.get_all_tasks

      expect(result.success?).to be true
      expect(result.fully_sorted?).to be true
      expect(result.tasks.map(&:id)).to eq(["v.0.1.0+task.1", "v.0.1.0+task.2", "v.0.1.0+task.3"])
    end

    it "handles tasks without dependencies" do
      create_task_file(
        File.join(structure[:tasks_dir], "task2.md"),
        id: "v.0.1.0+task.2",
        status: "pending",
        title: "Second Task"
      )
      create_task_file(
        File.join(structure[:tasks_dir], "task1.md"),
        id: "v.0.1.0+task.1",
        status: "pending",
        title: "First Task"
      )

      result = task_manager.get_all_tasks

      expect(result.success?).to be true
      expect(result.fully_sorted?).to be true
      # Should be sorted by task number
      expect(result.tasks.map(&:id)).to eq(["v.0.1.0+task.1", "v.0.1.0+task.2"])
    end

    context "cycle detection" do
      it "detects circular dependencies" do
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "pending",
          title: "First Task",
          dependencies: ["v.0.1.0+task.2"]
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task2.md"),
          id: "v.0.1.0+task.2",
          status: "pending",
          title: "Second Task",
          dependencies: ["v.0.1.0+task.1"]
        )

        result = task_manager.get_all_tasks

        expect(result.success?).to be true
        expect(result.has_cycles?).to be true
        expect(result.fully_sorted?).to be false
        expect(result.sorted_count).to be < result.total_count
      end

      it "handles complex dependency chains" do
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "pending",
          title: "First Task"
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task2.md"),
          id: "v.0.1.0+task.2",
          status: "pending",
          title: "Second Task",
          dependencies: ["v.0.1.0+task.1"]
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task3.md"),
          id: "v.0.1.0+task.3",
          status: "pending",
          title: "Third Task",
          dependencies: ["v.0.1.0+task.1", "v.0.1.0+task.2"]
        )

        result = task_manager.get_all_tasks

        expect(result.success?).to be true
        expect(result.has_cycles?).to be false
        expect(result.fully_sorted?).to be true

        # Task 1 should come first, then task 2, then task 3
        task_ids = result.tasks.map(&:id)
        expect(task_ids.index("v.0.1.0+task.1")).to be < task_ids.index("v.0.1.0+task.2")
        expect(task_ids.index("v.0.1.0+task.2")).to be < task_ids.index("v.0.1.0+task.3")
      end
    end
  end

  describe "#find_next_actionable_task_with_highlight" do
    let(:structure) { create_release_structure }

    it "adds highlight information to next actionable task" do
      create_task_file(
        File.join(structure[:tasks_dir], "task1.md"),
        id: "v.0.1.0+task.1",
        status: "pending",
        title: "Next Task"
      )

      result = task_manager.find_next_actionable_task_with_highlight

      expect(result.success?).to be true
      expect(result.found?).to be true
      expect(result.task.is_next_actionable?).to be true
    end
  end

  describe "integration with embedded tests" do
    context "Next Task Finding" do
      let(:structure) { create_release_structure }

      it "finds correct next actionable task" do
        # Create a complex dependency scenario
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "done",
          title: "Done Task"
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task2.md"),
          id: "v.0.1.0+task.2",
          status: "pending",
          title: "Next Task",
          dependencies: ["v.0.1.0+task.1"]
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task3.md"),
          id: "v.0.1.0+task.3",
          status: "pending",
          title: "Blocked Task",
          dependencies: ["v.0.1.0+task.2"]
        )

        result = task_manager.find_next_task

        expect(result.success?).to be true
        expect(result.found?).to be true
        expect(result.task.id).to eq("v.0.1.0+task.2")
        expect(result.task.title).to eq("Next Task")
      end
    end

    context "Cycle Detection" do
      let(:structure) { create_release_structure }

      it "detects circular dependencies" do
        create_task_file(
          File.join(structure[:tasks_dir], "task1.md"),
          id: "v.0.1.0+task.1",
          status: "pending",
          title: "First Task",
          dependencies: ["v.0.1.0+task.3"]
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task2.md"),
          id: "v.0.1.0+task.2",
          status: "pending",
          title: "Second Task",
          dependencies: ["v.0.1.0+task.1"]
        )
        create_task_file(
          File.join(structure[:tasks_dir], "task3.md"),
          id: "v.0.1.0+task.3",
          status: "pending",
          title: "Third Task",
          dependencies: ["v.0.1.0+task.2"]
        )

        result = task_manager.get_all_tasks

        expect(result.success?).to be true
        expect(result.has_cycles?).to be true
        expect(result.sorted_count).to be < result.total_count
      end
    end
  end

  describe "error handling" do
    it "handles missing task files gracefully" do
      # Create release structure but no task files
      create_release_structure

      result = task_manager.find_next_task

      expect(result.success?).to be false
      expect(result.message).to include("No tasks found")
    end

    it "handles malformed task files" do
      structure = create_release_structure

      # Create malformed task file
      File.write(File.join(structure[:tasks_dir], "bad.md"), "invalid content")

      result = task_manager.find_next_task

      expect(result.success?).to be false
      expect(result.message).to include("No tasks found")
    end

    it "handles file system errors" do
      # Try to access non-existent directory
      bad_manager = described_class.new(base_path: "/nonexistent/path")

      result = bad_manager.find_next_task

      expect(result.success?).to be false
      expect(result.message).to include("No current release directory found")
    end
  end
end
