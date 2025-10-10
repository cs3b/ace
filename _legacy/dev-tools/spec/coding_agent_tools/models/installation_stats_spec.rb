# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/installation_stats"

RSpec.describe CodingAgentTools::Models::InstallationStats do
  describe "#initialize" do
    it "initializes with default values" do
      stats = described_class.new

      expect(stats.created).to eq(0)
      expect(stats.skipped).to eq(0)
      expect(stats.updated).to eq(0)
      expect(stats.errors).to eq([])
      expect(stats.custom_commands).to eq(0)
      expect(stats.generated_commands).to eq(0)
      expect(stats.workflow_commands).to eq(0)
      expect(stats.agents).to eq(0)
    end

    it "accepts initial values" do
      stats = described_class.new(
        created: 5,
        skipped: 2,
        updated: 1,
        errors: ["error1"],
        custom_commands: 3,
        generated_commands: 2,
        workflow_commands: 0,
        agents: 1
      )

      expect(stats.created).to eq(5)
      expect(stats.skipped).to eq(2)
      expect(stats.updated).to eq(1)
      expect(stats.errors).to eq(["error1"])
      expect(stats.custom_commands).to eq(3)
      expect(stats.generated_commands).to eq(2)
      expect(stats.workflow_commands).to eq(0)
      expect(stats.agents).to eq(1)
    end
  end

  describe "#to_h" do
    it "converts to hash" do
      stats = described_class.new(created: 5, skipped: 2)
      hash = stats.to_h

      expect(hash).to be_a(Hash)
      expect(hash[:created]).to eq(5)
      expect(hash[:skipped]).to eq(2)
    end
  end

  describe "#total_commands" do
    it "calculates total commands" do
      stats = described_class.new(
        custom_commands: 3,
        generated_commands: 2,
        workflow_commands: 5
      )

      expect(stats.total_commands).to eq(10)
    end
  end

  describe "#errors?" do
    it "returns false when no errors" do
      stats = described_class.new
      expect(stats.errors?).to be false
    end

    it "returns true when errors exist" do
      stats = described_class.new(errors: ["error"])
      expect(stats.errors?).to be true
    end
  end

  describe "#add_error" do
    it "adds error message" do
      stats = described_class.new
      stats.add_error("Test error")

      expect(stats.errors).to eq(["Test error"])
    end
  end

  describe "#increment" do
    it "increments counters" do
      stats = described_class.new

      stats.increment(:created)
      expect(stats.created).to eq(1)

      stats.increment(:created, 5)
      expect(stats.created).to eq(6)
    end

    it "raises error for unknown counter" do
      stats = described_class.new

      expect do
        stats.increment(:unknown)
      end.to raise_error(ArgumentError, "Unknown counter: unknown")
    end
  end
end
