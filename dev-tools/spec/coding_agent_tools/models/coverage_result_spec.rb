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
      instance_double(CodingAgentTools::Models::MethodCoverage)
    end
    let(:methods) { [method_coverage] }

    before do
      allow(method_coverage).to receive(:to_h).with(format: :compact).and_return({name: "test_method", uncovered_lines: "11..13"})
      allow(method_coverage).to receive(:to_h).with(format: :verbose).and_return({name: "test_method", uncovered_lines: [11, 12, 13]})
    end

    context "with compact format (default)" do
      it "returns hash representation with compact format" do
        expected_hash = {
          file_path: file_path,
          relative_path: subject.relative_path,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines_count: 5,
          uncovered_lines: "",
          uncovered_ranges: [],
          methods: [{name: "test_method", uncovered_lines: "11..13"}]
        }

        expect(subject.to_h).to eq(expected_hash)
      end

      it "returns compact format when explicitly requested" do
        expected_hash = {
          file_path: file_path,
          relative_path: subject.relative_path,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines_count: 5,
          uncovered_lines: "",
          uncovered_ranges: [],
          methods: [{name: "test_method", uncovered_lines: "11..13"}]
        }

        expect(subject.to_h(format: :compact)).to eq(expected_hash)
      end
    end

    context "with verbose format" do
      it "returns hash representation with verbose format" do
        expected_hash = {
          file_path: file_path,
          relative_path: subject.relative_path,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines_count: 5,
          uncovered_lines: [],
          uncovered_ranges: [],
          methods: [{name: "test_method", uncovered_lines: [11, 12, 13]}]
        }

        expect(subject.to_h(format: :verbose)).to eq(expected_hash)
      end
    end

    context "with uncovered lines data" do
      subject do
        described_class.new(
          file_path: file_path,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          methods: methods,
          uncovered_details: {
            uncovered_lines: [11, 12, 13, 22, 23, 25, 26, 27, 28],
            uncovered_ranges: [],
            total_uncovered: 9
          }
        )
      end

      it "formats uncovered lines compactly" do
        result = subject.to_h(format: :compact)
        expect(result[:uncovered_lines]).to eq("11..13,22,23,25..28")
      end

      it "keeps uncovered lines verbose when requested" do
        result = subject.to_h(format: :verbose)
        expect(result[:uncovered_lines]).to eq([11, 12, 13, 22, 23, 25, 26, 27, 28])
      end
    end
  end

  describe "#uncovered_lines_compact" do
    context "with uncovered lines" do
      subject do
        described_class.new(
          file_path: file_path,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_details: {
            uncovered_lines: [11, 12, 13, 22, 23, 25, 26, 27, 28],
            uncovered_ranges: [],
            total_uncovered: 9
          }
        )
      end

      it "returns compact range format" do
        expect(subject.uncovered_lines_compact).to eq("11..13,22,23,25..28")
      end

      it "caches the result" do
        expect(subject.uncovered_lines_compact).to be(subject.uncovered_lines_compact)
      end
    end

    context "with no uncovered lines" do
      it "returns empty string" do
        expect(subject.uncovered_lines_compact).to eq("")
      end
    end
  end

  describe "#uncovered_lines_verbose" do
    it "returns the original uncovered lines array" do
      expect(subject.uncovered_lines_verbose).to eq([])
    end

    context "with uncovered lines" do
      subject do
        described_class.new(
          file_path: file_path,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_details: {
            uncovered_lines: [11, 12, 13, 22, 23],
            uncovered_ranges: [],
            total_uncovered: 5
          }
        )
      end

      it "returns the original uncovered lines array" do
        expect(subject.uncovered_lines_verbose).to eq([11, 12, 13, 22, 23])
      end
    end
  end
end
