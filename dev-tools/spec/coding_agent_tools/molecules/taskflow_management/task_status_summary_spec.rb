# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/coding_agent_tools/molecules/taskflow_management/task_status_summary"
require_relative "../../../../lib/coding_agent_tools/molecules/taskflow_management/task_file_loader"

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::TaskStatusSummary do
  let(:task_data_class) { CodingAgentTools::Molecules::TaskflowManagement::TaskFileLoader::TaskData }

  describe ".generate_summary" do
    context "with nil or empty task collection" do
      it "handles nil task collection" do
        result = described_class.generate_summary(nil)

        expect(result.counts).to eq({})
        expect(result.total).to eq(0)
        expect(result.formatted_text).to eq("Status: No tasks found")
        expect(result.empty?).to be true
      end

      it "handles empty task collection" do
        result = described_class.generate_summary([])

        expect(result.counts).to eq({})
        expect(result.total).to eq(0)
        expect(result.formatted_text).to eq("Status: No tasks found")
        expect(result.empty?).to be true
      end
    end

    context "with single task" do
      it "counts one pending task" do
        task = task_data_class.new("task-001", "pending", [], "Test Task", "/path", {}, "content")
        result = described_class.generate_summary([task])

        expect(result.counts).to eq({"pending" => 1})
        expect(result.total).to eq(1)
        expect(result.formatted_text).to eq("Status: 1 pending (1 total)")
        expect(result.empty?).to be false
      end

      it "counts one done task" do
        task = task_data_class.new("task-001", "done", [], "Test Task", "/path", {}, "content")
        result = described_class.generate_summary([task])

        expect(result.counts).to eq({"done" => 1})
        expect(result.total).to eq(1)
        expect(result.formatted_text).to eq("Status: 1 done (1 total)")
      end
    end

    context "with multiple tasks of same status" do
      it "counts multiple pending tasks" do
        tasks = [
          task_data_class.new("task-001", "pending", [], "Task 1", "/path1", {}, "content1"),
          task_data_class.new("task-002", "pending", [], "Task 2", "/path2", {}, "content2"),
          task_data_class.new("task-003", "pending", [], "Task 3", "/path3", {}, "content3")
        ]
        result = described_class.generate_summary(tasks)

        expect(result.counts).to eq({"pending" => 3})
        expect(result.total).to eq(3)
        expect(result.formatted_text).to eq("Status: 3 pending (3 total)")
      end
    end

    context "with multiple tasks of different statuses" do
      it "counts mixed status tasks in alphabetical order" do
        tasks = [
          task_data_class.new("task-001", "pending", [], "Task 1", "/path1", {}, "content1"),
          task_data_class.new("task-002", "done", [], "Task 2", "/path2", {}, "content2"),
          task_data_class.new("task-003", "in-progress", [], "Task 3", "/path3", {}, "content3"),
          task_data_class.new("task-004", "blocked", [], "Task 4", "/path4", {}, "content4"),
          task_data_class.new("task-005", "pending", [], "Task 5", "/path5", {}, "content5")
        ]
        result = described_class.generate_summary(tasks)

        expect(result.counts).to eq({
          "blocked" => 1,
          "done" => 1,
          "in-progress" => 1,
          "pending" => 2
        })
        expect(result.total).to eq(5)
        expect(result.formatted_text).to eq("Status: 1 blocked, 1 done, 1 in-progress, 2 pending (5 total)")
      end

      it "handles realistic distribution as described in task spec" do
        tasks = [
          # 3 draft tasks
          task_data_class.new("task-001", "draft", [], "Task 1", "/path1", {}, "content1"),
          task_data_class.new("task-002", "draft", [], "Task 2", "/path2", {}, "content2"),
          task_data_class.new("task-003", "draft", [], "Task 3", "/path3", {}, "content3"),
          # 12 pending tasks
          *12.times.map { |i| task_data_class.new("task-#{4 + i}", "pending", [], "Task #{4 + i}", "/path#{4 + i}", {}, "content#{4 + i}") },
          # 5 in_progress tasks
          *5.times.map { |i| task_data_class.new("task-#{16 + i}", "in_progress", [], "Task #{16 + i}", "/path#{16 + i}", {}, "content#{16 + i}") },
          # 8 done tasks
          *8.times.map { |i| task_data_class.new("task-#{21 + i}", "done", [], "Task #{21 + i}", "/path#{21 + i}", {}, "content#{21 + i}") },
          # 2 blocked tasks
          task_data_class.new("task-029", "blocked", [], "Task 29", "/path29", {}, "content29"),
          task_data_class.new("task-030", "blocked", [], "Task 30", "/path30", {}, "content30")
        ]
        result = described_class.generate_summary(tasks)

        expect(result.counts).to eq({
          "blocked" => 2,
          "done" => 8,
          "draft" => 3,
          "in_progress" => 5,
          "pending" => 12
        })
        expect(result.total).to eq(30)
        expect(result.formatted_text).to eq("Status: 2 blocked, 8 done, 3 draft, 5 in_progress, 12 pending (30 total)")
      end
    end

    context "with status normalization" do
      it "handles nil status values" do
        task = task_data_class.new("task-001", nil, [], "Test Task", "/path", {}, "content")
        result = described_class.generate_summary([task])

        expect(result.counts).to eq({"unknown" => 1})
        expect(result.total).to eq(1)
        expect(result.formatted_text).to eq("Status: 1 unknown (1 total)")
      end

      it "handles empty string status values" do
        task = task_data_class.new("task-001", "", [], "Test Task", "/path", {}, "content")
        result = described_class.generate_summary([task])

        expect(result.counts).to eq({"unknown" => 1})
        expect(result.total).to eq(1)
        expect(result.formatted_text).to eq("Status: 1 unknown (1 total)")
      end

      it "handles whitespace-only status values" do
        task = task_data_class.new("task-001", "   ", [], "Test Task", "/path", {}, "content")
        result = described_class.generate_summary([task])

        expect(result.counts).to eq({"unknown" => 1})
        expect(result.total).to eq(1)
        expect(result.formatted_text).to eq("Status: 1 unknown (1 total)")
      end

      it "normalizes status values to lowercase" do
        tasks = [
          task_data_class.new("task-001", "PENDING", [], "Task 1", "/path1", {}, "content1"),
          task_data_class.new("task-002", "Pending", [], "Task 2", "/path2", {}, "content2"),
          task_data_class.new("task-003", "pending", [], "Task 3", "/path3", {}, "content3")
        ]
        result = described_class.generate_summary(tasks)

        expect(result.counts).to eq({"pending" => 3})
        expect(result.total).to eq(3)
        expect(result.formatted_text).to eq("Status: 3 pending (3 total)")
      end

      it "normalizes status values with special characters" do
        tasks = [
          task_data_class.new("task-001", "in-progress", [], "Task 1", "/path1", {}, "content1"),
          task_data_class.new("task-002", "in progress", [], "Task 2", "/path2", {}, "content2"),
          task_data_class.new("task-003", "in@progress", [], "Task 3", "/path3", {}, "content3")
        ]
        result = described_class.generate_summary(tasks)

        expect(result.counts).to eq({
          "in-progress" => 1,
          "in_progress" => 2
        })
        expect(result.total).to eq(3)
        expect(result.formatted_text).to eq("Status: 1 in-progress, 2 in_progress (3 total)")
      end
    end

    context "with unknown or custom status values" do
      it "handles custom status values gracefully" do
        tasks = [
          task_data_class.new("task-001", "reviewing", [], "Task 1", "/path1", {}, "content1"),
          task_data_class.new("task-002", "testing", [], "Task 2", "/path2", {}, "content2"),
          task_data_class.new("task-003", "pending", [], "Task 3", "/path3", {}, "content3")
        ]
        result = described_class.generate_summary(tasks)

        expect(result.counts).to eq({
          "pending" => 1,
          "reviewing" => 1,
          "testing" => 1
        })
        expect(result.total).to eq(3)
        expect(result.formatted_text).to eq("Status: 1 pending, 1 reviewing, 1 testing (3 total)")
      end
    end
  end

  describe "StatusSummary" do
    let(:summary) { described_class::StatusSummary.new({"pending" => 2}, 2, "Status: 2 pending (2 total)") }
    let(:empty_summary) { described_class::StatusSummary.new({}, 0, "Status: No tasks found") }

    describe "#empty?" do
      it "returns false when there are tasks" do
        expect(summary.empty?).to be false
      end

      it "returns true when there are no tasks" do
        expect(empty_summary.empty?).to be true
      end
    end
  end
end
