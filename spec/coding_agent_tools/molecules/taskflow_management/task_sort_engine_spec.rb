# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::TaskSortEngine do
  # Test data structures
  let(:task_data) do
    Struct.new(:id, :status, :priority, :dependencies, :title, :frontmatter, keyword_init: true)
  end

  let(:basic_tasks) do
    [
      task_data.new(id: "v.1.0+task.001", status: "pending", priority: "high", dependencies: []),
      task_data.new(id: "v.1.0+task.002", status: "in-progress", priority: "medium", dependencies: []),
      task_data.new(id: "v.1.0+task.003", status: "done", priority: "low", dependencies: [])
    ]
  end

  let(:tasks_with_dependencies) do
    [
      task_data.new(id: "v.1.0+task.001", status: "pending", priority: "high", dependencies: []),
      task_data.new(id: "v.1.0+task.002", status: "pending", priority: "medium", dependencies: ["v.1.0+task.001"]),
      task_data.new(id: "v.1.0+task.003", status: "pending", priority: "low", dependencies: ["v.1.0+task.001", "v.1.0+task.002"]),
      task_data.new(id: "v.1.0+task.004", status: "pending", priority: "high", dependencies: ["v.1.0+task.002"])
    ]
  end

  let(:tasks_with_cycles) do
    [
      task_data.new(id: "v.1.0+task.001", status: "pending", priority: "high", dependencies: ["v.1.0+task.003"]),
      task_data.new(id: "v.1.0+task.002", status: "pending", priority: "medium", dependencies: ["v.1.0+task.001"]),
      task_data.new(id: "v.1.0+task.003", status: "pending", priority: "low", dependencies: ["v.1.0+task.002"])
    ]
  end

  let(:tasks_with_frontmatter) do
    [
      task_data.new(
        id: "v.1.0+task.001", 
        status: "pending", 
        priority: "high", 
        dependencies: [],
        frontmatter: {"sort" => "1"}
      ),
      task_data.new(
        id: "v.1.0+task.002", 
        status: "pending", 
        priority: "medium", 
        dependencies: [],
        frontmatter: {"sort" => "0"}
      )
    ]
  end

  describe "SortResult" do
    let(:sorted_tasks) { basic_tasks }
    let(:sort_result) { described_class::SortResult.new(sorted_tasks, false, 3, 3, {}) }

    describe "#fully_sorted?" do
      it "returns true when not cycle detected and counts match" do
        expect(sort_result.fully_sorted?).to be true
      end

      it "returns false when cycle detected" do
        cycle_result = described_class::SortResult.new(sorted_tasks, true, 3, 3, {})
        expect(cycle_result.fully_sorted?).to be false
      end

      it "returns false when counts don't match" do
        partial_result = described_class::SortResult.new(sorted_tasks, false, 2, 3, {})
        expect(partial_result.fully_sorted?).to be false
      end
    end

    describe "#has_cycles?" do
      it "returns false when no cycle detected" do
        expect(sort_result.has_cycles?).to be false
      end

      it "returns true when cycle detected" do
        cycle_result = described_class::SortResult.new(sorted_tasks, true, 3, 3, {})
        expect(cycle_result.has_cycles?).to be true
      end
    end
  end

  describe ".apply_sorts" do
    context "with empty sorts array" do
      it "returns tasks unchanged" do
        result = described_class.apply_sorts(basic_tasks, [])
        
        expect(result.sorted_tasks).to eq(basic_tasks)
        expect(result.cycle_detected).to be false
        expect(result.sorted_count).to eq(3)
        expect(result.total_count).to eq(3)
      end
    end

    context "with nil sorts" do
      it "returns tasks unchanged" do
        result = described_class.apply_sorts(basic_tasks, nil)
        
        expect(result.sorted_tasks).to eq(basic_tasks)
        expect(result.cycle_detected).to be false
        expect(result.sorted_count).to eq(3)
        expect(result.total_count).to eq(3)
      end
    end

    context "with implementation-order sort" do
      let(:impl_sort) do
        double("SortCriteria", implementation_order?: true)
      end

      it "calls apply_implementation_order_sort" do
        expect(described_class).to receive(:apply_implementation_order_sort)
          .with(basic_tasks, [impl_sort])
          .and_return(described_class::SortResult.new(basic_tasks, false, 3, 3, {}))

        described_class.apply_sorts(basic_tasks, [impl_sort])
      end
    end

    context "with multi-attribute sorts" do
      let(:multi_sort) do
        double("SortCriteria", implementation_order?: false)
      end

      it "calls apply_multi_attribute_sort" do
        expect(described_class).to receive(:apply_multi_attribute_sort)
          .with(basic_tasks, [multi_sort])
          .and_return(described_class::SortResult.new(basic_tasks, false, 3, 3, {}))

        described_class.apply_sorts(basic_tasks, [multi_sort])
      end
    end
  end

  describe ".apply_sort_string" do
    let(:mock_parser) { CodingAgentTools::Molecules::TaskflowManagement::TaskSortParser }

    context "with empty sort string" do
      it "returns tasks unchanged" do
        result = described_class.apply_sort_string(basic_tasks, "")
        
        expect(result[:result].sorted_tasks).to eq(basic_tasks)
        expect(result[:errors]).to be_empty
      end
    end

    context "with nil sort string" do
      it "returns tasks unchanged" do
        result = described_class.apply_sort_string(basic_tasks, nil)
        
        expect(result[:result].sorted_tasks).to eq(basic_tasks)
        expect(result[:errors]).to be_empty
      end
    end

    context "with valid sort string" do
      it "parses and applies sorts" do
        mock_sorts = [double("SortCriteria", implementation_order?: false)]
        
        allow(mock_parser).to receive(:parse_sorts).with("priority:desc").and_return(mock_sorts)
        allow(mock_parser).to receive(:validate_sorts).with(mock_sorts).and_return([])
        allow(described_class).to receive(:apply_sorts).with(basic_tasks, mock_sorts)
          .and_return(described_class::SortResult.new(basic_tasks, false, 3, 3, {}))

        result = described_class.apply_sort_string(basic_tasks, "priority:desc")
        
        expect(result[:result]).to be_a(described_class::SortResult)
        expect(result[:errors]).to be_empty
      end
    end

    context "with invalid sort string" do
      it "returns validation errors" do
        mock_sorts = [double("SortCriteria")]
        validation_errors = ["Invalid sort attribute: invalid_attr"]
        
        allow(mock_parser).to receive(:parse_sorts).with("invalid_attr:desc").and_return(mock_sorts)
        allow(mock_parser).to receive(:validate_sorts).with(mock_sorts).and_return(validation_errors)

        result = described_class.apply_sort_string(basic_tasks, "invalid_attr:desc")
        
        expect(result[:result]).to be_nil
        expect(result[:errors]).to eq(validation_errors)
      end
    end
  end

  describe ".default_all_sort" do
    it "returns implementation-order" do
      expect(described_class.default_all_sort).to eq("implementation-order")
    end
  end

  describe ".default_next_sort" do
    it "returns implementation-order" do
      expect(described_class.default_next_sort).to eq("implementation-order")
    end
  end

  describe "implementation-order sorting (via apply_sorts)" do
    let(:impl_sort) do
      double("SortCriteria", implementation_order?: true)
    end

    context "with tasks without dependencies" do
      it "sorts by sequential number and ID" do
        result = described_class.apply_sorts(basic_tasks, [impl_sort])
        
        expect(result.sorted_tasks.first.id).to eq("v.1.0+task.001")
        expect(result.sorted_tasks.last.id).to eq("v.1.0+task.003")
        expect(result.cycle_detected).to be false
        expect(result.sort_metadata[:sort_type]).to eq("implementation-order")
      end
    end

    context "with tasks with frontmatter sort metadata" do
      it "sorts by frontmatter sort value first" do
        result = described_class.apply_sorts(tasks_with_frontmatter, [impl_sort])
        
        # Task with sort: 0 should come before task with sort: 1
        expect(result.sorted_tasks.first.id).to eq("v.1.0+task.002")
        expect(result.sorted_tasks.last.id).to eq("v.1.0+task.001")
      end
    end

    context "with tasks with dependencies" do
      it "respects dependency constraints" do
        result = described_class.apply_sorts(tasks_with_dependencies, [impl_sort])
        
        sorted_ids = result.sorted_tasks.map(&:id)
        
        # Task 001 should come before task 002 (dependency)
        expect(sorted_ids.index("v.1.0+task.001")).to be < sorted_ids.index("v.1.0+task.002")
        # Task 002 should come before task 003 (dependency)
        expect(sorted_ids.index("v.1.0+task.002")).to be < sorted_ids.index("v.1.0+task.003")
        # Task 002 should come before task 004 (dependency)
        expect(sorted_ids.index("v.1.0+task.002")).to be < sorted_ids.index("v.1.0+task.004")
        
        expect(result.cycle_detected).to be false
      end

      it "includes dependency levels in metadata" do
        result = described_class.apply_sorts(tasks_with_dependencies, [impl_sort])
        
        expect(result.sort_metadata[:dependency_levels]).to be_a(Hash)
        expect(result.sort_metadata[:dependency_levels]).to have_key("v.1.0+task.001")
        expect(result.sort_metadata[:dependency_levels]).to have_key("v.1.0+task.002")
        expect(result.sort_metadata[:dependency_levels]).to have_key("v.1.0+task.003")
        expect(result.sort_metadata[:dependency_levels]).to have_key("v.1.0+task.004")
      end
    end

    context "with circular dependencies" do
      it "detects cycles and limits iterations" do
        result = described_class.apply_sorts(tasks_with_cycles, [impl_sort])
        
        expect(result.cycle_detected).to be true
        expect(result.sorted_tasks).to eq(tasks_with_cycles) # Should return some ordering
      end
    end
  end

  describe ".apply_multi_attribute_sort" do
    let(:sort_criteria) do
      double("SortCriteria", 
        get_sort_value: nil, 
        descending?: false,
        raw_sort: "priority:asc"
      )
    end

    context "with single sort criteria" do
      it "sorts by the specified attribute" do
        # Mock sort criteria to return priority values
        allow(sort_criteria).to receive(:get_sort_value) do |task|
          case task.priority
          when "high" then 0
          when "medium" then 1
          when "low" then 2
          end
        end

        result = described_class.apply_multi_attribute_sort(basic_tasks, [sort_criteria])
        
        expect(result.sorted_tasks.first.priority).to eq("high")
        expect(result.sorted_tasks.last.priority).to eq("low")
        expect(result.cycle_detected).to be false
        expect(result.sort_metadata[:sort_type]).to eq("multi-attribute")
      end
    end

    context "with descending sort" do
      it "reverses the sort order" do
        allow(sort_criteria).to receive(:descending?).and_return(true)
        allow(sort_criteria).to receive(:get_sort_value) do |task|
          case task.priority
          when "high" then 0
          when "medium" then 1
          when "low" then 2
          end
        end

        result = described_class.apply_multi_attribute_sort(basic_tasks, [sort_criteria])
        
        expect(result.sorted_tasks.first.priority).to eq("low")
        expect(result.sorted_tasks.last.priority).to eq("high")
      end
    end

    context "with nil sort values" do
      it "puts nil values last" do
        tasks_with_nil = [
          task_data.new(id: "task.001", priority: "high"),
          task_data.new(id: "task.002", priority: nil),
          task_data.new(id: "task.003", priority: "low")
        ]

        allow(sort_criteria).to receive(:get_sort_value) do |task|
          case task.priority
          when "high" then 0
          when "low" then 2
          when nil then nil
          end
        end

        result = described_class.apply_multi_attribute_sort(tasks_with_nil, [sort_criteria])
        
        expect(result.sorted_tasks.last.priority).to be_nil
      end
    end

    context "with multiple sort criteria" do
      let(:primary_sort) do
        double("SortCriteria", 
          get_sort_value: nil, 
          descending?: false,
          raw_sort: "status:asc"
        )
      end
      
      let(:secondary_sort) do
        double("SortCriteria", 
          get_sort_value: nil, 
          descending?: false,
          raw_sort: "priority:asc"
        )
      end

      it "sorts by primary criteria first, then secondary" do
        tasks_multi = [
          task_data.new(id: "task.001", status: "pending", priority: "low"),
          task_data.new(id: "task.002", status: "pending", priority: "high"),
          task_data.new(id: "task.003", status: "done", priority: "high")
        ]

        # Mock primary sort (status)
        allow(primary_sort).to receive(:get_sort_value) do |task|
          case task.status
          when "pending" then 0
          when "done" then 1
          end
        end

        # Mock secondary sort (priority)
        allow(secondary_sort).to receive(:get_sort_value) do |task|
          case task.priority
          when "high" then 0
          when "low" then 1
          end
        end

        result = described_class.apply_multi_attribute_sort(tasks_multi, [primary_sort, secondary_sort])
        
        sorted_tasks = result.sorted_tasks
        # First two should be pending status, sorted by priority (high before low)
        expect(sorted_tasks[0].status).to eq("pending")
        expect(sorted_tasks[0].priority).to eq("high")
        expect(sorted_tasks[1].status).to eq("pending")
        expect(sorted_tasks[1].priority).to eq("low")
        expect(sorted_tasks[2].status).to eq("done")
      end
    end

    context "when all criteria are equal" do
      it "falls back to sorting by task ID" do
        equal_tasks = [
          task_data.new(id: "task.003", priority: "high"),
          task_data.new(id: "task.001", priority: "high"),
          task_data.new(id: "task.002", priority: "high")
        ]

        allow(sort_criteria).to receive(:get_sort_value).and_return(0) # All equal

        result = described_class.apply_multi_attribute_sort(equal_tasks, [sort_criteria])
        
        sorted_ids = result.sorted_tasks.map(&:id)
        expect(sorted_ids).to eq(["task.001", "task.002", "task.003"])
      end
    end
  end

  describe ".extract_dependencies" do
    context "with array dependencies" do
      it "converts to string array" do
        task = task_data.new(dependencies: ["task.001", "task.002"])
        
        result = described_class.extract_dependencies(task)
        
        expect(result).to eq(["task.001", "task.002"])
      end
    end

    context "with string dependencies" do
      it "splits on comma and strips whitespace" do
        task = task_data.new(dependencies: "task.001, task.002 , task.003")
        
        result = described_class.extract_dependencies(task)
        
        expect(result).to eq(["task.001", "task.002", "task.003"])
      end
    end

    context "with nil dependencies" do
      it "returns empty array" do
        task = task_data.new(dependencies: nil)
        
        result = described_class.extract_dependencies(task)
        
        expect(result).to eq([])
      end
    end

    context "with other dependency types" do
      it "returns empty array" do
        task = task_data.new(dependencies: 123)
        
        result = described_class.extract_dependencies(task)
        
        expect(result).to eq([])
      end
    end
  end

  describe ".parse_task_sequential_number" do
    it "extracts sequential number from task ID" do
      expect(described_class.parse_task_sequential_number("v.1.0+task.123")).to eq(123)
      expect(described_class.parse_task_sequential_number("release+task.456")).to eq(456)
    end

    it "returns infinity for non-matching IDs" do
      expect(described_class.parse_task_sequential_number("invalid")).to eq(Float::INFINITY)
      expect(described_class.parse_task_sequential_number("task.123")).to eq(Float::INFINITY)
    end

    it "handles nil and non-string inputs" do
      expect(described_class.parse_task_sequential_number(nil)).to eq(Float::INFINITY)
      expect(described_class.parse_task_sequential_number(123)).to eq(Float::INFINITY)
    end
  end

  describe ".get_sort_metadata" do
    context "with frontmatter sort attribute" do
      it "returns numeric sort value" do
        task = task_data.new(frontmatter: {"sort" => "5"})
        
        result = described_class.get_sort_metadata(task)
        
        expect(result).to eq(5)
      end

      it "handles symbol keys" do
        task = task_data.new(frontmatter: {sort: "3"})
        
        result = described_class.get_sort_metadata(task)
        
        expect(result).to eq(3)
      end

      it "handles non-numeric sort values" do
        task = task_data.new(frontmatter: {"sort" => "invalid"})
        
        result = described_class.get_sort_metadata(task)
        
        expect(result).to eq(0)
      end
    end

    context "without frontmatter" do
      it "returns default value of 0" do
        task = task_data.new(frontmatter: nil)
        
        result = described_class.get_sort_metadata(task)
        
        expect(result).to eq(0)
      end
    end

    context "without sort attribute" do
      it "returns default value of 0" do
        task = task_data.new(frontmatter: {"other" => "value"})
        
        result = described_class.get_sort_metadata(task)
        
        expect(result).to eq(0)
      end
    end
  end

  describe ".calculate_dependency_levels" do
    it "calculates dependency levels for tasks" do
      # Create a properly sorted task list first
      impl_sort = double("SortCriteria", implementation_order?: true)
      sort_result = described_class.apply_sorts(tasks_with_dependencies, [impl_sort])
      sorted_tasks = sort_result.sorted_tasks
      
      task_map = {}
      tasks_with_dependencies.each { |task| task_map[task.id] = task }
      
      result = described_class.calculate_dependency_levels(sorted_tasks, task_map)
      
      # Check that levels are calculated and tasks with no dependencies are at level 0
      expect(result).to be_a(Hash)
      expect(result["v.1.0+task.001"]).to eq(0) # No dependencies
      
      # Check that dependent tasks have higher levels than their dependencies
      task_002_level = result["v.1.0+task.002"]
      task_003_level = result["v.1.0+task.003"] 
      task_004_level = result["v.1.0+task.004"]
      
      expect(task_002_level).to be >= result["v.1.0+task.001"]
      expect(task_003_level).to be >= [result["v.1.0+task.001"], task_002_level].max
      expect(task_004_level).to be >= task_002_level
    end

    it "handles tasks without dependencies" do
      task_map = {}
      basic_tasks.each { |task| task_map[task.id] = task }
      
      result = described_class.calculate_dependency_levels(basic_tasks, task_map)
      
      expect(result.values.uniq).to eq([0]) # All at level 0
    end
  end

  describe "integration tests" do
    context "with implementation-order sorting" do
      it "sorts complex dependency graph correctly" do
        complex_tasks = [
          task_data.new(id: "v.1.0+task.005", dependencies: ["v.1.0+task.001", "v.1.0+task.003"]),
          task_data.new(id: "v.1.0+task.001", dependencies: []),
          task_data.new(id: "v.1.0+task.003", dependencies: ["v.1.0+task.001"]),
          task_data.new(id: "v.1.0+task.002", dependencies: []),
          task_data.new(id: "v.1.0+task.004", dependencies: ["v.1.0+task.002"])
        ]

        result = described_class.apply_sort_string(complex_tasks, "implementation-order")
        
        expect(result[:errors]).to be_empty
        expect(result[:result].cycle_detected).to be false
        
        sorted_ids = result[:result].sorted_tasks.map(&:id)
        
        # Verify dependency constraints
        expect(sorted_ids.index("v.1.0+task.001")).to be < sorted_ids.index("v.1.0+task.003")
        expect(sorted_ids.index("v.1.0+task.003")).to be < sorted_ids.index("v.1.0+task.005")
        expect(sorted_ids.index("v.1.0+task.001")).to be < sorted_ids.index("v.1.0+task.005")
        expect(sorted_ids.index("v.1.0+task.002")).to be < sorted_ids.index("v.1.0+task.004")
      end
    end

    context "with multi-attribute sorting" do
      it "handles complex multi-attribute sort string" do
        result = described_class.apply_sort_string(basic_tasks, "status:asc,priority:desc")
        
        expect(result[:errors]).to be_empty
        expect(result[:result].cycle_detected).to be false
        expect(result[:result].sort_metadata[:sort_type]).to eq("multi-attribute")
      end
    end
  end
end