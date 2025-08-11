# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Models::ClaudeValidationResult do
  describe "initialization" do
    it "creates result with all attributes" do
      result = described_class.new(
        workflow_count: 10,
        command_count: 8,
        missing: ["task1", "task2"],
        outdated: [{command: "old.md", reason: "hash mismatch"}],
        duplicates: [{name: "dup", locations: ["a", "b"]}],
        orphaned: [{name: "orphan", location: "somewhere"}],
        valid: ["valid1", "valid2", "valid3"]
      )

      expect(result.workflow_count).to eq(10)
      expect(result.command_count).to eq(8)
      expect(result.missing).to eq(["task1", "task2"])
      expect(result.outdated.size).to eq(1)
      expect(result.duplicates.size).to eq(1)
      expect(result.orphaned.size).to eq(1)
      expect(result.valid).to eq(["valid1", "valid2", "valid3"])
    end

    it "initializes with default values" do
      result = described_class.new

      expect(result.workflow_count).to eq(0)
      expect(result.command_count).to eq(0)
      expect(result.missing).to eq([])
      expect(result.outdated).to eq([])
      expect(result.duplicates).to eq([])
      expect(result.orphaned).to eq([])
      expect(result.valid).to eq([])
    end
  end

  describe "#has_issues?" do
    it "returns true when there are missing commands" do
      result = described_class.new(missing: ["task1"])
      expect(result.has_issues?).to be true
    end

    it "returns true when there are outdated commands" do
      result = described_class.new(outdated: [{command: "old.md"}])
      expect(result.has_issues?).to be true
    end

    it "returns true when there are duplicate commands" do
      result = described_class.new(duplicates: [{name: "dup"}])
      expect(result.has_issues?).to be true
    end

    it "returns false when no issues" do
      result = described_class.new(valid: ["cmd1", "cmd2"])
      expect(result.has_issues?).to be false
    end
  end

  describe "#summary_counts" do
    it "returns counts for all categories" do
      result = described_class.new(
        missing: ["a", "b"],
        outdated: [{command: "c"}],
        duplicates: [{name: "d"}, {name: "e"}],
        orphaned: [{name: "f"}],
        valid: ["g", "h", "i"]
      )

      counts = result.summary_counts
      expect(counts).to eq({
        missing_count: 2,
        outdated_count: 1,
        duplicate_count: 2,
        orphaned_count: 1,
        valid_count: 3
      })
    end
  end

  describe "#all_valid?" do
    it "returns true when no issues and no missing" do
      result = described_class.new(valid: ["cmd1"])
      expect(result.all_valid?).to be true
    end

    it "returns false when there are issues" do
      result = described_class.new(missing: ["cmd1"])
      expect(result.all_valid?).to be false
    end
  end

  describe "#total_issues" do
    it "sums up all issue counts" do
      result = described_class.new(
        missing: ["a", "b"],
        outdated: [{command: "c"}],
        duplicates: [{name: "d"}]
      )

      expect(result.total_issues).to eq(4)
    end
  end

  describe "#summary_message" do
    it "returns success message when no issues" do
      result = described_class.new(valid: ["cmd1"])
      expect(result.summary_message).to eq("All commands are valid and up to date")
    end

    it "returns issue summary when problems exist" do
      result = described_class.new(
        missing: ["a", "b"],
        outdated: [{command: "c"}],
        duplicates: [{name: "d"}]
      )

      expect(result.summary_message).to eq("Summary: 2 missing, 1 outdated, 1 duplicate")
    end
  end
end
