# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Task::Reschedule do
  let(:command) { described_class.new }
  let(:project_root) { "/fake/project/root" }
  let(:mock_task_manager) { instance_double("CodingAgentTools::Organisms::TaskflowManagement::TaskManager") }
  let(:mock_tasks_result) { instance_double("CodingAgentTools::Organisms::TaskflowManagement::TaskManager::AllTasksResult") }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(mock_task_manager)
  end

  describe "#call" do
    context "with no tasks specified" do
      it "returns error and usage message" do
        allow(command).to receive(:error_output)

        result = command.call(tasks: [])

        expect(result).to eq(1)
        expect(command).to have_received(:error_output).with("Error: No tasks specified for rescheduling")
        expect(command).to have_received(:error_output).with("Usage: task-manager reschedule TASK_ID [TASK_ID...] [OPTIONS]")
      end
    end

    context "with task manager failure" do
      it "returns error when task manager fails to get tasks" do
        failed_result = instance_double("CodingAgentTools::Organisms::TaskflowManagement::TaskManager::AllTasksResult", success?: false, message: "Failed to load tasks")
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(failed_result)
        allow(command).to receive(:error_output)

        result = command.call(tasks: ["task.001"])

        expect(result).to eq(1)
        expect(command).to have_received(:error_output).with("Error: Failed to load tasks")
      end
    end

    context "with no valid tasks found" do
      let(:mock_tasks) { [] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)
        allow(command).to receive(:error_output)
      end

      it "returns error when no tasks can be resolved" do
        result = command.call(tasks: ["invalid.001"])

        expect(result).to eq(1)
        expect(command).to have_received(:error_output).with("Error: No valid tasks found from provided identifiers")
      end
    end

    context "with successful task resolution and add_next option" do
      let(:mock_task1) { double("Task", id: "v.0.3.0+task.001", path: "/path/task1.md") }
      let(:mock_task2) { double("Task", id: "v.0.3.0+task.002", path: "/path/task2.md") }
      let(:mock_tasks) { [mock_task1, mock_task2] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)
        allow(command).to receive(:reschedule_add_next)
      end

      it "calls reschedule_add_next when add_next option is true" do
        result = command.call(tasks: ["v.0.3.0+task.001"], add_next: true)

        expect(result).to eq(0)
        expect(command).to have_received(:reschedule_add_next)
      end
    end

    context "with successful task resolution and default behavior" do
      let(:mock_task1) { double("Task", id: "v.0.3.0+task.001", path: "/path/task1.md") }
      let(:mock_tasks) { [mock_task1] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(mock_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)
        allow(command).to receive(:reschedule_add_at_end)
      end

      it "calls reschedule_add_at_end by default" do
        result = command.call(tasks: ["v.0.3.0+task.001"])

        expect(result).to eq(0)
        expect(command).to have_received(:reschedule_add_at_end)
      end
    end

    context "with exception handling" do
      before do
        allow(mock_task_manager).to receive(:get_list_tasks).and_raise(StandardError, "Unexpected error")
        allow(command).to receive(:handle_error)
      end

      it "handles exceptions and returns error code" do
        result = command.call(tasks: ["task.001"])

        expect(result).to eq(1)
        expect(command).to have_received(:handle_error)
      end
    end
  end

  describe "#resolve_tasks" do
    let(:mock_task1) { double("Task", id: "v.0.3.0+task.001") }
    let(:mock_task2) { double("Task", id: "v.0.3.0+task.002") }
    let(:all_tasks) { [mock_task1, mock_task2] }

    before do
      allow(command).to receive(:find_task).and_return(nil)
      allow(command).to receive(:error_output)
    end

    it "resolves existing tasks" do
      allow(command).to receive(:find_task).with("v.0.3.0+task.001", all_tasks).and_return(mock_task1)

      result = command.send(:resolve_tasks, ["v.0.3.0+task.001"], all_tasks)

      expect(result).to eq([mock_task1])
    end

    it "warns about missing tasks and continues" do
      result = command.send(:resolve_tasks, ["invalid.001"], all_tasks)

      expect(result).to eq([])
      expect(command).to have_received(:error_output).with("Warning: Could not find task matching 'invalid.001'")
    end

    it "resolves multiple tasks correctly" do
      allow(command).to receive(:find_task).with("v.0.3.0+task.001", all_tasks).and_return(mock_task1)
      allow(command).to receive(:find_task).with("v.0.3.0+task.002", all_tasks).and_return(mock_task2)

      result = command.send(:resolve_tasks, ["v.0.3.0+task.001", "v.0.3.0+task.002"], all_tasks)

      expect(result).to eq([mock_task1, mock_task2])
    end
  end

  describe "#find_task" do
    let(:mock_task1) { double("Task", id: "v.0.3.0+task.001", path: "/path/to/task001.md") }
    let(:mock_task2) { double("Task", id: "v.0.3.0+task.002", path: "/path/to/task002.md") }
    let(:all_tasks) { [mock_task1, mock_task2] }

    it "finds task by exact ID match" do
      result = command.send(:find_task, "v.0.3.0+task.001", all_tasks)
      expect(result).to eq(mock_task1)
    end

    it "finds task by numeric ID without version prefix" do
      result = command.send(:find_task, "001", all_tasks)
      expect(result).to eq(mock_task1)
    end

    it "finds task by exact path match" do
      result = command.send(:find_task, "/path/to/task001.md", all_tasks)
      expect(result).to eq(mock_task1)
    end

    it "finds task by path suffix match" do
      result = command.send(:find_task, "task001.md", all_tasks)
      expect(result).to eq(mock_task1)
    end

    it "finds task by partial ID match" do
      result = command.send(:find_task, "task.001", all_tasks)
      expect(result).to eq(mock_task1)
    end

    it "returns nil when no match found" do
      result = command.send(:find_task, "nonexistent", all_tasks)
      expect(result).to be_nil
    end

    it "handles invalid numeric ID format" do
      result = command.send(:find_task, "abc", all_tasks)
      expect(result).to be_nil
    end
  end

  describe "#reschedule_add_next" do
    let(:mock_task1) { double("Task", id: "v.0.3.0+task.003", status: "pending") }
    let(:mock_task2) { double("Task", id: "v.0.3.0+task.004", status: "pending") }
    let(:pending_task) { double("Task", status: "pending") }
    let(:done_task) { double("Task", status: "done") }
    let(:all_tasks) { [pending_task, done_task] }
    let(:tasks_to_reschedule) { [mock_task1, mock_task2] }

    before do
      allow(command).to receive(:get_task_sort_value).and_return(100)
      allow(command).to receive(:update_task_sort)
      allow(command).to receive(:puts)
    end

    it "schedules tasks before existing pending tasks" do
      command.send(:reschedule_add_next, tasks_to_reschedule, all_tasks, mock_task_manager)

      expect(command).to have_received(:update_task_sort).with(mock_task1, 98, mock_task_manager)
      expect(command).to have_received(:update_task_sort).with(mock_task2, 99, mock_task_manager)
    end

    it "handles empty pending tasks list" do
      allow(pending_task).to receive(:status).and_return("done")
      allow(command).to receive(:get_task_sort_value).and_return(nil)

      command.send(:reschedule_add_next, tasks_to_reschedule, all_tasks, mock_task_manager)

      expect(command).to have_received(:update_task_sort).with(mock_task1, 998, mock_task_manager)
      expect(command).to have_received(:update_task_sort).with(mock_task2, 999, mock_task_manager)
    end

    it "outputs rescheduling messages" do
      command.send(:reschedule_add_next, tasks_to_reschedule, all_tasks, mock_task_manager)

      expect(command).to have_received(:puts).with("  Rescheduled v.0.3.0+task.003 with sort value 98")
      expect(command).to have_received(:puts).with("  Rescheduled v.0.3.0+task.004 with sort value 99")
    end
  end

  describe "#reschedule_add_at_end" do
    let(:mock_task1) { double("Task", id: "v.0.3.0+task.005") }
    let(:mock_task2) { double("Task", id: "v.0.3.0+task.006") }
    let(:existing_task) { double("Task", id: "v.0.3.0+task.003") }
    let(:all_tasks) { [existing_task] }
    let(:tasks_to_reschedule) { [mock_task1, mock_task2] }

    before do
      allow(command).to receive(:get_task_sort_value).and_return(50)
      allow(command).to receive(:parse_task_sequential_number).and_return(3)
      allow(command).to receive(:update_task_sort)
      allow(command).to receive(:puts)
    end

    it "schedules tasks after highest sort value" do
      command.send(:reschedule_add_at_end, tasks_to_reschedule, all_tasks, mock_task_manager)

      expect(command).to have_received(:update_task_sort).with(mock_task1, 51, mock_task_manager)
      expect(command).to have_received(:update_task_sort).with(mock_task2, 52, mock_task_manager)
    end

    it "uses sequential number when sort value is lower" do
      allow(command).to receive(:get_task_sort_value).and_return(1)
      allow(command).to receive(:parse_task_sequential_number).and_return(100)

      command.send(:reschedule_add_at_end, tasks_to_reschedule, all_tasks, mock_task_manager)

      expect(command).to have_received(:update_task_sort).with(mock_task1, 101, mock_task_manager)
      expect(command).to have_received(:update_task_sort).with(mock_task2, 102, mock_task_manager)
    end

    it "handles empty task list" do
      allow(command).to receive(:get_task_sort_value).and_return(nil)
      allow(command).to receive(:parse_task_sequential_number).and_return(nil)

      command.send(:reschedule_add_at_end, tasks_to_reschedule, [], mock_task_manager)

      expect(command).to have_received(:update_task_sort).with(mock_task1, 1, mock_task_manager)
      expect(command).to have_received(:update_task_sort).with(mock_task2, 2, mock_task_manager)
    end
  end

  describe "#get_task_sort_value" do
    it "returns sort value from frontmatter hash with string key" do
      task = double("Task")
      allow(task).to receive(:respond_to?).with(:frontmatter).and_return(true)
      allow(task).to receive(:frontmatter).and_return({"sort" => "42"})
      result = command.send(:get_task_sort_value, task)
      expect(result).to eq(42)
    end

    it "returns sort value from frontmatter hash with symbol key" do
      task = double("Task")
      allow(task).to receive(:respond_to?).with(:frontmatter).and_return(true)
      allow(task).to receive(:frontmatter).and_return({sort: "42"})
      result = command.send(:get_task_sort_value, task)
      expect(result).to eq(42)
    end

    it "returns nil when sort value is not numeric" do
      task = double("Task")
      allow(task).to receive(:respond_to?).with(:frontmatter).and_return(true)
      allow(task).to receive(:frontmatter).and_return({"sort" => "abc"})
      result = command.send(:get_task_sort_value, task)
      expect(result).to be_nil
    end

    it "returns nil when frontmatter is missing" do
      task = double("Task")
      allow(task).to receive(:respond_to?).with(:frontmatter).and_return(true)
      allow(task).to receive(:frontmatter).and_return(nil)
      result = command.send(:get_task_sort_value, task)
      expect(result).to be_nil
    end

    it "returns nil when task doesn't respond to frontmatter" do
      task = double("Task")
      allow(task).to receive(:respond_to?).with(:frontmatter).and_return(false)
      result = command.send(:get_task_sort_value, task)
      expect(result).to be_nil
    end

    it "returns nil when sort key is missing" do
      task = double("Task")
      allow(task).to receive(:respond_to?).with(:frontmatter).and_return(true)
      allow(task).to receive(:frontmatter).and_return({"priority" => "high"})
      result = command.send(:get_task_sort_value, task)
      expect(result).to be_nil
    end
  end

  describe "#parse_task_sequential_number" do
    it "extracts sequential number from task ID" do
      result = command.send(:parse_task_sequential_number, "v.0.3.0+task.042")
      expect(result).to eq(42)
    end

    it "handles single digit numbers" do
      result = command.send(:parse_task_sequential_number, "v.0.3.0+task.5")
      expect(result).to eq(5)
    end

    it "handles large numbers" do
      result = command.send(:parse_task_sequential_number, "v.0.3.0+task.999")
      expect(result).to eq(999)
    end

    it "returns nil for malformed task ID" do
      result = command.send(:parse_task_sequential_number, "invalid-task-id")
      expect(result).to be_nil
    end

    it "returns nil for nil input" do
      result = command.send(:parse_task_sequential_number, nil)
      expect(result).to be_nil
    end

    it "returns nil for non-string input" do
      result = command.send(:parse_task_sequential_number, 123)
      expect(result).to be_nil
    end
  end

  describe "#update_task_sort" do
    let(:task) { double("Task", path: "/path/to/task.md", id: "v.0.3.0+task.001") }
    let(:frontmatter_content) { "id: v.0.3.0+task.001\nstatus: pending\npriority: high" }
    let(:body_content) { "\n# Task Title\n\nTask content here." }
    let(:file_content) { "---\n#{frontmatter_content}\n---#{body_content}" }

    before do
      allow(File).to receive(:read).with("/path/to/task.md").and_return(file_content)
      allow(File).to receive(:write)
      allow(command).to receive(:error_output)
    end

    context "with existing sort value" do
      let(:frontmatter_content) { "id: v.0.3.0+task.001\nsort: 50\nstatus: pending" }

      it "updates existing sort value" do
        expected_content = "---\nid: v.0.3.0+task.001\nsort: 100\nstatus: pending\n---#{body_content}"

        command.send(:update_task_sort, task, 100, mock_task_manager)

        expect(File).to have_received(:write).with("/path/to/task.md", expected_content)
      end
    end

    context "without existing sort value" do
      it "adds sort value to frontmatter" do
        expected_content = "---\nid: v.0.3.0+task.001\nstatus: pending\npriority: high\nsort: 100\n---#{body_content}"

        command.send(:update_task_sort, task, 100, mock_task_manager)

        expect(File).to have_received(:write).with("/path/to/task.md", expected_content)
      end
    end

    context "with malformed frontmatter" do
      let(:file_content) { "Invalid file content without frontmatter" }

      it "outputs warning for unparseable frontmatter" do
        command.send(:update_task_sort, task, 100, mock_task_manager)

        expect(command).to have_received(:error_output).with("Warning: Could not parse frontmatter for v.0.3.0+task.001")
        expect(File).not_to have_received(:write)
      end
    end

    context "with file I/O errors" do
      it "handles file read errors gracefully" do
        allow(File).to receive(:read).and_raise(Errno::ENOENT, "File not found")

        expect {
          command.send(:update_task_sort, task, 100, mock_task_manager)
        }.to raise_error(Errno::ENOENT)
      end

      it "handles file write errors gracefully" do
        allow(File).to receive(:write).and_raise(Errno::EACCES, "Permission denied")

        expect {
          command.send(:update_task_sort, task, 100, mock_task_manager)
        }.to raise_error(Errno::EACCES)
      end
    end
  end

  describe "#handle_error" do
    let(:error) { StandardError.new("Test error message") }

    before do
      allow(command).to receive(:error_output)
      allow(error).to receive(:backtrace).and_return([
        "/path/to/file1.rb:10:in `method1'",
        "/path/to/file2.rb:20:in `method2'"
      ])
    end

    context "with debug disabled" do
      it "outputs simple error message" do
        command.send(:handle_error, error, false)

        expect(command).to have_received(:error_output).with("Error: Test error message")
        expect(command).to have_received(:error_output).with("Use --debug flag for more information")
      end
    end

    context "with debug enabled" do
      it "outputs detailed error information with backtrace" do
        command.send(:handle_error, error, true)

        expect(command).to have_received(:error_output).with("Error: StandardError: Test error message")
        expect(command).to have_received(:error_output).with("\nBacktrace:")
        expect(command).to have_received(:error_output).with("  /path/to/file1.rb:10:in `method1'")
        expect(command).to have_received(:error_output).with("  /path/to/file2.rb:20:in `method2'")
      end
    end

    context "with nil backtrace" do
      it "handles missing backtrace gracefully" do
        allow(error).to receive(:backtrace).and_return(nil)

        command.send(:handle_error, error, true)

        expect(command).to have_received(:error_output).with("Error: StandardError: Test error message")
        expect(command).to have_received(:error_output).with("\nBacktrace:")
      end
    end
  end

  describe "#error_output" do
    it "outputs to stderr" do
      expect { command.send(:error_output, "Test message") }.to output("Test message\n").to_stderr
    end
  end

  describe "edge cases and boundary conditions" do
    context "with very large sort values" do
      let(:mock_task) { double("Task", id: "v.0.3.0+task.001", path: "/path/task.md") }
      let(:all_tasks) { [mock_task] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(all_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)
        allow(command).to receive(:get_task_sort_value).and_return(999999)
        allow(command).to receive(:update_task_sort)
        allow(command).to receive(:puts)
      end

      it "handles large sort values correctly" do
        result = command.call(tasks: ["v.0.3.0+task.001"])
        expect(result).to eq(0)
      end
    end

    context "with conflicting options" do
      let(:mock_task) { double("Task", id: "v.0.3.0+task.001", path: "/path/task.md") }
      let(:all_tasks) { [mock_task] }

      before do
        allow(mock_tasks_result).to receive(:success?).and_return(true)
        allow(mock_tasks_result).to receive(:tasks).and_return(all_tasks)
        allow(mock_task_manager).to receive(:get_list_tasks).and_return(mock_tasks_result)
        allow(command).to receive(:reschedule_add_next)
        allow(command).to receive(:reschedule_add_at_end)
      end

      it "prioritizes add_next over add_at_the_end" do
        command.call(tasks: ["v.0.3.0+task.001"], add_next: true, add_at_the_end: true)

        expect(command).to have_received(:reschedule_add_next)
        expect(command).not_to have_received(:reschedule_add_at_end)
      end
    end

    context "with concurrent file access" do
      let(:task) { double("Task", path: "/path/to/task.md", id: "v.0.3.0+task.001") }
      let(:file_content) { "---\nid: v.0.3.0+task.001\n---\n# Task" }

      it "handles concurrent modification gracefully" do
        allow(File).to receive(:read).and_return(file_content)
        allow(File).to receive(:write).and_raise(Errno::EBUSY, "Resource busy")

        expect {
          command.send(:update_task_sort, task, 100, mock_task_manager)
        }.to raise_error(Errno::EBUSY)
      end
    end
  end
end
