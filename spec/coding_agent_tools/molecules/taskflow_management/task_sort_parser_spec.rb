# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::TaskSortParser do
  # Test data structures for task objects
  let(:task_data_class) do
    Struct.new(:id, :status, :priority, :dependencies, :title, :frontmatter, keyword_init: true)
  end

  let(:basic_task) do
    task_data_class.new(
      id: "v.1.0+task.001",
      status: "pending",
      priority: "high",
      dependencies: [],
      title: "Sample task",
      frontmatter: nil
    )
  end

  let(:task_with_frontmatter) do
    task_data_class.new(
      id: "v.1.0+task.002",
      status: "in-progress",
      priority: "medium",
      dependencies: ["v.1.0+task.001"],
      title: "Task with frontmatter",
      frontmatter: {
        "custom_attr" => "custom_value",
        :symbol_attr => "symbol_value",
        "sort" => "5"
      }
    )
  end

  let(:task_without_id_pattern) do
    task_data_class.new(
      id: "invalid-task-id",
      status: "done",
      priority: "low",
      dependencies: [],
      title: "Task with invalid ID",
      frontmatter: nil
    )
  end

  describe "SortCriteria", :struct_methods do
    let(:sort_criteria) { described_class::SortCriteria.new("priority", :asc, "priority:asc") }
    let(:desc_sort_criteria) { described_class::SortCriteria.new("status", :desc, "status:desc") }
    let(:impl_order_criteria) { described_class::SortCriteria.new("implementation-order", :asc, "implementation-order") }

    describe "#ascending?" do
      it "returns true for ascending direction" do
        expect(sort_criteria.ascending?).to be true
      end

      it "returns false for descending direction" do
        expect(desc_sort_criteria.ascending?).to be false
      end
    end

    describe "#descending?" do
      it "returns true for descending direction" do
        expect(desc_sort_criteria.descending?).to be true
      end

      it "returns false for ascending direction" do
        expect(sort_criteria.descending?).to be false
      end
    end

    describe "#implementation_order?" do
      it "returns true for implementation-order attribute" do
        expect(impl_order_criteria.implementation_order?).to be true
      end

      it "returns false for other attributes" do
        expect(sort_criteria.implementation_order?).to be false
      end
    end

    describe "#get_sort_value", :get_sort_value do
      context "with implementation-order attribute" do
        it "returns nil" do
          expect(impl_order_criteria.get_sort_value(basic_task)).to be_nil
        end
      end

      context "with id attribute" do
        let(:id_sort_criteria) { described_class::SortCriteria.new("id", :asc, "id:asc") }

        it "extracts sequential number from valid task ID" do
          expect(id_sort_criteria.get_sort_value(basic_task)).to eq(1)
        end

        it "returns Float::INFINITY for invalid task ID" do
          expect(id_sort_criteria.get_sort_value(task_without_id_pattern)).to eq(Float::INFINITY)
        end

        it "handles nil task ID" do
          nil_id_task = task_data_class.new(id: nil)
          expect(id_sort_criteria.get_sort_value(nil_id_task)).to eq(Float::INFINITY)
        end
      end

      context "with status attribute" do
        let(:status_sort_criteria) { described_class::SortCriteria.new("status", :asc, "status:asc") }

        it "maps in-progress status to priority 0" do
          expect(status_sort_criteria.get_sort_value(task_with_frontmatter)).to eq(0)
        end

        it "maps pending status to priority 1" do
          expect(status_sort_criteria.get_sort_value(basic_task)).to eq(1)
        end

        it "maps blocked status to priority 2" do
          blocked_task = task_data_class.new(status: "blocked")
          expect(status_sort_criteria.get_sort_value(blocked_task)).to eq(2)
        end

        it "maps done status to priority 3" do
          done_task = task_data_class.new(status: "done")
          expect(status_sort_criteria.get_sort_value(done_task)).to eq(3)
        end

        it "maps unknown status to priority 4" do
          unknown_task = task_data_class.new(status: "unknown")
          expect(status_sort_criteria.get_sort_value(unknown_task)).to eq(4)
        end

        it "handles nil status" do
          nil_status_task = task_data_class.new(status: nil)
          expect(status_sort_criteria.get_sort_value(nil_status_task)).to eq(4)
        end

        it "handles case insensitive status" do
          upper_task = task_data_class.new(status: "IN-PROGRESS")
          expect(status_sort_criteria.get_sort_value(upper_task)).to eq(0)
        end
      end

      context "with priority attribute" do
        let(:priority_sort_criteria) { described_class::SortCriteria.new("priority", :asc, "priority:asc") }

        it "maps high priority to value 0" do
          expect(priority_sort_criteria.get_sort_value(basic_task)).to eq(0)
        end

        it "maps medium priority to value 1" do
          expect(priority_sort_criteria.get_sort_value(task_with_frontmatter)).to eq(1)
        end

        it "maps low priority to value 2" do
          low_task = task_data_class.new(priority: "low")
          expect(priority_sort_criteria.get_sort_value(low_task)).to eq(2)
        end

        it "maps unknown priority to value 3" do
          unknown_task = task_data_class.new(priority: "unknown")
          expect(priority_sort_criteria.get_sort_value(unknown_task)).to eq(3)
        end

        it "handles nil priority" do
          nil_priority_task = task_data_class.new(priority: nil)
          expect(priority_sort_criteria.get_sort_value(nil_priority_task)).to eq(3)
        end

        it "handles case insensitive priority" do
          upper_task = task_data_class.new(priority: "HIGH")
          expect(priority_sort_criteria.get_sort_value(upper_task)).to eq(0)
        end
      end

      context "with other attributes" do
        let(:title_sort_criteria) { described_class::SortCriteria.new("title", :asc, "title:asc") }

        it "returns the attribute value directly" do
          expect(title_sort_criteria.get_sort_value(basic_task)).to eq("Sample task")
        end

        it "accesses attributes via direct method call" do
          expect(title_sort_criteria.get_sort_value(basic_task)).to eq(basic_task.title)
        end

        it "accesses attributes from frontmatter when method not available" do
          custom_sort_criteria = described_class::SortCriteria.new("custom_attr", :asc, "custom_attr:asc")
          expect(custom_sort_criteria.get_sort_value(task_with_frontmatter)).to eq("custom_value")
        end

        it "returns nil for symbol keys in frontmatter when accessed as string" do
          # The implementation only tries string keys, not symbol conversion
          task_with_only_symbol = task_data_class.new(
            frontmatter: {symbol_only: "symbol_value"}
          )
          symbol_sort_criteria = described_class::SortCriteria.new("symbol_only", :asc, "symbol_only:asc")
          expect(symbol_sort_criteria.get_sort_value(task_with_only_symbol)).to be_nil
        end

        it "returns nil for non-existent attributes" do
          nonexistent_sort_criteria = described_class::SortCriteria.new("nonexistent", :asc, "nonexistent:asc")
          expect(nonexistent_sort_criteria.get_sort_value(basic_task)).to be_nil
        end

        it "returns nil when task has no frontmatter" do
          custom_sort_criteria = described_class::SortCriteria.new("custom_attr", :asc, "custom_attr:asc")
          expect(custom_sort_criteria.get_sort_value(basic_task)).to be_nil
        end
      end
    end
  end

  describe ".parse_sort", :parse_sort do
    context "with valid sort strings" do
      it "parses attribute only (defaults to ascending)" do
        result = described_class.parse_sort("priority")

        expect(result).to be_a(described_class::SortCriteria)
        expect(result.attribute).to eq("priority")
        expect(result.direction).to eq(:asc)
        expect(result.raw_sort).to eq("priority")
      end

      it "parses attribute with ascending direction" do
        result = described_class.parse_sort("priority:asc")

        expect(result.attribute).to eq("priority")
        expect(result.direction).to eq(:asc)
        expect(result.raw_sort).to eq("priority:asc")
      end

      it "parses attribute with descending direction" do
        result = described_class.parse_sort("status:desc")

        expect(result.attribute).to eq("status")
        expect(result.direction).to eq(:desc)
        expect(result.raw_sort).to eq("status:desc")
      end

      it "parses attribute with ascending spelled out" do
        result = described_class.parse_sort("id:ascending")

        expect(result.attribute).to eq("id")
        expect(result.direction).to eq(:asc)
      end

      it "parses attribute with descending spelled out" do
        result = described_class.parse_sort("id:descending")

        expect(result.attribute).to eq("id")
        expect(result.direction).to eq(:desc)
      end

      it "handles case insensitive direction" do
        result = described_class.parse_sort("priority:DESC")

        expect(result.direction).to eq(:desc)
      end

      it "handles extra whitespace" do
        result = described_class.parse_sort("  priority : asc  ")

        expect(result.attribute).to eq("priority")
        expect(result.direction).to eq(:asc)
      end

      it "handles implementation-order special case" do
        result = described_class.parse_sort("implementation-order")

        expect(result.attribute).to eq("implementation-order")
        expect(result.direction).to eq(:asc)
        expect(result.implementation_order?).to be true
      end

      it "handles implementation-order with whitespace" do
        result = described_class.parse_sort("  implementation-order  ")

        expect(result.attribute).to eq("implementation-order")
        expect(result.direction).to eq(:asc)
      end
    end

    context "with invalid sort strings", :edge_cases do
      it "returns nil for nil input" do
        expect(described_class.parse_sort(nil)).to be_nil
      end

      it "returns nil for non-string input" do
        expect(described_class.parse_sort(123)).to be_nil
        expect(described_class.parse_sort([])).to be_nil
        expect(described_class.parse_sort({})).to be_nil
      end

      it "raises error for empty string due to implementation bug" do
        # Empty string split returns [], so parts[0] is nil, causing nil.strip to fail
        expect { described_class.parse_sort("") }.to raise_error(NoMethodError)
      end

      it "returns nil for whitespace only" do
        expect(described_class.parse_sort("   ")).to be_nil
      end

      it "returns nil for empty attribute" do
        expect(described_class.parse_sort(":asc")).to be_nil
      end

      it "returns nil for invalid direction" do
        expect(described_class.parse_sort("priority:invalid")).to be_nil
      end

      it "returns nil for multiple colons" do
        expect(described_class.parse_sort("priority:asc:extra")).to be_nil
      end
    end
  end

  describe ".parse_sorts", :parse_sorts do
    context "with valid sort strings" do
      it "parses single sort criteria" do
        result = described_class.parse_sorts("priority:desc")

        expect(result.size).to eq(1)
        expect(result.first.attribute).to eq("priority")
        expect(result.first.direction).to eq(:desc)
      end

      it "parses multiple sort criteria" do
        result = described_class.parse_sorts("priority:desc,status:asc")

        expect(result.size).to eq(2)
        expect(result[0].attribute).to eq("priority")
        expect(result[0].direction).to eq(:desc)
        expect(result[1].attribute).to eq("status")
        expect(result[1].direction).to eq(:asc)
      end

      it "parses mixed valid and invalid criteria (skips invalid)" do
        result = described_class.parse_sorts("priority:desc,invalid:baddir,status:asc")

        expect(result.size).to eq(2)
        expect(result[0].attribute).to eq("priority")
        expect(result[1].attribute).to eq("status")
      end

      it "handles whitespace around commas" do
        result = described_class.parse_sorts("priority:desc , status:asc , id")

        expect(result.size).to eq(3)
        expect(result[0].attribute).to eq("priority")
        expect(result[1].attribute).to eq("status")
        expect(result[2].attribute).to eq("id")
      end

      it "handles implementation-order in multiple sorts" do
        result = described_class.parse_sorts("implementation-order,priority:desc")

        expect(result.size).to eq(2)
        expect(result[0].implementation_order?).to be true
        expect(result[1].attribute).to eq("priority")
      end
    end

    context "with invalid sort strings", :edge_cases do
      it "returns empty array for nil input" do
        expect(described_class.parse_sorts(nil)).to eq([])
      end

      it "returns empty array for non-string input" do
        expect(described_class.parse_sorts(123)).to eq([])
        expect(described_class.parse_sorts([])).to eq([])
      end

      it "returns empty array for empty string" do
        expect(described_class.parse_sorts("")).to eq([])
      end

      it "returns empty array when all criteria are invalid" do
        expect(described_class.parse_sorts("invalid:baddir,another:baddir")).to eq([])
      end

      it "skips invalid parts between commas" do
        # When parse_sort returns nil for invalid parts, they get filtered out by the compact logic
        result = described_class.parse_sorts("priority:desc,invalid:baddir,status:asc")

        expect(result.size).to eq(2)
        expect(result[0].attribute).to eq("priority")
        expect(result[1].attribute).to eq("status")
      end
    end
  end

  describe ".validate_sorts", :validate_sorts do
    let(:valid_sorts) do
      [
        described_class::SortCriteria.new("id", :asc, "id:asc"),
        described_class::SortCriteria.new("status", :desc, "status:desc"),
        described_class::SortCriteria.new("priority", :asc, "priority:asc")
      ]
    end

    let(:mixed_sorts) do
      [
        described_class::SortCriteria.new("status", :asc, "status:asc"),
        described_class::SortCriteria.new("invalid-attr", :desc, "invalid-attr:desc"),  # hyphens make it invalid
        described_class::SortCriteria.new("custom_valid_attr", :asc, "custom_valid_attr:asc")
      ]
    end

    let(:implementation_order_sort) do
      [described_class::SortCriteria.new("implementation-order", :asc, "implementation-order")]
    end

    context "with valid sort criteria" do
      it "returns empty errors for known attributes" do
        errors = described_class.validate_sorts(valid_sorts)
        expect(errors).to be_empty
      end

      it "returns empty errors for implementation-order" do
        errors = described_class.validate_sorts(implementation_order_sort)
        expect(errors).to be_empty
      end

      it "returns empty errors for custom attributes matching pattern" do
        custom_sorts = [
          described_class::SortCriteria.new("custom_attr", :asc, "custom_attr:asc"),
          described_class::SortCriteria.new("another_valid_attr", :desc, "another_valid_attr:desc")
        ]

        errors = described_class.validate_sorts(custom_sorts)
        expect(errors).to be_empty
      end

      it "validates all known task attributes" do
        known_attrs = %w[id status dependencies title priority estimate sort implementation-order]
        sorts = known_attrs.map { |attr| described_class::SortCriteria.new(attr, :asc, "#{attr}:asc") }

        errors = described_class.validate_sorts(sorts)
        expect(errors).to be_empty
      end
    end

    context "with invalid sort criteria" do
      it "returns error for invalid attribute names" do
        invalid_sorts = [
          described_class::SortCriteria.new("invalid-attr-with-hyphens", :asc, "invalid-attr-with-hyphens:asc"),
          described_class::SortCriteria.new("123invalid", :desc, "123invalid:desc")
        ]

        errors = described_class.validate_sorts(invalid_sorts)
        expect(errors).to include("Invalid sort attribute: invalid-attr-with-hyphens")
        expect(errors).to include("Invalid sort attribute: 123invalid")
      end

      it "returns errors for mixed valid and invalid attributes" do
        errors = described_class.validate_sorts(mixed_sorts)
        expect(errors).to include("Invalid sort attribute: invalid-attr")
        expect(errors).not_to include("Invalid sort attribute: status")
        expect(errors).not_to include("Invalid sort attribute: custom_valid_attr")
      end

      it "validates attribute name pattern" do
        pattern_invalid_sorts = [
          described_class::SortCriteria.new("attr-with-hyphens", :asc, "attr-with-hyphens:asc"),
          described_class::SortCriteria.new("attr with spaces", :asc, "attr with spaces:asc"),
          described_class::SortCriteria.new("attr.with.dots", :asc, "attr.with.dots:asc")
        ]

        errors = described_class.validate_sorts(pattern_invalid_sorts)
        expect(errors.size).to eq(3)
        expect(errors).to all(start_with("Invalid sort attribute:"))
      end
    end

    context "with edge cases", :edge_cases do
      it "returns empty errors for nil input" do
        errors = described_class.validate_sorts(nil)
        expect(errors).to eq([])
      end

      it "returns empty errors for non-array input" do
        errors = described_class.validate_sorts("not an array")
        expect(errors).to eq([])
      end

      it "returns empty errors for empty array" do
        errors = described_class.validate_sorts([])
        expect(errors).to eq([])
      end

      it "handles sorts with nil attributes by raising error" do
        nil_attr_sort = described_class::SortCriteria.new(nil, :asc, "nil:asc")
        # The implementation doesn't handle nil attributes gracefully - it calls match? on nil
        expect { described_class.validate_sorts([nil_attr_sort]) }.to raise_error(NoMethodError)
      end
    end
  end

  describe "integration tests", :integration do
    context "parsing and validation workflow" do
      it "parses and validates complex sort string successfully" do
        sort_string = "priority:desc,status:asc,implementation-order"
        parsed_sorts = described_class.parse_sorts(sort_string)
        validation_errors = described_class.validate_sorts(parsed_sorts)

        expect(parsed_sorts.size).to eq(3)
        expect(validation_errors).to be_empty

        expect(parsed_sorts[0].attribute).to eq("priority")
        expect(parsed_sorts[0].direction).to eq(:desc)
        expect(parsed_sorts[1].attribute).to eq("status")
        expect(parsed_sorts[1].direction).to eq(:asc)
        expect(parsed_sorts[2].implementation_order?).to be true
      end

      it "handles invalid sort string with partial success" do
        sort_string = "priority:desc,invalid_attr:bad_dir,status:asc"
        parsed_sorts = described_class.parse_sorts(sort_string)
        validation_errors = described_class.validate_sorts(parsed_sorts)

        expect(parsed_sorts.size).to eq(2)  # invalid_attr:bad_dir gets filtered out during parsing
        expect(validation_errors).to be_empty  # remaining sorts are valid
      end
    end

    context "SortCriteria with real task data" do
      it "extracts correct sort values from various task types" do
        tasks = [basic_task, task_with_frontmatter, task_without_id_pattern]

        id_sort = described_class::SortCriteria.new("id", :asc, "id:asc")
        status_sort = described_class::SortCriteria.new("status", :asc, "status:asc")
        priority_sort = described_class::SortCriteria.new("priority", :asc, "priority:asc")

        # Test ID sorting values
        expect(id_sort.get_sort_value(tasks[0])).to eq(1)  # v.1.0+task.001
        expect(id_sort.get_sort_value(tasks[1])).to eq(2)  # v.1.0+task.002
        expect(id_sort.get_sort_value(tasks[2])).to eq(Float::INFINITY)  # invalid pattern

        # Test status sorting values
        expect(status_sort.get_sort_value(tasks[0])).to eq(1)  # pending
        expect(status_sort.get_sort_value(tasks[1])).to eq(0)  # in-progress

        # Test priority sorting values
        expect(priority_sort.get_sort_value(tasks[0])).to eq(0)  # high
        expect(priority_sort.get_sort_value(tasks[1])).to eq(1)  # medium
      end
    end
  end
end
