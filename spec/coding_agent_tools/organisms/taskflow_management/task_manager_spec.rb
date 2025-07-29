# frozen_string_literal: true

require "spec_helper"
require "ostruct"
require "coding_agent_tools/organisms/taskflow_management/task_manager"

RSpec.describe CodingAgentTools::Organisms::TaskflowManagement::TaskManager do
  let(:base_path) { "/tmp/test_task_manager" }
  let(:task_manager) { described_class.new(base_path: base_path) }

  # Sample task data structures
  let(:task_data_pending) {
    OpenStruct.new(
      id: "v.0.3.0+task.1",
      status: "pending",
      priority: "high",
      dependencies: [],
      path: "/tmp/task1.md"
    )
  }

  let(:task_data_in_progress) {
    OpenStruct.new(
      id: "v.0.3.0+task.2",
      status: "in-progress",
      priority: "medium",
      dependencies: [],
      path: "/tmp/task2.md"
    )
  }

  let(:task_data_done) {
    OpenStruct.new(
      id: "v.0.3.0+task.3",
      status: "done",
      priority: "low",
      dependencies: [],
      path: "/tmp/task3.md"
    )
  }

  let(:task_data_with_deps) {
    OpenStruct.new(
      id: "v.0.3.0+task.4",
      status: "pending",
      priority: "high",
      dependencies: ["v.0.3.0+task.1"],
      path: "/tmp/task4.md"
    )
  }

  before do
    # Create test directory structure
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/current")
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/done")
  end

  after do
    FileUtils.rm_rf(base_path) if File.exist?(base_path)
  end

  describe "Result structs" do
    describe "NextTaskResult" do
      it "responds to success? method" do
        result = described_class::NextTaskResult.new(nil, true, nil)
        expect(result.success?).to be true
        expect(result).to respond_to(:success?)
      end

      it "responds to found? method" do
        result = described_class::NextTaskResult.new(task_data_pending, true, nil)
        expect(result.found?).to be true

        empty_result = described_class::NextTaskResult.new(nil, true, nil)
        expect(empty_result.found?).to be false
      end

      it "has task, success, and message attributes" do
        result = described_class::NextTaskResult.new(task_data_pending, true, "success")
        expect(result.task).to eq(task_data_pending)
        expect(result.success).to be true
        expect(result.message).to eq("success")
      end
    end

    describe "RecentTasksResult" do
      it "responds to success? method" do
        result = described_class::RecentTasksResult.new([], true, nil)
        expect(result.success?).to be true
      end

      it "responds to count method" do
        tasks = [task_data_pending, task_data_done]
        result = described_class::RecentTasksResult.new(tasks, true, nil)
        expect(result.count).to eq(2)

        empty_result = described_class::RecentTasksResult.new(nil, false, "error")
        expect(empty_result.count).to eq(0)
      end

      it "has tasks, success, and message attributes" do
        tasks = [task_data_pending]
        result = described_class::RecentTasksResult.new(tasks, true, "found tasks")
        expect(result.tasks).to eq(tasks)
        expect(result.success).to be true
        expect(result.message).to eq("found tasks")
      end
    end

    describe "AllTasksResult" do
      it "responds to success? method" do
        result = described_class::AllTasksResult.new([], true, nil, false, 0, 0)
        expect(result.success?).to be true
      end

      it "responds to fully_sorted? method" do
        fully_sorted = described_class::AllTasksResult.new([], true, nil, false, 2, 2)
        expect(fully_sorted.fully_sorted?).to be true

        partial_sorted = described_class::AllTasksResult.new([], true, nil, true, 1, 2)
        expect(partial_sorted.fully_sorted?).to be false
      end

      it "responds to has_cycles? method" do
        with_cycles = described_class::AllTasksResult.new([], true, nil, true, 1, 2)
        expect(with_cycles.has_cycles?).to be true

        without_cycles = described_class::AllTasksResult.new([], true, nil, false, 2, 2)
        expect(without_cycles.has_cycles?).to be false
      end

      it "has all required attributes" do
        tasks = [task_data_pending]
        result = described_class::AllTasksResult.new(tasks, true, "sorted", false, 1, 1)
        expect(result.tasks).to eq(tasks)
        expect(result.success).to be true
        expect(result.message).to eq("sorted")
        expect(result.cycle_detected).to be false
        expect(result.sorted_count).to eq(1)
        expect(result.total_count).to eq(1)
      end
    end
  end

  describe "#initialize" do
    it "initializes with default base_path" do
      manager = described_class.new
      expect(manager).to be_an_instance_of(described_class)
    end

    it "initializes with custom base_path" do
      manager = described_class.new(base_path: "/custom/path")
      expect(manager).to be_an_instance_of(described_class)
    end
  end

  describe "#find_next_task" do
    let(:release_info) { OpenStruct.new(path: "#{base_path}/dev-taskflow/current/v.0.3.0-test") }
    let(:release_result) { OpenStruct.new(success?: true, release_info: release_info) }
    let(:tasks_result) { OpenStruct.new(tasks: [task_data_pending, task_data_in_progress, task_data_done]) }
    let(:dependency_result) { OpenStruct.new(actionable?: true) }

    before do
      allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
        .and_return(release_result)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskDependencyChecker).to receive(:check_task_dependencies).and_return(dependency_result)
    end

    context "when release resolution succeeds" do
      it "returns the next actionable task" do
        result = task_manager.find_next_task

        expect(result).to be_a(described_class::NextTaskResult)
        expect(result.success?).to be true
        expect(result.found?).to be true
        expect(result.task.status).to eq("in-progress") # in-progress has higher priority
      end

      it "handles specific release path" do
        result = task_manager.find_next_task(release_path: "v.0.3.0-test")

        expect(result.success?).to be true
        expect(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver)
          .to have_received(:resolve_release).with("v.0.3.0-test", base_path: base_path)
      end
    end

    context "when release resolution fails" do
      let(:failed_release_result) { OpenStruct.new(success?: false, error_message: "Release not found") }

      before do
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
          .and_return(failed_release_result)
      end

      it "returns error result" do
        result = task_manager.find_next_task

        expect(result.success?).to be false
        expect(result.found?).to be false
        expect(result.message).to eq("Release not found")
      end
    end

    context "when no actionable tasks exist" do
      let(:non_actionable_dependency_result) { OpenStruct.new(actionable?: false) }

      before do
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskDependencyChecker).to receive(:check_task_dependencies).and_return(non_actionable_dependency_result)
      end

      it "returns success with no task found message" do
        result = task_manager.find_next_task

        expect(result.success?).to be true
        expect(result.found?).to be false
        expect(result.message).to eq("No actionable tasks found")
      end
    end

    context "when an exception occurs" do
      before do
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
          .and_raise(StandardError, "Unexpected error")
      end

      it "returns error result with exception message" do
        result = task_manager.find_next_task

        expect(result.success?).to be false
        expect(result.message).to include("Error finding next task: Unexpected error")
      end
    end
  end

  describe "#get_all_tasks" do
    let(:release_info) { OpenStruct.new(path: "#{base_path}/dev-taskflow/current/v.0.3.0-test") }
    let(:release_result) { OpenStruct.new(success?: true, release_info: release_info) }

    context "with no dependencies (simple sort)" do
      let(:tasks_result) {
        OpenStruct.new(tasks: [
          OpenStruct.new(id: "v.0.3.0+task.3", dependencies: []),
          OpenStruct.new(id: "v.0.3.0+task.1", dependencies: []),
          OpenStruct.new(id: "v.0.3.0+task.2", dependencies: [])
        ])
      }

      before do
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
          .and_return(release_result)
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)
      end

      it "returns tasks in sorted order" do
        result = task_manager.get_all_tasks

        expect(result.success?).to be true
        expect(result.fully_sorted?).to be true
        expect(result.has_cycles?).to be false
        expect(result.tasks.map(&:id)).to eq(["v.0.3.0+task.1", "v.0.3.0+task.2", "v.0.3.0+task.3"])
      end
    end

    context "with dependencies (topological sort)" do
      let(:tasks_result) {
        OpenStruct.new(tasks: [
          OpenStruct.new(id: "v.0.3.0+task.3", dependencies: ["v.0.3.0+task.1", "v.0.3.0+task.2"]),
          OpenStruct.new(id: "v.0.3.0+task.2", dependencies: ["v.0.3.0+task.1"]),
          OpenStruct.new(id: "v.0.3.0+task.1", dependencies: [])
        ])
      }

      before do
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
          .and_return(release_result)
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)
      end

      it "returns tasks in topological order" do
        result = task_manager.get_all_tasks

        expect(result.success?).to be true
        expect(result.fully_sorted?).to be true
        expect(result.has_cycles?).to be false
        expect(result.tasks.map(&:id)).to eq(["v.0.3.0+task.1", "v.0.3.0+task.2", "v.0.3.0+task.3"])
      end
    end

    context "with circular dependencies (cycle detection)" do
      let(:tasks_result) {
        OpenStruct.new(tasks: [
          OpenStruct.new(id: "v.0.3.0+task.1", dependencies: ["v.0.3.0+task.2"]),
          OpenStruct.new(id: "v.0.3.0+task.2", dependencies: ["v.0.3.0+task.1"])
        ])
      }

      before do
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
          .and_return(release_result)
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)
      end

      it "detects cycles and returns partial results" do
        result = task_manager.get_all_tasks

        expect(result.success?).to be true
        expect(result.fully_sorted?).to be false
        expect(result.has_cycles?).to be true
        expect(result.sorted_count).to be < result.total_count
      end
    end

    context "when release resolution fails" do
      let(:failed_release_result) { OpenStruct.new(success?: false, error_message: "Release not found") }

      before do
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
          .and_return(failed_release_result)
      end

      it "returns error result" do
        result = task_manager.get_all_tasks

        expect(result.success?).to be false
        expect(result.message).to eq("Release not found")
      end
    end

    context "when an exception occurs" do
      before do
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
          .and_raise(StandardError, "Sorting error")
      end

      it "returns error result with exception message" do
        result = task_manager.get_all_tasks

        expect(result.success?).to be false
        expect(result.message).to include("Error getting all tasks: Sorting error")
      end
    end
  end

  describe "#find_next_actionable_task_with_highlight" do
    let(:release_info) { OpenStruct.new(path: "#{base_path}/dev-taskflow/current/v.0.3.0-test") }
    let(:release_result) { OpenStruct.new(success?: true, release_info: release_info) }
    let(:tasks_result) { OpenStruct.new(tasks: [task_data_pending]) }
    let(:dependency_result) { OpenStruct.new(actionable?: true) }

    before do
      allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
        .and_return(release_result)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskDependencyChecker).to receive(:check_task_dependencies).and_return(dependency_result)
    end

    it "returns highlighted task when found" do
      result = task_manager.find_next_actionable_task_with_highlight

      expect(result.success?).to be true
      expect(result.found?).to be true
      expect(result.task.is_next_actionable?).to be true
    end

    it "passes through error when find_next_task fails" do
      allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
        .and_return(OpenStruct.new(success?: false, error_message: "Error"))

      result = task_manager.find_next_actionable_task_with_highlight

      expect(result.success?).to be false
      expect(result.message).to eq("Error")
    end
  end

  describe "task priority sorting" do
    let(:release_info) { OpenStruct.new(path: "#{base_path}/dev-taskflow/current/v.0.3.0-test") }
    let(:release_result) { OpenStruct.new(success?: true, release_info: release_info) }
    let(:dependency_result) { OpenStruct.new(actionable?: true) }

    before do
      allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
        .and_return(release_result)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskDependencyChecker).to receive(:check_task_dependencies).and_return(dependency_result)
    end

    it "prioritizes in-progress tasks over pending tasks" do
      tasks = [
        OpenStruct.new(id: "v.0.3.0+task.2", status: "pending"),
        OpenStruct.new(id: "v.0.3.0+task.1", status: "in-progress")
      ]
      tasks_result = OpenStruct.new(tasks: tasks)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)

      result = task_manager.find_next_task

      expect(result.success?).to be true
      expect(result.task.status).to eq("in-progress")
    end

    it "sorts by task number when status is same" do
      tasks = [
        OpenStruct.new(id: "v.0.3.0+task.5", status: "pending"),
        OpenStruct.new(id: "v.0.3.0+task.2", status: "pending"),
        OpenStruct.new(id: "v.0.3.0+task.10", status: "pending")
      ]
      tasks_result = OpenStruct.new(tasks: tasks)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)

      result = task_manager.find_next_task

      expect(result.success?).to be true
      expect(result.task.id).to eq("v.0.3.0+task.2") # Lowest task number
    end

    it "handles malformed task IDs gracefully" do
      tasks = [
        OpenStruct.new(id: "invalid-task-id", status: "pending"),
        OpenStruct.new(id: "v.0.3.0+task.1", status: "pending")
      ]
      tasks_result = OpenStruct.new(tasks: tasks)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)

      result = task_manager.find_next_task

      expect(result.success?).to be true
      # Should still return a task, malformed ID gets infinity priority
      expect(result.task.id).to eq("v.0.3.0+task.1")
    end
  end

  describe "dependency extraction and topological sort" do
    let(:release_info) { OpenStruct.new(path: "#{base_path}/dev-taskflow/current/v.0.3.0-test") }
    let(:release_result) { OpenStruct.new(success?: true, release_info: release_info) }

    before do
      allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
        .and_return(release_result)
    end

    it "handles array dependencies in topological sort" do
      tasks = [
        OpenStruct.new(id: "v.0.3.0+task.2", dependencies: ["v.0.3.0+task.1"]),
        OpenStruct.new(id: "v.0.3.0+task.1", dependencies: [])
      ]
      tasks_result = OpenStruct.new(tasks: tasks)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)

      result = task_manager.get_all_tasks

      expect(result.success?).to be true
      expect(result.tasks.map(&:id)).to eq(["v.0.3.0+task.1", "v.0.3.0+task.2"])
    end

    it "handles string dependencies in topological sort" do
      tasks = [
        OpenStruct.new(id: "v.0.3.0+task.2", dependencies: "v.0.3.0+task.1"),
        OpenStruct.new(id: "v.0.3.0+task.1", dependencies: "")
      ]
      tasks_result = OpenStruct.new(tasks: tasks)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)

      result = task_manager.get_all_tasks

      expect(result.success?).to be true
      expect(result.tasks.map(&:id)).to eq(["v.0.3.0+task.1", "v.0.3.0+task.2"])
    end

    it "handles comma-separated string dependencies" do
      tasks = [
        OpenStruct.new(id: "v.0.3.0+task.3", dependencies: "v.0.3.0+task.1, v.0.3.0+task.2"),
        OpenStruct.new(id: "v.0.3.0+task.2", dependencies: "v.0.3.0+task.1"),
        OpenStruct.new(id: "v.0.3.0+task.1", dependencies: "")
      ]
      tasks_result = OpenStruct.new(tasks: tasks)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)

      result = task_manager.get_all_tasks

      expect(result.success?).to be true
      expect(result.tasks.map(&:id)).to eq(["v.0.3.0+task.1", "v.0.3.0+task.2", "v.0.3.0+task.3"])
    end

    it "handles nil or invalid dependencies" do
      tasks = [
        OpenStruct.new(id: "v.0.3.0+task.2", dependencies: nil),
        OpenStruct.new(id: "v.0.3.0+task.1", dependencies: 123) # Invalid type
      ]
      tasks_result = OpenStruct.new(tasks: tasks)
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory).and_return(tasks_result)

      result = task_manager.get_all_tasks

      expect(result.success?).to be true
      expect(result.tasks.size).to eq(2) # Both tasks processed despite invalid deps
    end
  end

  describe "edge cases and error conditions" do
    it "handles empty task list gracefully" do
      allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
        .and_return(OpenStruct.new(success?: true, release_info: OpenStruct.new(path: "/tmp")))
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory)
        .and_return(OpenStruct.new(tasks: []))

      result = task_manager.find_next_task

      expect(result.success?).to be true
      expect(result.found?).to be false
      expect(result.message).to eq("No actionable tasks found")
    end

    it "handles task loading failures" do
      allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
        .and_return(OpenStruct.new(success?: true, release_info: OpenStruct.new(path: "/tmp")))
      allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader).to receive(:load_tasks_from_directory)
        .and_return(OpenStruct.new(tasks: []))

      # This tests the load_tasks_from_release private method through public interface
      result = task_manager.find_next_task

      expect(result.success?).to be false
      expect(result.message).to include("No tasks found")
    end

    it "handles tasks directory not found" do
      allow(CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver).to receive(:resolve_release)
        .and_return(OpenStruct.new(success?: true, release_info: OpenStruct.new(path: "/nonexistent")))
      allow(File).to receive(:exist?).with("/nonexistent/tasks").and_return(false)

      result = task_manager.find_next_task

      expect(result.success?).to be false
      expect(result.message).to include("Tasks directory not found")
    end
  end
end
