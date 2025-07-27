# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Models::CoverageAnalysisResult do
  let(:threshold) { 80.0 }
  let(:analysis_timestamp) { Time.new(2025, 1, 27, 12, 0, 0) }
  
  let(:method1) do
    instance_double(
      CodingAgentTools::Models::MethodCoverage,
      under_threshold?: true
    ).tap do |method|
      allow(method).to receive(:to_h) do |format: :compact|
        case format
        when :compact
          {name: "method1"}
        when :verbose
          {name: "method1", coverage_percentage: 50.0}
        else
          {name: "method1"}
        end
      end
    end
  end

  let(:method2) do
    instance_double(
      CodingAgentTools::Models::MethodCoverage,
      under_threshold?: false
    ).tap do |method|
      allow(method).to receive(:to_h) do |format: :compact|
        case format
        when :compact
          {name: "method2"}
        when :verbose
          {name: "method2", coverage_percentage: 90.0}
        else
          {name: "method2"}
        end
      end
    end
  end

  let(:file1) do
    instance_double(
      CodingAgentTools::Models::CoverageResult,
      under_threshold?: true,
      methods: [method1, method2],
      total_lines: 100,
      covered_lines: 70
    ).tap do |file|
      allow(file).to receive(:to_h) do |format: :compact|
        case format
        when :compact
          nil  # Returns nil for compact format if no methods need tests
        when :verbose
          {file_path: "lib/file1.rb"}
        else
          {file_path: "lib/file1.rb"}
        end
      end
    end
  end

  let(:file2) do
    instance_double(
      CodingAgentTools::Models::CoverageResult,
      under_threshold?: false,
      methods: [],
      total_lines: 50,
      covered_lines: 45
    ).tap do |file|
      allow(file).to receive(:to_h) do |format: :compact|
        case format
        when :compact
          nil  # Returns nil for compact format if no methods need tests
        when :verbose
          {file_path: "lib/file2.rb"}
        else
          {file_path: "lib/file2.rb"}
        end
      end
    end
  end

  let(:files) { [file1, file2] }

  subject do
    described_class.new(
      files: files,
      threshold: threshold,
      analysis_timestamp: analysis_timestamp
    )
  end

  describe "#initialize" do
    it "sets all attributes correctly" do
      expect(subject.files).to eq(files)
      expect(subject.threshold).to eq(threshold)
      expect(subject.analysis_timestamp).to eq(analysis_timestamp)
    end

    it "defaults timestamp to current time" do
      result = described_class.new(files: files, threshold: threshold)
      expect(result.analysis_timestamp).to be_within(1).of(Time.now)
    end
  end

  describe "#under_covered_files" do
    it "returns files below threshold" do
      expect(subject.under_covered_files).to eq([file1])
    end

    it "memoizes the result" do
      expect(files.first).to receive(:under_threshold?).once.and_return(true)
      expect(files.last).to receive(:under_threshold?).once.and_return(false)
      
      2.times { subject.under_covered_files }
    end
  end

  describe "#under_covered_methods" do
    it "returns methods below threshold from all files" do
      expect(subject.under_covered_methods).to eq([method1])
    end

    it "memoizes the result" do
      expect(method1).to receive(:under_threshold?).once.and_return(true)
      expect(method2).to receive(:under_threshold?).once.and_return(false)
      
      2.times { subject.under_covered_methods }
    end
  end

  describe "#total_files" do
    it "returns total number of files" do
      expect(subject.total_files).to eq(2)
    end
  end

  describe "#total_methods" do
    it "returns total number of methods across all files" do
      expect(subject.total_methods).to eq(2)
    end
  end

  describe "#overall_coverage_percentage" do
    it "calculates overall coverage percentage" do
      # (70 + 45) / (100 + 50) * 100 = 76.67%
      expect(subject.overall_coverage_percentage).to eq(76.67)
    end

    context "when no executable lines" do
      let(:files) { [] }

      it "returns 0.0" do
        expect(subject.overall_coverage_percentage).to eq(0.0)
      end
    end
  end

  describe "#summary_stats" do
    it "returns summary statistics" do
      expected_stats = {
        total_files: 2,
        total_methods: 2,
        under_covered_files_count: 1,
        under_covered_methods_count: 1,
        overall_coverage_percentage: 76.67,
        threshold: 80.0,
        analysis_timestamp: "2025-01-27T12:00:00+00:00"
      }

      expect(subject.summary_stats).to eq(expected_stats)
    end
  end

  describe "#to_h" do
    context "with compact format (default)" do
      it "returns array of under-covered files only" do
        # Since compact format returns only under-covered files that have methods needing tests
        # and our mock files return nil from to_h(format: :compact), expect empty array
        expect(subject.to_h).to eq([])
      end
    end

    context "with verbose format" do
      it "returns full hash representation" do
        expected_hash = {
          summary: subject.summary_stats,
          files: subject.files.map { |f| f.to_h(format: :verbose) },
          under_covered_files: subject.under_covered_files.map { |f| f.to_h(format: :verbose) },
          under_covered_methods: subject.under_covered_methods.map { |m| m.to_h(format: :verbose) }
        }

        expect(subject.to_h(format: :verbose)).to eq(expected_hash)
      end
    end
  end
end