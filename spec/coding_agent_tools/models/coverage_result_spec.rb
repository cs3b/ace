# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Models::CoverageResult do
  let(:file_path) { "/project/lib/example.rb" }
  let(:total_lines) { 20 }
  let(:covered_lines) { 15 }
  let(:coverage_percentage) { 75.0 }
  let(:methods) { [] }

  subject do
    described_class.new(
      file_path: file_path,
      total_lines: total_lines,
      covered_lines: covered_lines,
      coverage_percentage: coverage_percentage,
      methods: methods
    )
  end

  describe "#initialize" do
    it "sets all attributes correctly" do
      expect(subject.file_path).to eq(file_path)
      expect(subject.total_lines).to eq(total_lines)
      expect(subject.covered_lines).to eq(covered_lines)
      expect(subject.coverage_percentage).to eq(coverage_percentage)
      expect(subject.methods).to eq(methods)
    end
  end

  describe "#under_threshold?" do
    it "returns true when coverage is below threshold" do
      expect(subject.under_threshold?(80)).to be true
    end

    it "returns false when coverage meets threshold" do
      expect(subject.under_threshold?(75)).to be false
    end

    it "returns false when coverage exceeds threshold" do
      expect(subject.under_threshold?(70)).to be false
    end
  end

  describe "#uncovered_lines_count" do
    it "calculates uncovered lines correctly" do
      expect(subject.uncovered_lines_count).to eq(5)
    end
  end

  describe "#relative_path" do
    context "with absolute path containing lib/" do
      let(:file_path) { "/project/src/lib/example.rb" }

      it "returns path relative to lib/" do
        expect(subject.relative_path).to eq("lib/example.rb")
      end
    end

    context "with absolute path not containing lib/" do
      let(:file_path) { "/project/src/example.rb" }

      it "returns the original path" do
        expect(subject.relative_path).to eq("/project/src/example.rb")
      end
    end
  end

  describe "#to_h" do
    let(:method_coverage) do
      instance_double(CodingAgentTools::Models::MethodCoverage, to_h: {name: "test_method"})
    end
    let(:methods) { [method_coverage] }

    it "returns hash representation" do
      expected_hash = {
        file_path: file_path,
        relative_path: subject.relative_path,
        total_lines: total_lines,
        covered_lines: covered_lines,
        coverage_percentage: coverage_percentage,
        uncovered_lines_count: 5,
        methods: [{name: "test_method"}]
      }

      expect(subject.to_h).to eq(expected_hash)
    end
  end
end