# frozen_string_literal: true

require "spec_helper"
require "ostruct"
require "coding_agent_tools/molecules/taskflow_management/task_dependency_checker"

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::TaskDependencyChecker do
  describe "DependencyResult" do
    let(:result) { described_class::DependencyResult.new("task1", true, [], false, nil) }

    describe "#actionable?" do
      it "returns the actionable status" do
        expect(result.actionable?).to be true
        
        non_actionable = described_class::DependencyResult.new("task2", false, ["dep1"], false, nil)
        expect(non_actionable.actionable?).to be false
      end
    end

    describe "#has_unmet_dependencies?" do
      it "returns false when unmet_dependencies is empty" do
        expect(result.has_unmet_dependencies?).to be false
      end

      it "returns false when unmet_dependencies is nil" do
        nil_deps = described_class::DependencyResult.new("task1", false, nil, false, nil)
        expect(nil_deps.has_unmet_dependencies?).to be false
      end

      it "returns true when unmet_dependencies has items" do
        with_deps = described_class::DependencyResult.new("task1", false, ["dep1", "dep2"], false, nil)
        expect(with_deps.has_unmet_dependencies?).to be true
      end
    end

    describe "struct attributes" do
      it "has all required attributes" do
        result = described_class::DependencyResult.new("task1", true, ["dep1"], true, ["cycle"])
        
        expect(result.task_id).to eq("task1")
        expect(result.actionable).to be true
        expect(result.unmet_dependencies).to eq(["dep1"])
        expect(result.cycle_detected).to be true
        expect(result.cycle_path).to eq(["cycle"])
      end
    end
  end

  describe ".check_task_dependencies" do
    let(:task_map) do
      {
        "task1" => OpenStruct.new(id: "task1", status: "pending", dependencies: []),
        "task2" => OpenStruct.new(id: "task2", status: "done", dependencies: []),
        "task3" => OpenStruct.new(id: "task3", status: "pending", dependencies: ["task1"]),
        "task4" => OpenStruct.new(id: "task4", status: "pending", dependencies: ["task2"]),
        "task5" => OpenStruct.new(id: "task5", status: "pending", dependencies: ["task1", "task2"]),
        "task6" => OpenStruct.new(id: "task6", status: "pending", dependencies: ["nonexistent"])
      }
    end

    context "when task doesn't exist in task_map" do
      it "returns non-actionable result" do
        result = described_class.check_task_dependencies("nonexistent", task_map)
        
        expect(result.task_id).to eq("nonexistent")
        expect(result.actionable?).to be false
        expect(result.unmet_dependencies).to eq([])
        expect(result.cycle_detected).to be false
        expect(result.cycle_path).to be nil
      end
    end

    context "when task is already done" do
      it "returns actionable result" do
        result = described_class.check_task_dependencies("task2", task_map)
        
        expect(result.task_id).to eq("task2")
        expect(result.actionable?).to be true
        expect(result.unmet_dependencies).to eq([])
        expect(result.cycle_detected).to be false
      end
    end

    context "when task has no dependencies" do
      it "returns actionable result" do
        result = described_class.check_task_dependencies("task1", task_map)
        
        expect(result.actionable?).to be true
        expect(result.unmet_dependencies).to eq([])
      end
    end

    context "when task has met dependencies" do
      it "returns actionable result" do
        result = described_class.check_task_dependencies("task4", task_map)
        
        expect(result.actionable?).to be true
        expect(result.unmet_dependencies).to eq([])
      end
    end

    context "when task has unmet dependencies" do
      it "returns non-actionable result with unmet dependencies" do
        result = described_class.check_task_dependencies("task3", task_map)
        
        expect(result.actionable?).to be false
        expect(result.unmet_dependencies).to eq(["task1"])
      end

      it "handles multiple unmet dependencies" do
        result = described_class.check_task_dependencies("task5", task_map)
        
        expect(result.actionable?).to be false
        expect(result.unmet_dependencies).to eq(["task1"])
      end
    end

    context "when task has missing dependencies" do
      it "ignores missing dependencies and checks remaining ones" do
        result = described_class.check_task_dependencies("task6", task_map)
        
        expect(result.actionable?).to be true
        expect(result.unmet_dependencies).to eq([])
      end
    end

    context "with hash-based task data" do
      let(:hash_task_map) do
        {
          "task1" => { "id" => "task1", "status" => "pending", "dependencies" => [] },
          "task2" => { "id" => "task2", "status" => "done", "dependencies" => [] },
          "task3" => { "id" => "task3", "status" => "pending", "dependencies" => ["task1"] }
        }
      end

      it "works with hash-based task data" do
        result = described_class.check_task_dependencies("task3", hash_task_map)
        
        expect(result.actionable?).to be false
        expect(result.unmet_dependencies).to eq(["task1"])
      end
    end

    context "with symbol-key task data" do
      let(:symbol_task_map) do
        {
          "task1" => { id: "task1", status: "pending", dependencies: [] },
          "task2" => { id: "task2", status: "done", dependencies: [] },
          "task3" => { id: "task3", status: "pending", dependencies: ["task1"] }
        }
      end

      it "works with symbol-key task data" do
        result = described_class.check_task_dependencies("task3", symbol_task_map)
        
        expect(result.actionable?).to be false
        expect(result.unmet_dependencies).to eq(["task1"])
      end
    end
  end

  describe ".find_actionable_tasks" do
    let(:task_map) do
      {
        "task1" => OpenStruct.new(id: "task1", status: "pending", dependencies: []),
        "task2" => OpenStruct.new(id: "task2", status: "done", dependencies: []),
        "task3" => OpenStruct.new(id: "task3", status: "pending", dependencies: ["task1"]),
        "task4" => OpenStruct.new(id: "task4", status: "pending", dependencies: ["task2"]),
        "task5" => OpenStruct.new(id: "task5", status: "in-progress", dependencies: [])
      }
    end

    it "returns all actionable tasks" do
      actionable_tasks = described_class.find_actionable_tasks(task_map)
      
      expect(actionable_tasks).to contain_exactly("task1", "task4", "task5")
    end

    it "excludes done tasks" do
      actionable_tasks = described_class.find_actionable_tasks(task_map)
      
      expect(actionable_tasks).not_to include("task2")
    end

    it "excludes tasks with unmet dependencies" do
      actionable_tasks = described_class.find_actionable_tasks(task_map)
      
      expect(actionable_tasks).not_to include("task3")
    end

    it "handles empty task map" do
      actionable_tasks = described_class.find_actionable_tasks({})
      
      expect(actionable_tasks).to eq([])
    end

    it "handles task map with all done tasks" do
      all_done_map = {
        "task1" => OpenStruct.new(id: "task1", status: "done", dependencies: []),
        "task2" => OpenStruct.new(id: "task2", status: "done", dependencies: [])
      }
      
      actionable_tasks = described_class.find_actionable_tasks(all_done_map)
      
      expect(actionable_tasks).to eq([])
    end
  end

  describe "private methods" do
    describe ".task_done?" do
      it "returns false for nil task data" do
        expect(described_class.send(:task_done?, nil)).to be false
      end

      it "returns true for done status with method access" do
        task = OpenStruct.new(status: "done")
        expect(described_class.send(:task_done?, task)).to be true
      end

      it "returns false for non-done status with method access" do
        task = OpenStruct.new(status: "pending")
        expect(described_class.send(:task_done?, task)).to be false
      end

      it "returns true for done status with hash access (string keys)" do
        task = { "status" => "done" }
        expect(described_class.send(:task_done?, task)).to be true
      end

      it "returns true for done status with hash access (symbol keys)" do
        task = { status: "done" }
        expect(described_class.send(:task_done?, task)).to be true
      end

      it "returns false for non-done status with hash access" do
        task = { "status" => "pending" }
        expect(described_class.send(:task_done?, task)).to be false
      end

      it "returns false when status is missing" do
        task = OpenStruct.new(id: "task1")
        expect(described_class.send(:task_done?, task)).to be false
      end
    end

    describe ".extract_dependencies" do
      it "returns empty array for nil task data" do
        expect(described_class.send(:extract_dependencies, nil)).to eq([])
      end

      it "extracts dependencies from method access" do
        task = OpenStruct.new(dependencies: ["task1", "task2"])
        expect(described_class.send(:extract_dependencies, task)).to eq(["task1", "task2"])
      end

      it "extracts dependencies from hash access (string keys)" do
        task = { "dependencies" => ["task1", "task2"] }
        expect(described_class.send(:extract_dependencies, task)).to eq(["task1", "task2"])
      end

      it "extracts dependencies from hash access (symbol keys)" do
        task = { dependencies: ["task1", "task2"] }
        expect(described_class.send(:extract_dependencies, task)).to eq(["task1", "task2"])
      end

      it "handles string dependencies" do
        task = OpenStruct.new(dependencies: "task1,task2")
        expect(described_class.send(:extract_dependencies, task)).to eq(["task1", "task2"])
      end

      it "handles string dependencies with spaces" do
        task = OpenStruct.new(dependencies: "task1, task2 , task3")
        expect(described_class.send(:extract_dependencies, task)).to eq(["task1", "task2", "task3"])
      end

      it "handles empty string dependencies" do
        task = OpenStruct.new(dependencies: "")
        expect(described_class.send(:extract_dependencies, task)).to eq([])
      end

      it "handles nil dependencies" do
        task = OpenStruct.new(dependencies: nil)
        expect(described_class.send(:extract_dependencies, task)).to eq([])
      end

      it "handles invalid dependency types" do
        task = OpenStruct.new(dependencies: 123)
        expect(described_class.send(:extract_dependencies, task)).to eq([])
      end

      it "converts non-string array elements to strings" do
        task = OpenStruct.new(dependencies: [1, 2, 3])
        expect(described_class.send(:extract_dependencies, task)).to eq(["1", "2", "3"])
      end

      it "handles missing dependencies attribute" do
        task = OpenStruct.new(id: "task1")
        expect(described_class.send(:extract_dependencies, task)).to eq([])
      end
    end

    describe ".find_unmet_dependencies" do
      let(:task_map) do
        {
          "task1" => OpenStruct.new(status: "done"),
          "task2" => OpenStruct.new(status: "pending"),
          "task3" => OpenStruct.new(status: "in-progress")
        }
      end

      it "returns empty array for no dependencies" do
        unmet = described_class.send(:find_unmet_dependencies, [], task_map)
        expect(unmet).to eq([])
      end

      it "returns empty array when all dependencies are done" do
        unmet = described_class.send(:find_unmet_dependencies, ["task1"], task_map)
        expect(unmet).to eq([])
      end

      it "returns unmet dependencies" do
        unmet = described_class.send(:find_unmet_dependencies, ["task2", "task3"], task_map)
        expect(unmet).to eq(["task2", "task3"])
      end

      it "returns mix of met and unmet dependencies" do
        unmet = described_class.send(:find_unmet_dependencies, ["task1", "task2"], task_map)
        expect(unmet).to eq(["task2"])
      end

      it "ignores missing dependencies" do
        unmet = described_class.send(:find_unmet_dependencies, ["task1", "nonexistent", "task2"], task_map)
        expect(unmet).to eq(["task2"])
      end

      it "handles nil task in task_map" do
        task_map_with_nil = task_map.merge("nil_task" => nil)
        unmet = described_class.send(:find_unmet_dependencies, ["task1", "nil_task"], task_map_with_nil)
        expect(unmet).to eq([])
      end
    end
  end

  # Integration tests combining multiple methods
  describe "integration scenarios" do
    context "complex dependency chain" do
      let(:complex_task_map) do
        {
          "foundation" => OpenStruct.new(id: "foundation", status: "done", dependencies: []),
          "middleware" => OpenStruct.new(id: "middleware", status: "pending", dependencies: ["foundation"]),
          "api" => OpenStruct.new(id: "api", status: "pending", dependencies: ["middleware"]),
          "ui" => OpenStruct.new(id: "ui", status: "pending", dependencies: ["api"]),
          "tests" => OpenStruct.new(id: "tests", status: "pending", dependencies: ["ui", "api"]),
          "docs" => OpenStruct.new(id: "docs", status: "pending", dependencies: [])
        }
      end

      it "identifies correct actionable tasks at start" do
        actionable = described_class.find_actionable_tasks(complex_task_map)
        expect(actionable).to contain_exactly("middleware", "docs")
      end

      it "checks individual task dependencies correctly" do
        middleware_result = described_class.check_task_dependencies("middleware", complex_task_map)
        expect(middleware_result.actionable?).to be true

        api_result = described_class.check_task_dependencies("api", complex_task_map)
        expect(api_result.actionable?).to be false
        expect(api_result.unmet_dependencies).to eq(["middleware"])

        ui_result = described_class.check_task_dependencies("ui", complex_task_map)
        expect(ui_result.actionable?).to be false
        expect(ui_result.unmet_dependencies).to eq(["api"])
      end
    end

    context "circular dependency scenarios" do
      let(:circular_task_map) do
        {
          "taskA" => OpenStruct.new(id: "taskA", status: "pending", dependencies: ["taskB"]),
          "taskB" => OpenStruct.new(id: "taskB", status: "pending", dependencies: ["taskA"]),
          "taskC" => OpenStruct.new(id: "taskC", status: "pending", dependencies: [])
        }
      end

      it "handles circular dependencies gracefully" do
        actionable = described_class.find_actionable_tasks(circular_task_map)
        expect(actionable).to eq(["taskC"])

        task_a_result = described_class.check_task_dependencies("taskA", circular_task_map)
        expect(task_a_result.actionable?).to be false
        expect(task_a_result.unmet_dependencies).to eq(["taskB"])
      end
    end

    context "mixed data formats" do
      let(:mixed_format_map) do
        {
          "struct_task" => OpenStruct.new(id: "struct_task", status: "done", dependencies: ["hash_task"]),
          "hash_task" => { "id" => "hash_task", "status" => "pending", "dependencies" => [] },
          "symbol_task" => { id: "symbol_task", status: "pending", dependencies: ["struct_task"] }
        }
      end

      it "handles mixed data formats correctly" do
        actionable = described_class.find_actionable_tasks(mixed_format_map)
        expect(actionable).to contain_exactly("hash_task", "symbol_task")
      end
    end
  end

  # Edge cases and error handling
  describe "edge cases" do
    it "handles empty task map" do
      expect(described_class.find_actionable_tasks({})).to eq([])
    end

    it "handles task map with only nil values" do
      nil_map = { "task1" => nil, "task2" => nil }
      result = described_class.check_task_dependencies("task1", nil_map)
      expect(result.actionable?).to be false
    end

    it "handles malformed task data by raising appropriate errors" do
      malformed_map = {
        "good_task" => OpenStruct.new(id: "good_task", status: "pending", dependencies: []),
        "bad_task" => "not_a_hash_or_struct"
      }

      # The current implementation will raise TypeError for malformed data
      expect { described_class.find_actionable_tasks(malformed_map) }.to raise_error(TypeError)
      expect { described_class.check_task_dependencies("bad_task", malformed_map) }.to raise_error(TypeError)
    end

    it "handles deeply nested dependency strings" do
      task = OpenStruct.new(dependencies: "a,b,c,d,e,f,g,h,i,j")
      deps = described_class.send(:extract_dependencies, task)
      expect(deps).to eq(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"])
    end

    it "handles whitespace-only dependency strings" do
      task = OpenStruct.new(dependencies: " , , ")
      deps = described_class.send(:extract_dependencies, task)
      expect(deps).to eq(["", "", ""])
    end
  end
end