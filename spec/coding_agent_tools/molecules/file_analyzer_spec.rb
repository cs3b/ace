# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::FileAnalyzer do
  subject { described_class.new }

  let(:file_path) { "/test/lib/example.rb" }
  
  let(:file_coverage_data) do
    {
      coverage_data: {
        total_lines: 10,
        covered_lines: 6,
        coverage_percentage: 60.0
      },
      lines_data: [nil, 1, 0, 1, nil, 0, 1, nil, 1, 1, 0],
      frameworks: ["RSpec"]
    }
  end

  let(:sample_methods) do
    [
      instance_double(CodingAgentTools::Models::MethodCoverage,
        name: "covered_method", coverage_percentage: 100.0, total_lines: 3, to_h: {name: "covered_method"}),
      instance_double(CodingAgentTools::Models::MethodCoverage,
        name: "uncovered_method", coverage_percentage: 0.0, total_lines: 5, to_h: {name: "uncovered_method"}),
      instance_double(CodingAgentTools::Models::MethodCoverage,
        name: "partial_method", coverage_percentage: 50.0, total_lines: 4, to_h: {name: "partial_method"})
    ]
  end

  describe "#analyze_file" do
    before do
      # Mock the method mapper to return sample methods
      allow_any_instance_of(CodingAgentTools::Molecules::MethodCoverageMapper)
        .to receive(:map_file_coverage).and_return(sample_methods)
      
      # Mock file existence
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:readable?).with(file_path).and_return(true)
    end

    it "creates a complete coverage result" do
      result = subject.analyze_file(file_path, file_coverage_data)

      expect(result).to be_a(CodingAgentTools::Models::CoverageResult)
      expect(result.file_path).to eq(file_path)
      expect(result.total_lines).to eq(10)
      expect(result.covered_lines).to eq(6)
      expect(result.coverage_percentage).to eq(60.0)
      expect(result.methods).to eq(sample_methods)
    end

    context "when file is not readable" do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(false)
      end

      it "handles missing files gracefully" do
        expect {
          result = subject.analyze_file(file_path, file_coverage_data)
          expect(result.methods).to eq([])
        }.to output(/Warning: Cannot read source file/).to_stderr
      end
    end
  end

  describe "#analyze_files" do
    let(:processed_data) do
      {
        file_coverage: {
          "/test/lib/low_coverage.rb" => {
            coverage_data: { total_lines: 20, covered_lines: 10, coverage_percentage: 50.0 },
            lines_data: Array.new(20, 1),
            frameworks: ["RSpec"]
          },
          "/test/lib/high_coverage.rb" => {
            coverage_data: { total_lines: 15, covered_lines: 14, coverage_percentage: 93.3 },
            lines_data: Array.new(15, 1),
            frameworks: ["RSpec"]
          }
        }
      }
    end

    before do
      allow_any_instance_of(CodingAgentTools::Molecules::MethodCoverageMapper)
        .to receive(:map_file_coverage).and_return([])
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:readable?).and_return(true)
    end

    it "analyzes multiple files and prioritizes under-covered ones" do
      results = subject.analyze_files(processed_data, threshold: 80.0)

      expect(results.length).to eq(2)
      
      # Under-covered files should come first
      expect(results.first.coverage_percentage).to eq(50.0)  # low_coverage.rb
      expect(results.last.coverage_percentage).to eq(93.3)   # high_coverage.rb
    end

    it "sorts files by specified criteria" do
      results = subject.analyze_files(processed_data, sort_by: 'coverage')

      expect(results.first.coverage_percentage).to eq(50.0)  # lowest first
      expect(results.last.coverage_percentage).to eq(93.3)
    end

    it "filters for methods_only when requested" do
      allow_any_instance_of(CodingAgentTools::Molecules::MethodCoverageMapper)
        .to receive(:map_file_coverage).and_return([], sample_methods)

      results = subject.analyze_files(processed_data, methods_only: true)

      expect(results.length).to eq(1)  # Only files with methods
    end
  end

  describe "#detailed_file_analysis" do
    before do
      allow_any_instance_of(CodingAgentTools::Molecules::MethodCoverageMapper)
        .to receive(:map_file_coverage).and_return(sample_methods)
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:readable?).with(file_path).and_return(true)
    end

    it "provides comprehensive file analysis" do
      result = subject.detailed_file_analysis(file_path, file_coverage_data, threshold: 80.0)

      expect(result).to have_key(:file_info)
      expect(result).to have_key(:method_analysis)
      expect(result).to have_key(:uncovered_areas)
      expect(result).to have_key(:frameworks)
      expect(result).to have_key(:priority_score)

      expect(result[:file_info][:under_threshold]).to be true
      expect(result[:method_analysis][:total_methods]).to eq(3)
      expect(result[:frameworks]).to eq(["RSpec"])
    end

    it "analyzes uncovered line ranges" do
      result = subject.detailed_file_analysis(file_path, file_coverage_data)

      uncovered_areas = result[:uncovered_areas]
      expect(uncovered_areas).to be_an(Array)
      # Should identify ranges of uncovered lines
      expect(uncovered_areas.first).to have_key(:start_line)
      expect(uncovered_areas.first).to have_key(:end_line)
    end
  end

  describe "#calculate_priority_score" do
    let(:file_result) do
      instance_double(CodingAgentTools::Models::CoverageResult,
        under_threshold?: true,
        coverage_percentage: 60.0,
        uncovered_lines_count: 15,
        methods: sample_methods
      )
    end

    before do
      # Mock method coverage percentages and sizes
      allow(sample_methods[0]).to receive(:coverage_percentage).and_return(100.0)
      allow(sample_methods[0]).to receive(:total_lines).and_return(3)
      allow(sample_methods[1]).to receive(:coverage_percentage).and_return(0.0)  # uncovered
      allow(sample_methods[1]).to receive(:total_lines).and_return(15)  # large
      allow(sample_methods[2]).to receive(:coverage_percentage).and_return(30.0)  # low coverage
      allow(sample_methods[2]).to receive(:total_lines).and_return(12)  # large
    end

    it "calculates priority score based on coverage gaps and method analysis" do
      score = subject.calculate_priority_score(file_result, 80.0)

      expect(score).to be > 0
      # Should get points for being below threshold, uncovered lines, and problematic methods
    end
  end

  describe "private methods" do
    describe "#find_uncovered_line_ranges" do
      let(:lines_with_gaps) { [nil, 1, 0, 0, 1, nil, 0, 1, 0, 0, 0] }

      it "identifies ranges of uncovered lines" do
        ranges = subject.send(:find_uncovered_line_ranges, lines_with_gaps)

        expect(ranges.length).to eq(3)
        expect(ranges[0]).to eq({start_line: 3, end_line: 4})    # Lines 3-4
        expect(ranges[1]).to eq({start_line: 7, end_line: 7})    # Line 7
        expect(ranges[2]).to eq({start_line: 9, end_line: 11})   # Lines 9-11
      end

      it "handles nil and empty input" do
        expect(subject.send(:find_uncovered_line_ranges, nil)).to eq([])
        expect(subject.send(:find_uncovered_line_ranges, [])).to eq([])
      end
    end

    describe "#sort_file_results" do
      let(:file_results) do
        [
          instance_double(CodingAgentTools::Models::CoverageResult,
            coverage_percentage: 80.0, uncovered_lines_count: 5, relative_path: "b.rb"),
          instance_double(CodingAgentTools::Models::CoverageResult,
            coverage_percentage: 60.0, uncovered_lines_count: 10, relative_path: "a.rb")
        ]
      end

      it "sorts by coverage percentage" do
        sorted = subject.send(:sort_file_results, file_results, 'coverage')
        expect(sorted.first.coverage_percentage).to eq(60.0)  # lowest first
      end

      it "sorts by uncovered lines count" do
        sorted = subject.send(:sort_file_results, file_results, 'uncovered_lines')
        expect(sorted.first.uncovered_lines_count).to eq(10)  # most uncovered first
      end

      it "sorts by file name" do
        sorted = subject.send(:sort_file_results, file_results, 'file_name')
        expect(sorted.first.relative_path).to eq("a.rb")  # alphabetical
      end
    end
  end
end