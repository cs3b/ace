# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Models::MethodCoverage do
  let(:name) { "test_method" }
  let(:start_line) { 5 }
  let(:end_line) { 15 }
  let(:total_lines) { 8 }
  let(:covered_lines) { 6 }
  let(:coverage_percentage) { 75.0 }

  subject do
    described_class.new(
      name: name,
      start_line: start_line,
      end_line: end_line,
      total_lines: total_lines,
      covered_lines: covered_lines,
      coverage_percentage: coverage_percentage
    )
  end

  describe "#initialize" do
    it "sets all attributes correctly" do
      expect(subject.name).to eq(name)
      expect(subject.start_line).to eq(start_line)
      expect(subject.end_line).to eq(end_line)
      expect(subject.total_lines).to eq(total_lines)
      expect(subject.covered_lines).to eq(covered_lines)
      expect(subject.coverage_percentage).to eq(coverage_percentage)
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

  describe "#line_range" do
    it "returns correct range" do
      expect(subject.line_range).to eq(5..15)
    end
  end

  describe "#uncovered_lines_count" do
    it "calculates uncovered lines correctly" do
      expect(subject.uncovered_lines_count).to eq(2)
    end
  end

  describe "#to_h" do
    it "returns hash representation" do
      expected_hash = {
        name: name,
        start_line: start_line,
        end_line: end_line,
        total_lines: total_lines,
        covered_lines: covered_lines,
        coverage_percentage: coverage_percentage,
        uncovered_lines_count: 2
      }

      expect(subject.to_h).to eq(expected_hash)
    end
  end
end