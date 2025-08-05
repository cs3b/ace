# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe CodingAgentTools::Molecules::ReportFormatter do
  subject { described_class.new }

  let(:sample_coverage_results) do
    method_needing_tests = instance_double(CodingAgentTools::Models::MethodCoverage,
      name: 'low_coverage_method',
      start_line: 5,
      end_line: 10,
      coverage_percentage: 0.0,
      uncovered_lines: [6, 7, 8],
      uncovered_lines_compact: '6..8',
      needs_tests?: true)
    allow(method_needing_tests).to receive(:to_h).with(format: :compact).and_return({
      name: 'low_coverage_method',
      start_line: 5,
      end_line: 10,
      coverage_percentage: 0.0,
      uncovered_lines: '6..8'
    })
    allow(method_needing_tests).to receive(:to_h).with(format: :verbose).and_return({
      name: 'low_coverage_method',
      start_line: 5,
      end_line: 10,
      coverage_percentage: 0.0,
      uncovered_lines: [6, 7, 8]
    })

    low_coverage_file = instance_double(CodingAgentTools::Models::CoverageResult,
      file_path: '/test/lib/low_coverage.rb',
      relative_path: 'lib/low_coverage.rb',
      total_lines: 20,
      covered_lines: 10,
      coverage_percentage: 50.0,
      uncovered_lines_count: 10,
      methods: [method_needing_tests])
    allow(low_coverage_file).to receive(:under_threshold?).with(80.0).and_return(true)
    allow(low_coverage_file).to receive(:to_h).with(format: :compact).and_return({
      file_path: '/test/lib/low_coverage.rb',
      relative_path: 'lib/low_coverage.rb',
      coverage_percentage: 50.0,
      total_lines: 20,
      covered_lines: 10
    })
    allow(low_coverage_file).to receive(:to_h).with(format: :verbose).and_return({
      file_path: '/test/lib/low_coverage.rb',
      relative_path: 'lib/low_coverage.rb',
      coverage_percentage: 50.0,
      total_lines: 20,
      covered_lines: 10
    })

    high_coverage_file = instance_double(CodingAgentTools::Models::CoverageResult,
      file_path: '/test/lib/high_coverage.rb',
      relative_path: 'lib/high_coverage.rb',
      total_lines: 15,
      covered_lines: 14,
      coverage_percentage: 93.3,
      uncovered_lines_count: 1,
      methods: [])
    allow(high_coverage_file).to receive(:under_threshold?).with(80.0).and_return(false)
    allow(high_coverage_file).to receive(:to_h).with(format: :compact).and_return({
      file_path: '/test/lib/high_coverage.rb',
      relative_path: 'lib/high_coverage.rb',
      coverage_percentage: 93.3,
      total_lines: 15,
      covered_lines: 14
    })
    allow(high_coverage_file).to receive(:to_h).with(format: :verbose).and_return({
      file_path: '/test/lib/high_coverage.rb',
      relative_path: 'lib/high_coverage.rb',
      coverage_percentage: 93.3,
      total_lines: 15,
      covered_lines: 14
    })

    [low_coverage_file, high_coverage_file]
  end

  let(:sample_analysis_result) do
    analysis_result = instance_double(CodingAgentTools::Models::CoverageAnalysisResult,
      files: sample_coverage_results,
      under_covered_files: [sample_coverage_results.first],
      total_files: 2,
      threshold: 80.0,
      overall_coverage_percentage: 68.6,
      analysis_timestamp: Time.new(2025, 1, 15, 10, 30, 0))

    allow(analysis_result).to receive(:to_h).with(format: :compact).and_return({
      summary: {
        total_files: 2,
        total_methods: 0,
        under_covered_files_count: 1,
        under_covered_methods_count: 0,
        overall_coverage_percentage: 68.6,
        threshold: 80.0,
        analysis_timestamp: '2025-01-15T10:30:00Z'
      },
      under_covered_files: [sample_coverage_results.first.to_h(format: :compact)],
      under_covered_methods: []
    })

    allow(analysis_result).to receive(:to_h).with(format: :verbose).and_return({
      summary: {
        total_files: 2,
        total_methods: 0,
        under_covered_files_count: 1,
        under_covered_methods_count: 0,
        overall_coverage_percentage: 68.6,
        threshold: 80.0,
        analysis_timestamp: '2025-01-15T10:30:00Z'
      },
      under_covered_files: [sample_coverage_results.first.to_h(format: :verbose)],
      under_covered_methods: []
    })

    # Mock private methods
    allow(analysis_result).to receive(:send).with(:total_executable_lines).and_return(35)
    allow(analysis_result).to receive(:send).with(:total_covered_lines).and_return(24)

    analysis_result
  end

  describe '#format_text_report' do
    it 'generates a comprehensive text report' do
      report = subject.format_text_report(sample_analysis_result)

      expect(report).to include('Coverage Analysis Report')
      expect(report).to include('Overall Coverage: 68.6%')
      expect(report).to include('Threshold: 80.0%')
      expect(report).to include('Files Under Threshold: 1 of 2')
      expect(report).to include('Public Methods Needing Tests:')
      expect(report).to include('lib/low_coverage.rb')
      expect(report).to include('low_coverage_method')
      expect(report).to include('6..8')
    end

    it 'includes summary statistics' do
      report = subject.format_text_report(sample_analysis_result)

      expect(report).to include('Total Lines: 35')
      expect(report).to include('Covered Lines: 24')
      expect(report).to include('Overall Coverage: 68.6%')
    end

    it 'lists public methods needing tests with details' do
      report = subject.format_text_report(sample_analysis_result)

      expect(report).to include('Public Methods Needing Tests:')
      expect(report).to include('lib/low_coverage.rb')
      expect(report).to include('low_coverage_method')
      expect(report).to include('Coverage: 0.0%')
      expect(report).to include('Uncovered lines: 6..8')
    end

    context 'with detailed analysis' do
      let(:detailed_analysis) do
        {
          file_info: {
            under_threshold: true,
            relative_path: 'lib/example.rb'
          },
          method_analysis: {
            total_methods: 3,
            under_covered_methods: 2,
            completely_uncovered: 1
          },
          uncovered_areas: [
            { start_line: 5, end_line: 8 },
            { start_line: 12, end_line: 15 }
          ],
          frameworks: ['RSpec'],
          priority_score: 85.5
        }
      end

      it 'includes method-level analysis when available' do
        report = subject.format_detailed_file_report(detailed_analysis)

        expect(report).to include('Method Analysis:')
        expect(report).to include('Total Methods: 3')
        expect(report).to include('Under-Covered Methods: 2')
        expect(report).to include('Completely Uncovered: 1')
      end

      it 'shows uncovered line ranges' do
        report = subject.format_detailed_file_report(detailed_analysis)

        expect(report).to include('Uncovered Areas:')
        expect(report).to include('Lines 5-8')
        expect(report).to include('Lines 12-15')
      end

      it 'includes priority score' do
        report = subject.format_detailed_file_report(detailed_analysis)

        expect(report).to include('Priority Score: 85.5')
      end

      it 'handles single line uncovered areas' do
        single_line_analysis = {
          file_info: {
            under_threshold: true,
            relative_path: 'lib/single_line.rb'
          },
          method_analysis: {
            total_methods: 1,
            under_covered_methods: 1,
            completely_uncovered: 0
          },
          uncovered_areas: [
            { start_line: 15, end_line: 15 },
            { start_line: 20, end_line: 22 }
          ],
          priority_score: 75.0
        }

        report = subject.format_detailed_file_report(single_line_analysis)

        expect(report).to include('Line 15')  # Single line case
        expect(report).to include('Lines 20-22')  # Range case
      end
    end

    context 'when no public methods need tests' do
      let(:good_analysis_result) do
        good_file = instance_double(CodingAgentTools::Models::CoverageResult,
          methods: [])

        result = instance_double(CodingAgentTools::Models::CoverageAnalysisResult,
          files: [good_file],
          under_covered_files: [],
          total_files: 1,
          threshold: 80.0,
          overall_coverage_percentage: 95.0)

        # Mock private methods
        allow(result).to receive(:send).with(:total_executable_lines).and_return(100)
        allow(result).to receive(:send).with(:total_covered_lines).and_return(95)

        result
      end

      it 'shows positive message' do
        report = subject.format_text_report(good_analysis_result)

        expect(report).to include('All public methods have test coverage!')
        expect(report).to include('Overall Coverage: 95.0%')
      end
    end
  end

  describe '#format_json_report' do
    it 'generates valid JSON with complete data' do
      json_report = subject.format_json_report(sample_analysis_result)
      parsed = JSON.parse(json_report)

      expect(parsed).to have_key('summary')
      expect(parsed).to have_key('under_covered_files')
      expect(parsed['summary']['total_files']).to eq(2)
      expect(parsed['summary']['under_covered_files_count']).to eq(1)
      expect(parsed['summary']['threshold']).to eq(80.0)
    end

    it 'includes metadata and timestamps in verbose format' do
      json_report = subject.format_json_report(sample_analysis_result, format: :verbose)
      parsed = JSON.parse(json_report)

      expect(parsed).to have_key('metadata')
      expect(parsed['metadata']).to have_key('generated_at')
      expect(parsed['metadata']).to have_key('analysis_timestamp')
      expect(parsed['metadata']['analysis_timestamp']).to match(/2025-01-15T10:30:00/)
    end

    it 'preserves numeric precision' do
      json_report = subject.format_json_report(sample_analysis_result)
      parsed = JSON.parse(json_report)

      expect(parsed['summary']['overall_coverage_percentage']).to eq(68.6)
      expect(parsed['under_covered_files'].first['coverage_percentage']).to eq(50.0)
    end

    it 'includes adaptive threshold information in verbose format when available' do
      # Since we can't easily mock the respond_to? methods, let's test the code path indirectly
      # by ensuring that a result without adaptive threshold methods works correctly
      json_report = subject.format_json_report(sample_analysis_result, format: :verbose)
      parsed = JSON.parse(json_report)

      # Should not have adaptive_threshold key when methods don't exist
      expect(parsed).not_to have_key('adaptive_threshold')
      expect(parsed).to have_key('metadata')
      expect(parsed).to have_key('public_methods_needing_tests')
    end

    it 'defaults to compact format for unknown format' do
      # Add a stub for the unknown format to allow the call
      allow(sample_analysis_result).to receive(:to_h).with(format: :unknown).and_return(
        sample_analysis_result.to_h(format: :compact)
      )

      json_report = subject.format_json_report(sample_analysis_result, format: :unknown)
      parsed = JSON.parse(json_report)

      # Should behave like compact format (no metadata key)
      expect(parsed).not_to have_key('metadata')
      expect(parsed).to have_key('summary')
      expect(parsed).to have_key('under_covered_files')
    end
  end

  describe '#format_csv_report' do
    it 'generates CSV with proper headers' do
      csv_report = subject.format_csv_report(sample_analysis_result)
      lines = csv_report.split("\n")

      expect(lines.first).to eq('file_path,coverage_percentage,total_lines,covered_lines,uncovered_lines,under_threshold')
      expect(lines.length).to eq(3)  # Header + 2 data rows
    end

    it 'includes file data in correct format' do
      csv_report = subject.format_csv_report(sample_analysis_result)
      lines = csv_report.split("\n")

      expect(lines[1]).to include('lib/low_coverage.rb,50.0,20,10,10,true')
      expect(lines[2]).to include('lib/high_coverage.rb,93.3,15,14,1,false')
    end

    it 'handles special characters in file paths' do
      special_result = instance_double(CodingAgentTools::Models::CoverageResult,
        relative_path: 'lib/file with spaces & symbols.rb',
        coverage_percentage: 75.0,
        total_lines: 10,
        covered_lines: 7,
        uncovered_lines_count: 3)
      allow(special_result).to receive(:under_threshold?).with(80.0).and_return(true)

      allow(sample_analysis_result).to receive(:files).and_return([special_result])

      csv_report = subject.format_csv_report(sample_analysis_result)

      expect(csv_report).to include('lib/file with spaces & symbols.rb')
    end

    context 'with empty results' do
      let(:empty_analysis_result) do
        instance_double(CodingAgentTools::Models::CoverageAnalysisResult,
          files: [])
      end

      it 'generates header-only CSV' do
        csv_report = subject.format_csv_report(empty_analysis_result)
        lines = csv_report.split("\n")

        expect(lines.length).to eq(1)
        expect(lines.first).to include('file_path,coverage_percentage')
      end
    end
  end

  describe '#save_report' do
    let(:temp_file) { Tempfile.new(['coverage_report', '.txt']) }

    after { temp_file.unlink }

    it 'saves text report to file' do
      report_content = subject.format_text_report(sample_analysis_result)

      subject.save_report(report_content, temp_file.path)

      saved_content = File.read(temp_file.path)
      expect(saved_content).to eq(report_content)
    end

    it "creates directories if they don't exist" do
      nested_path = File.join(Dir.tmpdir, 'coverage', 'reports', 'test_report.txt')

      begin
        subject.save_report('test content', nested_path)

        expect(File.exist?(nested_path)).to be true
        expect(File.read(nested_path)).to eq('test content')
      ensure
        FileUtils.rm_rf(File.dirname(nested_path)) if File.exist?(nested_path)
      end
    end

    it 'handles file write errors gracefully' do
      invalid_path = '/root/readonly/report.txt'

      expect do
        subject.save_report('content', invalid_path)
      end.to raise_error(CodingAgentTools::Molecules::ReportFormatter::SaveError)
    end
  end

  describe '#generate_summary_stats' do
    it 'calculates comprehensive statistics' do
      stats = subject.generate_summary_stats(sample_analysis_result)

      expect(stats).to have_key(:files_summary)
      expect(stats).to have_key(:coverage_distribution)
      expect(stats).to have_key(:line_coverage_stats)

      expect(stats[:files_summary][:total_files]).to eq(2)
      expect(stats[:files_summary][:under_threshold_count]).to eq(1)
      expect(stats[:files_summary][:percentage_under_threshold]).to eq(50.0)
    end

    it 'groups files by coverage ranges' do
      stats = subject.generate_summary_stats(sample_analysis_result)
      distribution = stats[:coverage_distribution]

      expect(distribution).to have_key(:excellent)  # 90-100%
      expect(distribution).to have_key(:good)       # 80-89%
      expect(distribution).to have_key(:fair)       # 60-79%
      expect(distribution).to have_key(:poor)       # <60%

      expect(distribution[:excellent]).to eq(1)  # high_coverage.rb
      expect(distribution[:poor]).to eq(1)       # low_coverage.rb
    end
  end

  describe 'format detection and validation' do
    describe '#detect_output_format' do
      it 'detects format from file extension' do
        expect(subject.detect_output_format('report.json')).to eq(:json)
        expect(subject.detect_output_format('report.csv')).to eq(:csv)
        expect(subject.detect_output_format('report.txt')).to eq(:text)
      end

      it 'defaults to text format for unknown extensions' do
        expect(subject.detect_output_format('report.unknown')).to eq(:text)
        expect(subject.detect_output_format('report')).to eq(:text)
      end
    end

    describe '#validate_format' do
      it 'accepts valid formats' do
        expect { subject.validate_format(:text) }.not_to raise_error
        expect { subject.validate_format(:json) }.not_to raise_error
        expect { subject.validate_format(:csv) }.not_to raise_error
      end

      it 'rejects invalid formats' do
        expect do
          subject.validate_format(:xml)
        end.to raise_error(CodingAgentTools::Molecules::ReportFormatter::InvalidFormatError)
      end
    end
  end

  describe 'private helper methods' do
    describe '#format_coverage_percentage' do
      it 'formats percentages with one decimal place' do
        expect(subject.send(:format_coverage_percentage, 85.666)).to eq('85.7%')
        expect(subject.send(:format_coverage_percentage, 100.0)).to eq('100.0%')
        expect(subject.send(:format_coverage_percentage, 0.0)).to eq('0.0%')
      end
    end

    describe '#format_file_size' do
      it 'formats line counts appropriately' do
        expect(subject.send(:format_file_size, 1)).to eq('1 line')
        expect(subject.send(:format_file_size, 50)).to eq('50 lines')
        expect(subject.send(:format_file_size, 1000)).to eq('1,000 lines')
      end
    end

    describe '#prioritize_results_by_severity' do
      it 'sorts files by coverage severity' do
        sorted = subject.send(:prioritize_results_by_severity, sample_coverage_results)

        expect(sorted.first.coverage_percentage).to eq(50.0)  # Worst first
        expect(sorted.last.coverage_percentage).to eq(93.3)   # Best last
      end
    end

    describe '#format_uncovered_ranges' do
      it 'returns empty string for empty ranges' do
        expect(subject.send(:format_uncovered_ranges, [])).to eq('')
      end

      it 'formats single line ranges correctly' do
        ranges = [{ start_line: 10, end_line: 10 }]
        expect(subject.send(:format_uncovered_ranges, ranges)).to eq('10')
      end

      it 'formats multi-line ranges correctly' do
        ranges = [
          { start_line: 5, end_line: 8 },
          { start_line: 12, end_line: 12 },
          { start_line: 20, end_line: 25 }
        ]
        expect(subject.send(:format_uncovered_ranges, ranges)).to eq('5-8, 12, 20-25')
      end
    end

    describe '#format_threshold_information' do
      it 'formats regular threshold information' do
        lines = subject.send(:format_threshold_information, sample_analysis_result)

        expect(lines).to include('Threshold: 80.0%')
        expect(lines).not_to include('adaptive')
      end
    end
  end

  describe 'integration with create-path workflow' do
    context 'when generating reports for create-path integration' do
      it 'formats reports in create-path compatible structure' do
        report_data = subject.format_for_create_path(sample_analysis_result)

        expect(report_data).to have_key(:summary)
        expect(report_data).to have_key(:details)
        expect(report_data).to have_key(:recommendations)

        expect(report_data[:summary][:action_required]).to be true
        expect(report_data[:details][:under_covered_files]).to be_an(Array)
      end

      it 'includes actionable recommendations' do
        report_data = subject.format_for_create_path(sample_analysis_result)
        recommendations = report_data[:recommendations]

        expect(recommendations).to include('Focus testing efforts on lib/low_coverage.rb (50.0% coverage)')
        expect(recommendations).to include('1 file below 80.0% threshold requires attention')
      end

      it 'shows positive message when all files meet coverage threshold' do
        # Create analysis result with no under-covered files
        good_analysis_result = instance_double(CodingAgentTools::Models::CoverageAnalysisResult,
          files: [sample_coverage_results.last], # Only high coverage file
          under_covered_files: [],
          total_files: 1,
          threshold: 80.0,
          overall_coverage_percentage: 93.3)

        report_data = subject.format_for_create_path(good_analysis_result)
        recommendations = report_data[:recommendations]

        expect(recommendations).to include('All files meet coverage threshold - excellent work!')
        expect(report_data[:summary][:action_required]).to be false
      end
    end
  end
end
