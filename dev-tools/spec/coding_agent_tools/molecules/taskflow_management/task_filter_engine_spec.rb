# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/taskflow_management/task_filter_engine"
require "coding_agent_tools/molecules/taskflow_management/task_filter_parser"

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::TaskFilterEngine do
  # Create a simple task struct for testing
  TaskData = Struct.new(:id, :status, :title, :priority, :frontmatter) do
    def dependencies
      frontmatter&.fetch("dependencies", [])
    end
  end

  let(:pending_task) do
    TaskData.new(
      "task-001",
      "pending",
      "Implement feature A",
      "high",
      {"dependencies" => ["task-000"], "estimate" => "2h"}
    )
  end

  let(:in_progress_task) do
    TaskData.new(
      "task-002",
      "in-progress",
      "Fix bug B",
      "medium",
      {"dependencies" => [], "estimate" => "1h"}
    )
  end

  let(:done_task) do
    TaskData.new(
      "task-003",
      "done",
      "Update documentation",
      "low",
      {"dependencies" => ["task-001"], "estimate" => "30m"}
    )
  end

  let(:blocked_task) do
    TaskData.new(
      "task-004",
      "blocked",
      "Waiting for approval",
      "high",
      {"dependencies" => ["task-002", "task-003"], "estimate" => "4h"}
    )
  end

  let(:all_tasks) { [pending_task, in_progress_task, done_task, blocked_task] }

  describe ".apply_filters" do
    context "with no filters" do
      it "returns all tasks when filters is nil" do
        result = described_class.apply_filters(all_tasks, nil)
        expect(result).to eq(all_tasks)
      end

      it "returns all tasks when filters is empty array" do
        result = described_class.apply_filters(all_tasks, [])
        expect(result).to eq(all_tasks)
      end
    end

    context "with single filter" do
      it "filters by status" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "pending", false, "status:pending"
        )

        result = described_class.apply_filters(all_tasks, [filter])
        expect(result).to eq([pending_task])
      end

      it "filters by priority" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "priority", "high", false, "priority:high"
        )

        result = described_class.apply_filters(all_tasks, [filter])
        expect(result).to contain_exactly(pending_task, blocked_task)
      end

      it "filters by id" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "id", "task-002", false, "id:task-002"
        )

        result = described_class.apply_filters(all_tasks, [filter])
        expect(result).to eq([in_progress_task])
      end
    end

    context "with negated filter" do
      it "excludes tasks matching the filter" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "done", true, "status:!done"
        )

        result = described_class.apply_filters(all_tasks, [filter])
        expect(result).to contain_exactly(pending_task, in_progress_task, blocked_task)
      end
    end

    context "with OR filter" do
      it "matches any of the OR values" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "pending|in-progress", false, "status:pending|in-progress"
        )

        result = described_class.apply_filters(all_tasks, [filter])
        expect(result).to contain_exactly(pending_task, in_progress_task)
      end
    end

    context "with multiple filters (AND logic)" do
      it "applies all filters" do
        status_filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "pending|blocked", false, "status:pending|blocked"
        )
        priority_filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "priority", "high", false, "priority:high"
        )

        result = described_class.apply_filters(all_tasks, [status_filter, priority_filter])
        expect(result).to contain_exactly(pending_task, blocked_task)
      end

      it "returns empty array when no tasks match all filters" do
        status_filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "done", false, "status:done"
        )
        priority_filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "priority", "high", false, "priority:high"
        )

        result = described_class.apply_filters(all_tasks, [status_filter, priority_filter])
        expect(result).to be_empty
      end
    end

    context "with frontmatter attributes" do
      it "filters by estimate from frontmatter" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "estimate", "2h", false, "estimate:2h"
        )

        result = described_class.apply_filters(all_tasks, [filter])
        expect(result).to eq([pending_task])
      end

      it "filters by dependencies array" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "dependencies", "task-001", false, "dependencies:task-001"
        )

        result = described_class.apply_filters(all_tasks, [filter])
        expect(result).to eq([done_task])
      end
    end
  end

  describe ".apply_filter_strings" do
    context "with no filter strings" do
      it "returns all tasks with empty errors when filter_strings is nil" do
        result = described_class.apply_filter_strings(all_tasks, nil)
        expect(result[:tasks]).to eq(all_tasks)
        expect(result[:errors]).to be_empty
      end

      it "returns all tasks with empty errors when filter_strings is empty" do
        result = described_class.apply_filter_strings(all_tasks, [])
        expect(result[:tasks]).to eq(all_tasks)
        expect(result[:errors]).to be_empty
      end
    end

    context "with valid filter strings" do
      it "applies single filter string" do
        result = described_class.apply_filter_strings(all_tasks, ["status:pending"])
        expect(result[:tasks]).to eq([pending_task])
        expect(result[:errors]).to be_empty
      end

      it "applies multiple filter strings" do
        result = described_class.apply_filter_strings(all_tasks, ["status:pending|blocked", "priority:high"])
        expect(result[:tasks]).to contain_exactly(pending_task, blocked_task)
        expect(result[:errors]).to be_empty
      end

      it "applies negated filter strings" do
        result = described_class.apply_filter_strings(all_tasks, ["status:!done"])
        expect(result[:tasks]).to contain_exactly(pending_task, in_progress_task, blocked_task)
        expect(result[:errors]).to be_empty
      end
    end

    context "with invalid filter strings" do
      it "returns errors for invalid filter format" do
        # Mock the parser to return an invalid filter that would fail validation
        allow(CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser)
          .to receive(:parse_filters)
          .and_return([
            CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
              "123invalid", "value", false, "123invalid:value"
            )
          ])

        result = described_class.apply_filter_strings(all_tasks, ["123invalid:value"])
        expect(result[:tasks]).to be_empty
        expect(result[:errors]).to include("Invalid filter attribute: 123invalid")
      end

      it "handles parser returning empty filters for malformed strings" do
        result = described_class.apply_filter_strings(all_tasks, ["malformed", "no_colon"])
        # Parser will skip invalid filters and return empty filter array, so we get all tasks back
        expect(result[:tasks]).to eq(all_tasks)
        expect(result[:errors]).to be_empty
      end
    end

    context "integration with TaskFilterParser" do
      it "correctly parses and applies complex filter strings" do
        filter_strings = [
          "status:pending|in-progress",
          "priority:!low"
        ]

        result = described_class.apply_filter_strings(all_tasks, filter_strings)
        # Should return pending and in-progress tasks that are not low priority
        # pending_task: status=pending, priority=high ✓
        # in_progress_task: status=in-progress, priority=medium ✓
        expect(result[:tasks]).to contain_exactly(pending_task, in_progress_task)
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe ".default_next_filters" do
    it "returns default filter for pending and in-progress tasks" do
      filters = described_class.default_next_filters
      expect(filters).to eq(["status:pending|in-progress"])
    end

    it "default filters work with apply_filter_strings" do
      result = described_class.apply_filter_strings(all_tasks, described_class.default_next_filters)
      expect(result[:tasks]).to contain_exactly(pending_task, in_progress_task)
      expect(result[:errors]).to be_empty
    end
  end

  describe ".has_actionable_tasks?" do
    context "with tasks matching filters" do
      it "returns true when tasks match" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "pending", false, "status:pending"
        )

        expect(described_class.has_actionable_tasks?(all_tasks, [filter])).to be true
      end
    end

    context "with no tasks matching filters" do
      it "returns false when no tasks match" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "cancelled", false, "status:cancelled"
        )

        expect(described_class.has_actionable_tasks?(all_tasks, [filter])).to be false
      end
    end

    context "with empty filters" do
      it "returns true when filters are empty and tasks exist" do
        expect(described_class.has_actionable_tasks?(all_tasks, [])).to be true
      end

      it "returns false when tasks are empty" do
        expect(described_class.has_actionable_tasks?([], [])).to be false
      end
    end
  end

  describe "edge cases" do
    context "with nil task attributes" do
      let(:task_with_nil) do
        TaskData.new("task-005", nil, "Task with nil status", nil, nil)
      end

      it "handles nil values gracefully" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "pending", false, "status:pending"
        )

        result = described_class.apply_filters([task_with_nil], [filter])
        expect(result).to be_empty
      end
    end

    context "with case sensitivity" do
      it "performs case-insensitive matching" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "PENDING", false, "status:PENDING"
        )

        result = described_class.apply_filters(all_tasks, [filter])
        expect(result).to eq([pending_task])
      end
    end

    context "with empty tasks array" do
      it "returns empty array" do
        filter = CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser::FilterCriteria.new(
          "status", "pending", false, "status:pending"
        )

        result = described_class.apply_filters([], [filter])
        expect(result).to be_empty
      end
    end
  end
end
