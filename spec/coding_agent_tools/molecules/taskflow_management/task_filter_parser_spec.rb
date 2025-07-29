# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::TaskFilterParser do
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
        :symbol_attr => "symbol_value"
      }
    )
  end

  let(:task_without_frontmatter) do
    task_data_class.new(
      id: "v.1.0+task.003",
      status: "done",
      priority: "low",
      dependencies: [],
      title: "Task without frontmatter",
      frontmatter: nil
    )
  end

  describe "FilterCriteria", :FilterCriteria do
    let(:filter_criteria) { described_class::FilterCriteria.new("status", "pending", false, "status:pending") }

    describe "#matches?" do
      context "with direct attribute access" do
        it "matches when attribute value equals filter value" do
          expect(filter_criteria.matches?(basic_task)).to be true
        end

        it "does not match when attribute value differs from filter value" do
          task = task_data_class.new(status: "done")
          expect(filter_criteria.matches?(task)).to be false
        end

        it "handles case insensitive matching" do
          task = task_data_class.new(status: "PENDING")
          expect(filter_criteria.matches?(task)).to be true
        end
      end

      context "with frontmatter attribute access" do
        let(:frontmatter_filter) { described_class::FilterCriteria.new("custom_attr", "custom_value", false, "custom_attr:custom_value") }

        it "matches frontmatter string keys" do
          expect(frontmatter_filter.matches?(task_with_frontmatter)).to be true
        end

        it "does not match frontmatter symbol keys (only string keys are supported)" do
          symbol_filter = described_class::FilterCriteria.new("symbol_attr", "symbol_value", false, "symbol_attr:symbol_value")
          expect(symbol_filter.matches?(task_with_frontmatter)).to be false
        end

        it "does not match when frontmatter attribute is missing" do
          expect(frontmatter_filter.matches?(basic_task)).to be false
        end

        it "does not match when task has no frontmatter" do
          expect(frontmatter_filter.matches?(task_without_frontmatter)).to be false
        end
      end

      context "with OR values (pipe-separated)" do
        let(:or_filter) { described_class::FilterCriteria.new("status", "pending|in-progress", false, "status:pending|in-progress") }

        it "matches first OR value" do
          pending_task = task_data_class.new(status: "pending")
          expect(or_filter.matches?(pending_task)).to be true
        end

        it "matches second OR value" do
          in_progress_task = task_data_class.new(status: "in-progress")
          expect(or_filter.matches?(in_progress_task)).to be true
        end

        it "does not match values not in OR list" do
          done_task = task_data_class.new(status: "done")
          expect(or_filter.matches?(done_task)).to be false
        end

        it "handles whitespace around pipe separators" do
          spaced_filter = described_class::FilterCriteria.new("status", "pending | in-progress", false, "status:pending | in-progress")
          pending_task = task_data_class.new(status: "pending")
          expect(spaced_filter.matches?(pending_task)).to be true
        end
      end

      context "with array attributes" do
        let(:dependency_filter) { described_class::FilterCriteria.new("dependencies", "v.1.0+task.001", false, "dependencies:v.1.0+task.001") }

        it "matches when array contains the filter value" do
          task = task_data_class.new(dependencies: ["v.1.0+task.001", "v.1.0+task.002"])
          expect(dependency_filter.matches?(task)).to be true
        end

        it "does not match when array does not contain the filter value" do
          task = task_data_class.new(dependencies: ["v.1.0+task.002", "v.1.0+task.003"])
          expect(dependency_filter.matches?(task)).to be false
        end

        it "handles empty arrays" do
          task = task_data_class.new(dependencies: [])
          expect(dependency_filter.matches?(task)).to be false
        end

        it "works with OR values for array attributes" do
          or_dependency_filter = described_class::FilterCriteria.new("dependencies", "v.1.0+task.001|v.1.0+task.003", false, "dependencies:v.1.0+task.001|v.1.0+task.003")
          task = task_data_class.new(dependencies: ["v.1.0+task.003"])
          expect(or_dependency_filter.matches?(task)).to be true
        end
      end

      context "with negation" do
        let(:negated_filter) { described_class::FilterCriteria.new("status", "done", true, "status:!done") }

        it "returns true when attribute does not match negated value" do
          pending_task = task_data_class.new(status: "pending")
          expect(negated_filter.matches?(pending_task)).to be true
        end

        it "returns false when attribute matches negated value" do
          done_task = task_data_class.new(status: "done")
          expect(negated_filter.matches?(done_task)).to be false
        end

        it "works with OR values in negation" do
          negated_or_filter = described_class::FilterCriteria.new("status", "pending|done", true, "status:!pending|done")
          in_progress_task = task_data_class.new(status: "in-progress")
          expect(negated_or_filter.matches?(in_progress_task)).to be true
        end
      end

      context "with nil and missing attributes" do
        it "returns false when attribute is nil" do
          task = task_data_class.new(status: nil)
          expect(filter_criteria.matches?(task)).to be false
        end

        it "returns false when attribute is missing" do
          minimal_task = Struct.new(:id).new("task.001")
          expect(filter_criteria.matches?(minimal_task)).to be false
        end

        it "returns false when frontmatter is nil" do
          task = task_data_class.new(frontmatter: nil)
          frontmatter_filter = described_class::FilterCriteria.new("custom_attr", "value", false, "custom_attr:value")
          expect(frontmatter_filter.matches?(task)).to be false
        end
      end

      context "with type coercion" do
        it "handles numeric values" do
          task = task_data_class.new(priority: 1)
          numeric_filter = described_class::FilterCriteria.new("priority", "1", false, "priority:1")
          expect(numeric_filter.matches?(task)).to be true
        end

        it "handles boolean values through frontmatter" do
          task = task_data_class.new(frontmatter: {"active" => true})
          boolean_filter = described_class::FilterCriteria.new("active", "true", false, "active:true")
          expect(boolean_filter.matches?(task)).to be true
        end
      end
    end
  end

  describe ".parse_filter", :parse_filter do
    context "with valid filter strings" do
      it "parses simple attribute:value format" do
        result = described_class.parse_filter("status:pending")
        
        expect(result).to be_a(described_class::FilterCriteria)
        expect(result.attribute).to eq("status")
        expect(result.value).to eq("pending")
        expect(result.negated).to be false
        expect(result.raw_filter).to eq("status:pending")
      end

      it "parses negated filter with exclamation mark" do
        result = described_class.parse_filter("priority:!low")
        
        expect(result).to be_a(described_class::FilterCriteria)
        expect(result.attribute).to eq("priority")
        expect(result.value).to eq("low")
        expect(result.negated).to be true
        expect(result.raw_filter).to eq("priority:!low")
      end

      it "parses OR values with pipes" do
        result = described_class.parse_filter("status:pending|in-progress")
        
        expect(result.attribute).to eq("status")
        expect(result.value).to eq("pending|in-progress")
        expect(result.negated).to be false
      end

      it "handles whitespace around attribute and value" do
        result = described_class.parse_filter("  status  :  pending  ")
        
        expect(result.attribute).to eq("status")
        expect(result.value).to eq("pending")
        expect(result.negated).to be false
      end

      it "handles whitespace around negated value" do
        result = described_class.parse_filter("status: ! done ")
        
        expect(result.attribute).to eq("status")
        expect(result.value).to eq("done")
        expect(result.negated).to be true
      end

      it "handles values with multiple colons" do
        result = described_class.parse_filter("url:https://example.com:8080")
        
        expect(result.attribute).to eq("url")
        expect(result.value).to eq("https://example.com:8080")
        expect(result.negated).to be false
      end

      it "handles complex attribute names" do
        result = described_class.parse_filter("custom_attr_123:value")
        
        expect(result.attribute).to eq("custom_attr_123")
        expect(result.value).to eq("value")
        expect(result.negated).to be false
      end
    end

    context "with invalid filter strings" do
      it "returns nil for empty string" do
        expect(described_class.parse_filter("")).to be_nil
      end

      it "returns nil for nil input" do
        expect(described_class.parse_filter(nil)).to be_nil
      end

      it "returns nil for non-string input" do
        expect(described_class.parse_filter(123)).to be_nil
        expect(described_class.parse_filter([])).to be_nil
        expect(described_class.parse_filter({})).to be_nil
      end

      it "returns nil for string without colon" do
        expect(described_class.parse_filter("status")).to be_nil
        expect(described_class.parse_filter("pending")).to be_nil
      end

      it "returns nil for string with empty attribute" do
        expect(described_class.parse_filter(":pending")).to be_nil
        expect(described_class.parse_filter("  :pending")).to be_nil
      end

      it "returns nil for string with empty value" do
        expect(described_class.parse_filter("status:")).to be_nil
        expect(described_class.parse_filter("status:  ")).to be_nil
      end

      it "returns nil for negated filter with empty value after exclamation" do
        expect(described_class.parse_filter("status:!")).to be_nil
        expect(described_class.parse_filter("status:! ")).to be_nil
      end

      it "returns nil for string with only colon" do
        expect(described_class.parse_filter(":")).to be_nil
      end

      it "returns nil for string with only whitespace" do
        expect(described_class.parse_filter("   ")).to be_nil
      end
    end

    context "edge cases" do
      it "handles single character attribute and value" do
        result = described_class.parse_filter("a:b")
        
        expect(result.attribute).to eq("a")
        expect(result.value).to eq("b")
      end

      it "handles special characters in values" do
        result = described_class.parse_filter("pattern:@#$%^&*()")
        
        expect(result.attribute).to eq("pattern")
        expect(result.value).to eq("@#$%^&*()")
      end

      it "handles unicode characters" do
        result = described_class.parse_filter("title:测试任务")
        
        expect(result.attribute).to eq("title")
        expect(result.value).to eq("测试任务")
      end
    end
  end

  describe ".parse_filters", :parse_filters do
    context "with valid filter string arrays" do
      it "parses multiple valid filters" do
        filters = ["status:pending", "priority:high", "dependencies:!empty"]
        result = described_class.parse_filters(filters)
        
        expect(result.size).to eq(3)
        expect(result.first.attribute).to eq("status")
        expect(result[1].attribute).to eq("priority")
        expect(result[2].attribute).to eq("dependencies")
        expect(result[2].negated).to be true
      end

      it "handles empty array" do
        result = described_class.parse_filters([])
        expect(result).to eq([])
      end

      it "skips invalid filters but keeps valid ones" do
        filters = ["status:pending", "invalid_filter", "priority:high", "", nil]
        result = described_class.parse_filters(filters)
        
        expect(result.size).to eq(2)
        expect(result.first.attribute).to eq("status")
        expect(result[1].attribute).to eq("priority")
      end

      it "handles array with all invalid filters" do
        filters = ["invalid", "", nil, 123]
        result = described_class.parse_filters(filters)
        
        expect(result).to eq([])
      end

      it "handles mixed valid and invalid filter types" do
        filters = ["status:pending", 123, "priority:high", {}, "title:test"]
        result = described_class.parse_filters(filters)
        
        expect(result.size).to eq(3)
        expect(result.map(&:attribute)).to eq(["status", "priority", "title"])
      end
    end

    context "with invalid inputs" do
      it "returns empty array for nil input" do
        expect(described_class.parse_filters(nil)).to eq([])
      end

      it "returns empty array for non-array input" do
        expect(described_class.parse_filters("string")).to eq([])
        expect(described_class.parse_filters(123)).to eq([])
        expect(described_class.parse_filters({})).to eq([])
      end
    end

    context "with large arrays" do
      it "handles large number of filters efficiently" do
        filters = 100.times.map { |i| "attr#{i}:value#{i}" }
        result = described_class.parse_filters(filters)
        
        expect(result.size).to eq(100)
        expect(result.first.attribute).to eq("attr0")
        expect(result.last.attribute).to eq("attr99")
      end
    end
  end

  describe ".validate_filters", :validate_filters do
    let(:valid_filters) do
      [
        described_class::FilterCriteria.new("status", "pending", false, "status:pending"),
        described_class::FilterCriteria.new("priority", "high", false, "priority:high"),
        described_class::FilterCriteria.new("dependencies", "task.001", false, "dependencies:task.001")
      ]
    end

    let(:mixed_filters) do
      [
        described_class::FilterCriteria.new("status", "pending", false, "status:pending"),
        described_class::FilterCriteria.new("123invalid", "value", false, "123invalid:value"),
        described_class::FilterCriteria.new("priority", "high", false, "priority:high")
      ]
    end

    let(:custom_valid_filters) do
      [
        described_class::FilterCriteria.new("custom_field", "value", false, "custom_field:value"),
        described_class::FilterCriteria.new("another_field", "value", false, "another_field:value")
      ]
    end

    context "with valid filters" do
      it "returns empty error array for all known attributes" do
        errors = described_class.validate_filters(valid_filters)
        expect(errors).to eq([])
      end

      it "returns empty error array for valid custom attributes" do
        errors = described_class.validate_filters(custom_valid_filters)
        expect(errors).to eq([])
      end

      it "handles empty filter array" do
        errors = described_class.validate_filters([])
        expect(errors).to eq([])
      end

      it "validates known task attributes" do
        known_attrs = %w[id status dependencies title priority estimate sort]
        filters = known_attrs.map { |attr| described_class::FilterCriteria.new(attr, "value", false, "#{attr}:value") }
        
        errors = described_class.validate_filters(filters)
        expect(errors).to eq([])
      end
    end

    context "with invalid filters" do
      it "returns errors for invalid attribute names" do
        invalid_filters = [
          described_class::FilterCriteria.new("123invalid", "value", false, "123invalid:value"),
          described_class::FilterCriteria.new("invalid-attr", "value", false, "invalid-attr:value"),
          described_class::FilterCriteria.new("", "value", false, ":value")
        ]
        
        errors = described_class.validate_filters(invalid_filters)
        expect(errors.size).to eq(3)
        expect(errors).to all(start_with("Invalid filter attribute:"))
      end

      it "returns specific error messages for each invalid attribute" do
        invalid_filters = [
          described_class::FilterCriteria.new("123invalid", "value", false, "123invalid:value"),
          described_class::FilterCriteria.new("special@char", "value", false, "special@char:value")
        ]
        
        errors = described_class.validate_filters(invalid_filters)
        expect(errors).to include("Invalid filter attribute: 123invalid")
        expect(errors).to include("Invalid filter attribute: special@char")
      end

      it "validates mixed valid and invalid filters" do
        errors = described_class.validate_filters(mixed_filters)
        expect(errors.size).to eq(1)
        expect(errors.first).to eq("Invalid filter attribute: 123invalid")
      end
    end

    context "with edge cases" do
      it "handles nil input" do
        errors = described_class.validate_filters(nil)
        expect(errors).to eq([])
      end

      it "handles non-array input" do
        errors = described_class.validate_filters("not an array")
        expect(errors).to eq([])
      end

      it "validates attribute name patterns" do
        test_cases = [
          ["valid_attr", true],
          ["validAttr", true],
          ["valid123", true],
          ["_valid", true],
          ["123invalid", false],
          ["invalid-attr", false],
          ["invalid.attr", false],
          ["invalid@attr", false],
          ["", false]
        ]

        test_cases.each do |attr_name, should_be_valid|
          filter = described_class::FilterCriteria.new(attr_name, "value", false, "#{attr_name}:value")
          errors = described_class.validate_filters([filter])
          
          if should_be_valid
            expect(errors).to be_empty, "Expected '#{attr_name}' to be valid but got errors: #{errors}"
          else
            expect(errors).not_to be_empty, "Expected '#{attr_name}' to be invalid but got no errors"
          end
        end
      end
    end

    context "with special attribute names" do
      it "allows underscore-separated names" do
        filter = described_class::FilterCriteria.new("custom_field_name", "value", false, "custom_field_name:value")
        errors = described_class.validate_filters([filter])
        expect(errors).to be_empty
      end

      it "allows camelCase names" do
        filter = described_class::FilterCriteria.new("camelCaseField", "value", false, "camelCaseField:value")
        errors = described_class.validate_filters([filter])
        expect(errors).to be_empty
      end

      it "allows names starting with underscore" do
        filter = described_class::FilterCriteria.new("_privateField", "value", false, "_privateField:value")
        errors = described_class.validate_filters([filter])
        expect(errors).to be_empty
      end
    end
  end

  describe "integration scenarios" do
    context "parsing and validating complex filter strings" do
      it "handles complete workflow from string to validated filters" do
        filter_strings = [
          "status:pending|in-progress",
          "priority:!low",
          "dependencies:v.1.0+task.001",
          "custom_field:custom_value"
        ]

        # Parse filters
        filters = described_class.parse_filters(filter_strings)
        expect(filters.size).to eq(4)

        # Validate filters
        errors = described_class.validate_filters(filters)
        expect(errors).to be_empty

        # Test matching against tasks
        matching_task = task_data_class.new(
          status: "pending",
          priority: "high",
          dependencies: ["v.1.0+task.001"],
          frontmatter: {"custom_field" => "custom_value"}
        )

        expect(filters.all? { |filter| filter.matches?(matching_task) }).to be true
      end

      it "handles error cases in complete workflow" do
        filter_strings = [
          "status:pending",
          "invalid_string",
          "123invalid:value",
          ""
        ]

        # Parse filters (should skip invalid ones)
        filters = described_class.parse_filters(filter_strings)
        expect(filters.size).to eq(2) # Only "status:pending" and "123invalid:value" parsed

        # Validate filters (should find validation error)
        errors = described_class.validate_filters(filters)
        expect(errors.size).to eq(1)
        expect(errors.first).to include("123invalid")
      end
    end

    context "performance with large datasets" do
      it "handles large numbers of filters efficiently" do
        # Create 100 valid filters
        filter_strings = 100.times.map { |i| "field#{i}:value#{i}" }
        
        filters = described_class.parse_filters(filter_strings)
        expect(filters.size).to eq(100)
        
        errors = described_class.validate_filters(filters)
        expect(errors).to be_empty
      end

      it "handles complex matching scenarios efficiently" do
        # Create task with many attributes
        complex_task = task_data_class.new(
          status: "pending",
          priority: "high",
          dependencies: (1..50).map { |i| "task.#{i}" },
          frontmatter: (1..50).each_with_object({}) { |i, h| h["field#{i}"] = "value#{i}" }
        )

        # Create filters that should match
        filters = [
          described_class::FilterCriteria.new("status", "pending", false, "status:pending"),
          described_class::FilterCriteria.new("dependencies", "task.25", false, "dependencies:task.25"),
          described_class::FilterCriteria.new("field25", "value25", false, "field25:value25")
        ]

        expect(filters.all? { |filter| filter.matches?(complex_task) }).to be true
      end
    end
  end
end