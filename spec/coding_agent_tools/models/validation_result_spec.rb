# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/validation_result"

RSpec.describe CodingAgentTools::Models::ValidationResult do
  let(:sample_findings) do
    [
      {type: "style", message: "Use single quotes", correctable: true},
      {type: "layout", message: "Extra whitespace", correctable: true},
      {type: "naming", message: "Use snake_case", correctable: false}
    ]
  end

  let(:sample_errors) do
    [
      {type: "syntax", message: "Unexpected token"},
      {type: "reference", message: "Undefined variable"}
    ]
  end

  let(:sample_warnings) do
    [
      {type: "deprecated", message: "Method deprecated"},
      {type: "performance", message: "Inefficient algorithm"}
    ]
  end

  let(:sample_metadata) do
    {linter_version: "1.0.0", run_time: "2024-01-06T14:30:52Z"}
  end

  let(:valid_attributes) do
    {
      success: true,
      linter: "rubocop",
      language: "ruby",
      findings: sample_findings,
      errors: sample_errors,
      warnings: sample_warnings,
      exit_code: 0,
      duration: 2.5,
      metadata: sample_metadata
    }
  end

  describe "#initialize" do
    it "creates a new validation result with all attributes" do
      result = described_class.new(valid_attributes)

      expect(result.success).to be(true)
      expect(result.linter).to eq("rubocop")
      expect(result.language).to eq("ruby")
      expect(result.findings).to eq(sample_findings)
      expect(result.errors).to eq(sample_errors)
      expect(result.warnings).to eq(sample_warnings)
      expect(result.exit_code).to eq(0)
      expect(result.duration).to eq(2.5)
      expect(result.metadata).to eq(sample_metadata)
    end

    it "initializes with default values when not provided" do
      result = described_class.new

      expect(result.success).to be(false)
      expect(result.linter).to be_nil
      expect(result.language).to be_nil
      expect(result.findings).to eq([])
      expect(result.errors).to eq([])
      expect(result.warnings).to eq([])
      expect(result.exit_code).to be_nil
      expect(result.duration).to be_nil
      expect(result.metadata).to eq({})
    end

    it "handles partial attributes correctly" do
      partial_attributes = {
        success: false,
        linter: "eslint",
        findings: sample_findings
      }

      result = described_class.new(partial_attributes)

      expect(result.success).to be(false)
      expect(result.linter).to eq("eslint")
      expect(result.findings).to eq(sample_findings)
      expect(result.errors).to eq([])
      expect(result.warnings).to eq([])
      expect(result.metadata).to eq({})
    end
  end

  describe "#issue_count" do
    it "returns total count of findings and errors" do
      result = described_class.new(valid_attributes)
      expected_count = sample_findings.size + sample_errors.size
      expect(result.issue_count).to eq(expected_count)
    end

    it "returns 0 when no findings or errors" do
      result = described_class.new(findings: [], errors: [])
      expect(result.issue_count).to eq(0)
    end

    it "counts only findings when no errors" do
      result = described_class.new(findings: sample_findings, errors: [])
      expect(result.issue_count).to eq(sample_findings.size)
    end

    it "counts only errors when no findings" do
      result = described_class.new(findings: [], errors: sample_errors)
      expect(result.issue_count).to eq(sample_errors.size)
    end

    it "handles nil findings and errors gracefully" do
      result = described_class.new(findings: nil, errors: nil)
      expect(result.issue_count).to eq(0)
    end
  end

  describe "#has_issues?" do
    it "returns true when issues are present" do
      result = described_class.new(valid_attributes)
      expect(result.has_issues?).to be(true)
    end

    it "returns false when no issues" do
      result = described_class.new(findings: [], errors: [])
      expect(result.has_issues?).to be(false)
    end

    it "returns true when only findings are present" do
      result = described_class.new(findings: sample_findings, errors: [])
      expect(result.has_issues?).to be(true)
    end

    it "returns true when only errors are present" do
      result = described_class.new(findings: [], errors: sample_errors)
      expect(result.has_issues?).to be(true)
    end

    it "is consistent with issue_count" do
      test_cases = [
        {findings: [], errors: []},
        {findings: sample_findings, errors: []},
        {findings: [], errors: sample_errors},
        {findings: sample_findings, errors: sample_errors}
      ]

      test_cases.each do |test_case|
        result = described_class.new(test_case)
        expect(result.has_issues?).to eq(result.issue_count > 0)
      end
    end
  end

  describe "#correctable_count" do
    it "returns count of correctable findings" do
      result = described_class.new(findings: sample_findings)
      correctable_findings = sample_findings.count { |f| f[:correctable] }
      expect(result.correctable_count).to eq(correctable_findings)
    end

    it "returns 0 when no correctable findings" do
      non_correctable_findings = [
        {type: "error", message: "Cannot fix", correctable: false},
        {type: "warning", message: "Manual fix required", correctable: false}
      ]
      result = described_class.new(findings: non_correctable_findings)
      expect(result.correctable_count).to eq(0)
    end

    it "returns 0 when no findings" do
      result = described_class.new(findings: [])
      expect(result.correctable_count).to eq(0)
    end

    it "handles findings without correctable field" do
      findings_without_correctable = [
        {type: "style", message: "Some issue"},
        {type: "layout", message: "Another issue", correctable: true}
      ]
      result = described_class.new(findings: findings_without_correctable)
      expect(result.correctable_count).to eq(1)
    end

    it "handles nil findings gracefully" do
      result = described_class.new(findings: nil)
      expect(result.correctable_count).to eq(0)
    end
  end

  describe "success status patterns" do
    it "allows explicit success true" do
      result = described_class.new(success: true)
      expect(result.success).to be(true)
    end

    it "allows explicit success false" do
      result = described_class.new(success: false)
      expect(result.success).to be(false)
    end

    it "defaults to false when not specified" do
      result = described_class.new({})
      expect(result.success).to be(false)
    end
  end

  describe "linter and language information" do
    it "accepts common linter names" do
      linters = ["rubocop", "eslint", "pylint", "prettier", "standardrb"]
      linters.each do |linter|
        result = described_class.new(linter: linter)
        expect(result.linter).to eq(linter)
      end
    end

    it "accepts common language names" do
      languages = ["ruby", "javascript", "python", "typescript", "markdown"]
      languages.each do |language|
        result = described_class.new(language: language)
        expect(result.language).to eq(language)
      end
    end
  end

  describe "duration handling" do
    it "accepts numeric duration" do
      result = described_class.new(duration: 3.14159)
      expect(result.duration).to eq(3.14159)
    end

    it "accepts integer duration" do
      result = described_class.new(duration: 42)
      expect(result.duration).to eq(42)
    end

    it "accepts zero duration" do
      result = described_class.new(duration: 0)
      expect(result.duration).to eq(0)
    end
  end

  describe "exit code handling" do
    it "accepts zero exit code (success)" do
      result = described_class.new(exit_code: 0)
      expect(result.exit_code).to eq(0)
    end

    it "accepts non-zero exit codes (failure)" do
      [1, 2, 127, 255].each do |code|
        result = described_class.new(exit_code: code)
        expect(result.exit_code).to eq(code)
      end
    end
  end

  describe "metadata handling" do
    it "preserves complex metadata structures" do
      complex_metadata = {
        version: "1.2.3",
        config: {strict: true, ignore: ["*.tmp"]},
        stats: {files_processed: 42, time_taken: 1.5}
      }

      result = described_class.new(metadata: complex_metadata)
      expect(result.metadata).to eq(complex_metadata)
    end

    it "handles empty metadata" do
      result = described_class.new(metadata: {})
      expect(result.metadata).to eq({})
    end
  end

  describe "edge cases", :edge_cases do
    it "handles very large arrays of findings" do
      large_findings = Array.new(10_000) do |i|
        {type: "issue#{i}", message: "Message #{i}", correctable: i.even?}
      end

      result = described_class.new(findings: large_findings)

      expect(result.issue_count).to eq(10_000)
      expect(result.correctable_count).to eq(5000) # Half are correctable
      expect(result.has_issues?).to be(true)
    end

    it "handles findings with complex structures" do
      complex_findings = [
        {
          type: "complex",
          message: "Complex issue",
          correctable: true,
          location: {file: "test.rb", line: 42, column: 10},
          metadata: {severity: "high", tags: ["performance"]}
        }
      ]

      result = described_class.new(findings: complex_findings)

      expect(result.findings.first[:location][:line]).to eq(42)
      expect(result.correctable_count).to eq(1)
    end

    it "handles unicode characters in messages" do
      unicode_findings = [
        {type: "style", message: "Use émojis 🚀 correctly", correctable: true},
        {type: "naming", message: "Variable ñame should be snake_case", correctable: false}
      ]

      result = described_class.new(findings: unicode_findings)

      expect(result.findings.first[:message]).to include("🚀")
      expect(result.findings.last[:message]).to include("ñame")
    end

    it "handles very long durations" do
      very_long_duration = 999_999.999999
      result = described_class.new(duration: very_long_duration)
      expect(result.duration).to eq(very_long_duration)
    end

    it "handles negative durations gracefully" do
      negative_duration = -1.5
      result = described_class.new(duration: negative_duration)
      expect(result.duration).to eq(negative_duration)
    end

    it "handles very large exit codes" do
      large_exit_code = 999_999
      result = described_class.new(exit_code: large_exit_code)
      expect(result.exit_code).to eq(large_exit_code)
    end

    it "handles mixed data types in arrays" do
      mixed_findings = [
        {type: "string", message: "String message", correctable: true},
        {type: :symbol, message: "Symbol type", correctable: false},
        {"type" => "string_key", "message" => "String keys", "correctable" => true}
      ]

      result = described_class.new(findings: mixed_findings)

      expect(result.findings.size).to eq(3)
      # Only the first finding uses symbol keys, others use string keys
      expect(result.correctable_count).to eq(1)
    end

    it "handles nil values in findings arrays" do
      findings_with_nil = [
        {type: "valid", message: "Valid finding", correctable: true},
        nil,
        {type: "another", message: "Another finding", correctable: false}
      ]

      result = described_class.new(findings: findings_with_nil)

      expect(result.findings.size).to eq(3)
      expect(result.issue_count).to eq(3)
      # correctable_count will fail on nil - this tests the current behavior
      expect { result.correctable_count }.to raise_error(NoMethodError)
    end

    it "handles boolean-like values for correctable field" do
      boolean_findings = [
        {type: "truthy", message: "Truthy correctable", correctable: 1},
        {type: "falsy", message: "Falsy correctable", correctable: 0},
        {type: "nil", message: "Nil correctable", correctable: nil},
        {type: "string", message: "String correctable", correctable: "yes"}
      ]

      result = described_class.new(findings: boolean_findings)

      # The count method uses truthiness, so 1, 0, and "yes" should be truthy (nil is falsy)
      expect(result.correctable_count).to eq(3)
    end
  end
end
