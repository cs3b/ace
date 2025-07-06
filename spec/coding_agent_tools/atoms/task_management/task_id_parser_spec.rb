# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::TaskManagement::TaskIdParser do
  describe ".parse" do
    it "parses valid task ID correctly" do
      result = described_class.parse("v.0.3.0+task.05")
      expect(result).to eq({
        version: "v.0.3.0",
        sequential_number: 5
      })
    end

    it "handles single digit numbers" do
      result = described_class.parse("v.1.0.0+task.1")
      expect(result).to eq({
        version: "v.1.0.0",
        sequential_number: 1
      })
    end

    it "handles multi-digit numbers" do
      result = described_class.parse("v.2.1.3+task.123")
      expect(result).to eq({
        version: "v.2.1.3",
        sequential_number: 123
      })
    end

    it "raises ArgumentError for nil input" do
      expect { described_class.parse(nil) }.to raise_error(ArgumentError, "task_id must be a string")
    end

    it "raises ArgumentError for empty string" do
      expect { described_class.parse("") }.to raise_error(ArgumentError, "task_id cannot be nil or empty")
    end

    it "raises ArgumentError for non-string input" do
      expect { described_class.parse(123) }.to raise_error(ArgumentError, "task_id must be a string")
    end

    it "raises ArgumentError for invalid format" do
      expect { described_class.parse("invalid-format") }.to raise_error(ArgumentError, /Invalid task ID format/)
    end

    it "raises ArgumentError for missing version" do
      expect { described_class.parse("+task.05") }.to raise_error(ArgumentError, /Invalid task ID format/)
    end

    it "raises ArgumentError for missing task number" do
      expect { described_class.parse("v.0.3.0+task.") }.to raise_error(ArgumentError, /Invalid task ID format/)
    end
  end

  describe ".extract_version" do
    it "extracts version from valid task ID" do
      expect(described_class.extract_version("v.0.3.0+task.05")).to eq("v.0.3.0")
    end

    it "raises ArgumentError for invalid task ID" do
      expect { described_class.extract_version("invalid") }.to raise_error(ArgumentError)
    end
  end

  describe ".extract_sequential_number" do
    it "extracts sequential number from valid task ID" do
      expect(described_class.extract_sequential_number("v.0.3.0+task.05")).to eq(5)
    end

    it "handles leading zeros correctly" do
      expect(described_class.extract_sequential_number("v.1.0.0+task.007")).to eq(7)
    end

    it "raises ArgumentError for invalid task ID" do
      expect { described_class.extract_sequential_number("invalid") }.to raise_error(ArgumentError)
    end
  end

  describe ".valid?" do
    it "returns true for valid task ID" do
      expect(described_class.valid?("v.0.3.0+task.05")).to be true
    end

    it "returns true for various valid formats" do
      expect(described_class.valid?("v.1.0.0+task.1")).to be true
      expect(described_class.valid?("v.10.20.30+task.999")).to be true
      expect(described_class.valid?("v.0.0.1+task.01")).to be true
    end

    it "returns false for nil" do
      expect(described_class.valid?(nil)).to be false
    end

    it "returns false for empty string" do
      expect(described_class.valid?("")).to be false
    end

    it "returns false for non-string" do
      expect(described_class.valid?(123)).to be false
    end

    it "returns false for invalid formats" do
      expect(described_class.valid?("invalid")).to be false
      expect(described_class.valid?("v.0.3.0")).to be false
      expect(described_class.valid?("+task.05")).to be false
      expect(described_class.valid?("v.0.3.0+task.")).to be false
      expect(described_class.valid?("0.3.0+task.05")).to be false
    end
  end

  describe ".valid_version?" do
    it "returns true for valid version" do
      expect(described_class.valid_version?("v.0.3.0")).to be true
    end

    it "returns true for various valid versions" do
      expect(described_class.valid_version?("v.1.0.0")).to be true
      expect(described_class.valid_version?("v.10.20.30")).to be true
      expect(described_class.valid_version?("v.0.0.1")).to be true
    end

    it "returns false for nil" do
      expect(described_class.valid_version?(nil)).to be false
    end

    it "returns false for empty string" do
      expect(described_class.valid_version?("")).to be false
    end

    it "returns false for non-string" do
      expect(described_class.valid_version?(123)).to be false
    end

    it "returns false for invalid formats" do
      expect(described_class.valid_version?("0.3.0")).to be false
      expect(described_class.valid_version?("v.0.3")).to be false
      expect(described_class.valid_version?("v.0.3.0.1")).to be false
      expect(described_class.valid_version?("v.0.3.0+task.05")).to be false
    end
  end

  describe ".generate_next_id" do
    it "generates next task ID with zero padding" do
      result = described_class.generate_next_id("v.0.3.0", current_max: 4)
      expect(result).to eq("v.0.3.0+task.05")
    end

    it "generates first task ID when current_max is 0" do
      result = described_class.generate_next_id("v.1.0.0", current_max: 0)
      expect(result).to eq("v.1.0.0+task.01")
    end

    it "handles large numbers" do
      result = described_class.generate_next_id("v.2.1.0", current_max: 99)
      expect(result).to eq("v.2.1.0+task.100")
    end

    it "raises ArgumentError for invalid version" do
      expect { described_class.generate_next_id("invalid", current_max: 1) }.to raise_error(ArgumentError, /Invalid version format/)
    end

    it "raises ArgumentError for negative current_max" do
      expect { described_class.generate_next_id("v.0.3.0", current_max: -1) }.to raise_error(ArgumentError, /current_max must be a non-negative integer/)
    end

    it "raises ArgumentError for non-integer current_max" do
      expect { described_class.generate_next_id("v.0.3.0", current_max: "5") }.to raise_error(ArgumentError, /current_max must be a non-negative integer/)
    end
  end

  describe ".sort_task_ids" do
    it "sorts task IDs by version then sequential number" do
      task_ids = ["v.0.3.0+task.05", "v.0.2.0+task.10", "v.0.3.0+task.01", "v.0.3.1+task.01"]
      result = described_class.sort_task_ids(task_ids)
      expect(result).to eq(["v.0.2.0+task.10", "v.0.3.0+task.01", "v.0.3.0+task.05", "v.0.3.1+task.01"])
    end

    it "handles empty array" do
      expect(described_class.sort_task_ids([])).to eq([])
    end

    it "handles nil input" do
      expect(described_class.sort_task_ids(nil)).to eq([])
    end

    it "handles single task ID" do
      result = described_class.sort_task_ids(["v.0.3.0+task.05"])
      expect(result).to eq(["v.0.3.0+task.05"])
    end

    it "falls back to string comparison for invalid task IDs" do
      task_ids = ["v.0.3.0+task.05", "invalid", "v.0.2.0+task.01"]
      result = described_class.sort_task_ids(task_ids)
      expect(result).to include("v.0.2.0+task.01", "v.0.3.0+task.05", "invalid")
    end
  end

  describe ".compare_versions" do
    it "compares versions correctly" do
      expect(described_class.compare_versions("v.0.3.0", "v.0.2.0")).to eq(1)
      expect(described_class.compare_versions("v.0.2.0", "v.0.3.0")).to eq(-1)
      expect(described_class.compare_versions("v.0.3.0", "v.0.3.0")).to eq(0)
    end

    it "handles different version lengths" do
      expect(described_class.compare_versions("v.1.0.0", "v.1.0")).to eq(0)
      expect(described_class.compare_versions("v.1.0.1", "v.1.0")).to eq(1)
      expect(described_class.compare_versions("v.1.0", "v.1.0.1")).to eq(-1)
    end

    it "handles major version differences" do
      expect(described_class.compare_versions("v.2.0.0", "v.1.9.9")).to eq(1)
      expect(described_class.compare_versions("v.1.9.9", "v.2.0.0")).to eq(-1)
    end
  end

  describe ".extract_sequential_from_text" do
    it "extracts sequential number from text containing task ID" do
      expect(described_class.extract_sequential_from_text("v.0.3.0+task.05-implement-feature.md")).to eq(5)
    end

    it "extracts from middle of text" do
      expect(described_class.extract_sequential_from_text("some text v.0.3.0+task.123 more text")).to eq(123)
    end

    it "returns nil for text without task ID" do
      expect(described_class.extract_sequential_from_text("no task id here")).to be_nil
    end

    it "returns nil for nil input" do
      expect(described_class.extract_sequential_from_text(nil)).to be_nil
    end

    it "returns nil for empty string" do
      expect(described_class.extract_sequential_from_text("")).to be_nil
    end

    it "finds first occurrence when multiple present" do
      expect(described_class.extract_sequential_from_text("v.0.3.0+task.05 and v.0.3.0+task.10")).to eq(5)
    end
  end

  describe ".build_task_id" do
    it "builds task ID with zero padding" do
      result = described_class.build_task_id("v.0.3.0", 5)
      expect(result).to eq("v.0.3.0+task.05")
    end

    it "builds task ID without zero padding" do
      result = described_class.build_task_id("v.0.3.0", 5, zero_pad: false)
      expect(result).to eq("v.0.3.0+task.5")
    end

    it "handles large numbers" do
      result = described_class.build_task_id("v.1.0.0", 123)
      expect(result).to eq("v.1.0.0+task.123")
    end

    it "raises ArgumentError for invalid version" do
      expect { described_class.build_task_id("invalid", 5) }.to raise_error(ArgumentError, /Invalid version format/)
    end

    it "raises ArgumentError for non-positive sequential number" do
      expect { described_class.build_task_id("v.0.3.0", 0) }.to raise_error(ArgumentError, /sequential_number must be a positive integer/)
      expect { described_class.build_task_id("v.0.3.0", -1) }.to raise_error(ArgumentError, /sequential_number must be a positive integer/)
    end

    it "raises ArgumentError for non-integer sequential number" do
      expect { described_class.build_task_id("v.0.3.0", "5") }.to raise_error(ArgumentError, /sequential_number must be a positive integer/)
    end
  end

  describe ".belongs_to_version?" do
    it "returns true when task ID belongs to version" do
      expect(described_class.belongs_to_version?("v.0.3.0+task.05", "v.0.3.0")).to be true
    end

    it "returns false when task ID belongs to different version" do
      expect(described_class.belongs_to_version?("v.0.3.0+task.05", "v.0.2.0")).to be false
    end

    it "returns false for invalid task ID" do
      expect(described_class.belongs_to_version?("invalid", "v.0.3.0")).to be false
    end

    it "returns false for invalid version" do
      expect(described_class.belongs_to_version?("v.0.3.0+task.05", "invalid")).to be false
    end
  end
end
