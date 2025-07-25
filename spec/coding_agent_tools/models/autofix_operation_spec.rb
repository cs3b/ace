# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/autofix_operation"

RSpec.describe CodingAgentTools::Models::AutofixOperation do
  let(:valid_attributes) do
    {
      file: "test.rb",
      line: 10,
      column: 5,
      original_content: "original code",
      fixed_content: "fixed code",
      linter: "rubocop",
      rule: "Style/StringLiterals",
      description: "Use single quotes",
      applied: false,
      error: nil
    }
  end

  describe "#initialize" do
    it "creates a new autofix operation with valid attributes" do
      operation = described_class.new(valid_attributes)

      expect(operation.file).to eq("test.rb")
      expect(operation.line).to eq(10)
      expect(operation.column).to eq(5)
      expect(operation.original_content).to eq("original code")
      expect(operation.fixed_content).to eq("fixed code")
      expect(operation.linter).to eq("rubocop")
      expect(operation.rule).to eq("Style/StringLiterals")
      expect(operation.description).to eq("Use single quotes")
      expect(operation.applied).to be(false)
      expect(operation.error).to be_nil
    end

    it "sets applied to false by default" do
      operation = described_class.new(valid_attributes.except(:applied))
      expect(operation.applied).to be(false)
    end

    it "allows applied to be explicitly set to true" do
      operation = described_class.new(valid_attributes.merge(applied: true))
      expect(operation.applied).to be(true)
    end

    it "accepts nil values for optional fields" do
      minimal_attributes = { file: "test.rb" }
      operation = described_class.new(minimal_attributes)

      expect(operation.file).to eq("test.rb")
      expect(operation.line).to be_nil
      expect(operation.column).to be_nil
      expect(operation.original_content).to be_nil
      expect(operation.fixed_content).to be_nil
      expect(operation.linter).to be_nil
      expect(operation.rule).to be_nil
      expect(operation.description).to be_nil
      expect(operation.applied).to be(false)
      expect(operation.error).to be_nil
    end
  end

  describe "#successful?" do
    it "returns true when applied is true and error is nil" do
      operation = described_class.new(valid_attributes.merge(applied: true, error: nil))
      expect(operation.successful?).to be(true)
    end

    it "returns false when applied is false" do
      operation = described_class.new(valid_attributes.merge(applied: false, error: nil))
      expect(operation.successful?).to be(false)
    end

    it "returns false when error is present even if applied is true" do
      operation = described_class.new(valid_attributes.merge(applied: true, error: "Some error"))
      expect(operation.successful?).to be(false)
    end

    it "returns false when both applied is false and error is present" do
      operation = described_class.new(valid_attributes.merge(applied: false, error: "Some error"))
      expect(operation.successful?).to be(false)
    end
  end

  describe "#failed?" do
    it "returns false when operation is successful" do
      operation = described_class.new(valid_attributes.merge(applied: true, error: nil))
      expect(operation.failed?).to be(false)
    end

    it "returns true when operation is not successful" do
      operation = described_class.new(valid_attributes.merge(applied: false, error: nil))
      expect(operation.failed?).to be(true)
    end

    it "returns true when error is present" do
      operation = described_class.new(valid_attributes.merge(applied: true, error: "Some error"))
      expect(operation.failed?).to be(true)
    end
  end

  describe "data integrity" do
    it "maintains data consistency between successful? and failed?" do
      operations = [
        described_class.new(valid_attributes.merge(applied: true, error: nil)),
        described_class.new(valid_attributes.merge(applied: false, error: nil)),
        described_class.new(valid_attributes.merge(applied: true, error: "error")),
        described_class.new(valid_attributes.merge(applied: false, error: "error"))
      ]

      operations.each do |operation|
        expect(operation.successful?).to eq(!operation.failed?)
      end
    end
  end

  describe "edge cases", :edge_cases do
    it "handles empty strings gracefully" do
      operation = described_class.new(
        file: "",
        original_content: "",
        fixed_content: "",
        linter: "",
        rule: "",
        description: ""
      )

      expect(operation.file).to eq("")
      expect(operation.original_content).to eq("")
      expect(operation.fixed_content).to eq("")
      expect(operation.successful?).to be(false)
    end

    it "handles very large line and column numbers" do
      operation = described_class.new(
        valid_attributes.merge(line: 999999, column: 999999)
      )

      expect(operation.line).to eq(999999)
      expect(operation.column).to eq(999999)
    end

    it "handles special characters in content and descriptions" do
      operation = described_class.new(
        valid_attributes.merge(
          original_content: "content with\nnewlines\tand\rtabs",
          fixed_content: "fixed with 🚀 emojis",
          description: "Description with special chars: <>?:\"{}|",
          error: "Error with unicode: ñáéíóú"
        )
      )

      expect(operation.original_content).to include("\n")
      expect(operation.fixed_content).to include("🚀")
      expect(operation.description).to include("<>?:")
      expect(operation.error).to include("ñáéíóú")
    end

    it "handles zero and negative line/column numbers" do
      operation = described_class.new(
        valid_attributes.merge(line: 0, column: -1)
      )

      expect(operation.line).to eq(0)
      expect(operation.column).to eq(-1)
    end
  end
end