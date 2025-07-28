# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "json"

RSpec.describe CodingAgentTools::Organisms::CoverageAnalyzer do
  subject(:analyzer) { described_class.new }

  let(:mock_data_processor) { instance_double(CodingAgentTools::Molecules::CoverageDataProcessor) }
  let(:mock_file_analyzer) { instance_double(CodingAgentTools::Molecules::FileAnalyzer) }
  let(:mock_report_formatter) { instance_double(CodingAgentTools::Molecules::ReportFormatter) }
  let(:mock_threshold_validator) { instance_double(CodingAgentTools::Atoms::ThresholdValidator) }
  let(:mock_adaptive_calculator) { instance_double(CodingAgentTools::Atoms::AdaptiveThresholdCalculator) }

  let(:analyzer_with_mocks) do
    described_class.new(
      data_processor: mock_data_processor,
      file_analyzer: mock_file_analyzer,
      report_formatter: mock_report_formatter,
      threshold_validator: mock_threshold_validator,
      adaptive_threshold_calculator: mock_adaptive_calculator
    )
  end

  let(:sample_processed_data) do
    {
      total_files: 2,
      processed_files: 2,
      frameworks: ["RSpec"],
      timestamp: 1753640000,
      file_coverage: {
        "/test/lib/example.rb" => {
          coverage_data: {
            total_lines: 10,
            covered_lines: 8,
            coverage_percentage: 80.0
          },
          lines_data: [nil, 1, 0, 1, nil, 1, 1, 0, 1, 1, nil],
          uncovered_details: {
            uncovered_lines: [3, 8],
            uncovered_ranges: ["3", "8"],
            total_uncovered: 2
          }
        },
        "/test/lib/another.rb" => {
          coverage_data: {
            total_lines: 5,
            covered_lines: 2,
            coverage_percentage: 40.0
          },
          lines_data: [nil, 0, 0, 1, 1, nil],
          uncovered_details: {
            uncovered_lines: [2, 3],
            uncovered_ranges: ["2-3"],
            total_uncovered: 3
          }
        }
      }
    }
  end

  let(:sample_coverage_result) do
    instance_double(
      CodingAgentTools::Models::CoverageResult,
      file_path: "/test/lib/example.rb",
      total_lines: 10,
      covered_lines: 8,
      coverage_percentage: 80.0,
      methods: [],
      uncovered_details: { uncovered_lines: [3, 8], uncovered_ranges: ["3", "8"], total_uncovered: 2 }
    )
  end

  let(:sample_coverage_result_low) do
    instance_double(
      CodingAgentTools::Models::CoverageResult,
      file_path: "/test/lib/another.rb",
      total_lines: 5,
      covered_lines: 2,
      coverage_percentage: 40.0,
      methods: [],
      uncovered_details: { uncovered_lines: [2, 3], uncovered_ranges: ["2-3"], total_uncovered: 3 }
    )
  end

  let(:sample_analysis_result) do
    instance_double(
      CodingAgentTools::Models::CoverageAnalysisResult,
      files: [sample_coverage_result, sample_coverage_result_low],
      threshold: 85.0,
      analysis_timestamp: Time.now,
      under_covered_files: [sample_coverage_result_low]
    )
  end

  # Sample SimpleCov data structures for testing extract_coverage_data
  let(:simplecov_new_format) do
    {
      "RSpec" => {
        "coverage" => {
          "/test/lib/example.rb" => {
            "lines" => [nil, 1, 0, 2, nil, 1]
          },
          "/test/lib/another.rb" => {
            "lines" => [nil, 0, 1, 1]
          }
        },
        "timestamp" => 1753640000
      }
    }
  end

  let(:simplecov_old_format) do
    {
      "RSpec" => {
        "coverage" => {
          "/test/lib/example.rb" => [nil, 1, 0, 2, nil, 1],
          "/test/lib/another.rb" => [nil, 0, 1, 1]
        },
        "timestamp" => 1753640000
      }
    }
  end

  let(:processed_format) do
    {
      files: [
        { coverage_percentage: 80.0 },
        { coverage_percentage: 40.0 }
      ]
    }
  end

  describe "#initialize" do
    it "creates instance with default dependencies" do
      expect(analyzer).to be_a(described_class)
    end

    it "accepts custom dependencies" do
      custom_analyzer = described_class.new(
        data_processor: mock_data_processor,
        file_analyzer: mock_file_analyzer,
        report_formatter: mock_report_formatter,
        threshold_validator: mock_threshold_validator,
        adaptive_threshold_calculator: mock_adaptive_calculator
      )
      expect(custom_analyzer).to be_a(described_class)
    end
  end

  describe "#analyze_coverage" do
    let(:file_path) { "/test/coverage/.resultset.json" }
    let(:options) { { threshold: 85.0 } }
    
    before do
      allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
      allow(mock_data_processor).to receive(:process_file).with(file_path, anything).and_return(sample_processed_data)
      allow(mock_file_analyzer).to receive(:analyze_files).and_return([sample_coverage_result, sample_coverage_result_low])
    end

    context "with fixed threshold" do
      it "performs complete coverage analysis workflow" do
        result = analyzer_with_mocks.analyze_coverage(file_path, options)

        expect(mock_data_processor).to have_received(:process_file).with(file_path, anything)
        expect(mock_file_analyzer).to have_received(:analyze_files).with(
          sample_processed_data,
          hash_including(threshold: 85.0)
        )
        expect(result).to be_a(CodingAgentTools::Models::CoverageAnalysisResult)
        expect(result.threshold).to eq(85.0)
        expect(result.adaptive_threshold_used?).to be false
      end

      it "validates options before processing" do
        analyzer_with_mocks.analyze_coverage(file_path, options)
        expect(mock_threshold_validator).to have_received(:validate_threshold).with(85.0)
      end

      it "passes correct options to file analyzer" do
        custom_options = {
          threshold: 90.0,
          sort_by: 'uncovered_lines',
          detailed_analysis: true
        }
        
        allow(mock_threshold_validator).to receive(:validate_threshold).with(90.0).and_return(90.0)
        
        analyzer_with_mocks.analyze_coverage(file_path, custom_options)
        
        expect(mock_file_analyzer).to have_received(:analyze_files).with(
          sample_processed_data,
          hash_including(
            threshold: 90.0,
            sort_by: 'uncovered_lines',
            detailed_analysis: true
          )
        )
      end
    end

    context "with adaptive threshold" do
      let(:adaptive_options) { { adaptive_threshold: true } }
      let(:adaptive_result) do
        {
          optimal_threshold: 75.0,
          reasoning: "Optimal threshold based on distribution",
          statistics: { median: 60.0, mean: 65.0 }
        }
      end

      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
        allow(mock_adaptive_calculator).to receive(:calculate_optimal_threshold).and_return(adaptive_result)
      end

      it "uses adaptive threshold when requested" do
        result = analyzer_with_mocks.analyze_coverage(file_path, adaptive_options)

        expect(mock_adaptive_calculator).to have_received(:calculate_optimal_threshold)
        expect(mock_file_analyzer).to have_received(:analyze_files).with(
          sample_processed_data,
          hash_including(threshold: 75.0)
        )
        expect(result.threshold).to eq(75.0)
        expect(result.adaptive_threshold_used?).to be true
        expect(result.adaptive_threshold_result).to eq(adaptive_result)
      end

      it "extracts coverage data for adaptive calculation" do
        analyzer_with_mocks.analyze_coverage(file_path, adaptive_options)
        
        # The coverage data should be extracted and passed to the adaptive calculator
        # Note: extract_coverage_data returns empty array for our sample format
        expect(mock_adaptive_calculator).to have_received(:calculate_optimal_threshold).with([])
      end
    end

    context "with default options" do
      it "uses sensible defaults" do
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
        
        analyzer_with_mocks.analyze_coverage(file_path)
        
        expect(mock_file_analyzer).to have_received(:analyze_files).with(
          sample_processed_data,
          hash_including(
            threshold: 85.0,
            sort_by: 'coverage',
            detailed_analysis: false
          )
        )
      end
    end
  end

  describe "#determine_final_threshold" do
    let(:validated_options_fixed) { { threshold: 85.0, adaptive_threshold: false } }
    let(:validated_options_adaptive) { { threshold: 85.0, adaptive_threshold: true } }
    let(:adaptive_result) do
      {
        optimal_threshold: 75.0,
        reasoning: "Calculated based on distribution"
      }
    end

    before do
      allow(mock_adaptive_calculator).to receive(:calculate_optimal_threshold).and_return(adaptive_result)
    end

    context "with fixed threshold" do
      it "returns the provided threshold with no adaptive result" do
        threshold, adaptive_result_returned = analyzer_with_mocks.send(:determine_final_threshold, sample_processed_data, validated_options_fixed)
        
        expect(threshold).to eq(85.0)
        expect(adaptive_result_returned).to be_nil
      end
    end

    context "with adaptive threshold" do
      it "calculates and returns adaptive threshold with result" do
        threshold, adaptive_result_returned = analyzer_with_mocks.send(:determine_final_threshold, sample_processed_data, validated_options_adaptive)
        
        expect(threshold).to eq(75.0)
        expect(adaptive_result_returned).to eq(adaptive_result)
        expect(mock_adaptive_calculator).to have_received(:calculate_optimal_threshold)
      end

      it "extracts coverage data for adaptive calculation" do
        analyzer_with_mocks.send(:determine_final_threshold, sample_processed_data, validated_options_adaptive)
        
        # Note: extract_coverage_data returns empty array for our sample format
        expect(mock_adaptive_calculator).to have_received(:calculate_optimal_threshold).with([])
      end
    end
  end

  describe "#extract_coverage_data" do
    context "with processed format data" do
      it "extracts coverage percentages from files array" do
        result = analyzer.send(:extract_coverage_data, processed_format)
        
        expect(result).to eq([
          { coverage_percentage: 80.0 },
          { coverage_percentage: 40.0 }
        ])
      end
    end

    context "with SimpleCov new format (hash with lines key)" do
      it "calculates coverage percentages from lines data" do
        result = analyzer.send(:extract_coverage_data, simplecov_new_format)
        
        # First file: [nil, 1, 0, 2, nil, 1] -> 4 executable, 3 covered = 75%
        # Second file: [nil, 0, 1, 1] -> 3 executable, 2 covered = 66.67%
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result[0][:coverage_percentage]).to be_within(0.1).of(75.0)
        expect(result[1][:coverage_percentage]).to be_within(0.1).of(66.67)
      end
    end

    context "with SimpleCov old format (direct array)" do
      it "calculates coverage percentages from direct array data" do
        result = analyzer.send(:extract_coverage_data, simplecov_old_format)
        
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result[0][:coverage_percentage]).to be_within(0.1).of(75.0)
        expect(result[1][:coverage_percentage]).to be_within(0.1).of(66.67)
      end
    end

    context "with multiple test frameworks" do
      let(:multi_framework_data) do
        {
          "RSpec" => {
            "coverage" => {
              "/test/lib/example.rb" => { "lines" => [nil, 1, 0, 1, nil] }
            }
          },
          "MiniTest" => {
            "coverage" => {
              "/test/lib/example.rb" => { "lines" => [nil, 0, 1, 1, nil] },
              "/test/lib/another.rb" => { "lines" => [nil, 1, 1] }
            }
          }
        }
      end

      it "aggregates coverage from all frameworks" do
        result = analyzer.send(:extract_coverage_data, multi_framework_data)
        
        # Should process all files from all frameworks (may have duplicates)
        expect(result.length).to be >= 2
        
        # All entries should have coverage_percentage
        expect(result).to all(include(:coverage_percentage))
      end
    end

    context "with empty or invalid data" do
      it "returns empty array for nil data" do
        result = analyzer.send(:extract_coverage_data, nil)
        expect(result).to eq([])
      end

      it "returns empty array for empty hash" do
        result = analyzer.send(:extract_coverage_data, {})
        expect(result).to eq([])
      end

      it "handles files with no executable lines" do
        no_lines_data = {
          "RSpec" => {
            "coverage" => {
              "/test/lib/empty.rb" => { "lines" => [nil, nil, nil] }
            }
          }
        }
        
        result = analyzer.send(:extract_coverage_data, no_lines_data)
        expect(result).to eq([])
      end

      it "skips files with nil coverage data" do
        nil_coverage_data = {
          "RSpec" => {
            "coverage" => {
              "/test/lib/valid.rb" => { "lines" => [nil, 1, 0, 1] },
              "/test/lib/invalid.rb" => nil
            }
          }
        }
        
        result = analyzer.send(:extract_coverage_data, nil_coverage_data)
        expect(result.length).to eq(1)
      end
    end

    context "with array format data" do
      let(:array_data) do
        [
          { coverage_percentage: 90.0 },
          { coverage_percentage: 45.0 }
        ]
      end

      it "handles array format directly" do
        result = analyzer.send(:extract_coverage_data, array_data)
        
        expect(result).to eq([
          { coverage_percentage: 90.0 },
          { coverage_percentage: 45.0 }
        ])
      end

      it "defaults missing coverage_percentage to 0" do
        array_data_missing = [
          { file: "example.rb" },
          { coverage_percentage: 45.0 }
        ]
        
        result = analyzer.send(:extract_coverage_data, array_data_missing)
        
        expect(result).to eq([
          { coverage_percentage: 0.0 },
          { coverage_percentage: 45.0 }
        ])
      end
    end
  end

  describe "#calculate_median_coverage" do
    let(:files_odd) do
      [
        double(coverage_percentage: 90.0),
        double(coverage_percentage: 70.0),
        double(coverage_percentage: 50.0)
      ]
    end

    let(:files_even) do
      [
        double(coverage_percentage: 80.0),
        double(coverage_percentage: 60.0),
        double(coverage_percentage: 40.0),
        double(coverage_percentage: 20.0)
      ]
    end

    let(:single_file) do
      [double(coverage_percentage: 75.0)]
    end

    it "calculates median for odd number of files" do
      result = analyzer.send(:calculate_median_coverage, files_odd)
      expect(result).to eq(70.0)
    end

    it "calculates median for even number of files" do
      result = analyzer.send(:calculate_median_coverage, files_even)
      expect(result).to eq(50.0) # (60.0 + 40.0) / 2
    end

    it "handles single file" do
      result = analyzer.send(:calculate_median_coverage, single_file)
      expect(result).to eq(75.0)
    end

    it "handles empty file list" do
      result = analyzer.send(:calculate_median_coverage, [])
      expect(result).to be_nil
    end
  end

  describe "#validate_options" do
    before do
      allow(mock_threshold_validator).to receive(:validate_threshold).and_return(85.0)
    end

    it "validates and sets default options" do
      result = analyzer_with_mocks.send(:validate_options, {})
      
      expect(result).to include(
        threshold: 85.0,
        adaptive_threshold: false,
        include_patterns: ["**/lib/**/*.rb"],
        exclude_patterns: ["**/spec/**", "**/test/**"],
        detailed_analysis: false,
        sort_by: 'coverage'
      )
    end

    it "validates custom threshold" do
      analyzer_with_mocks.send(:validate_options, { threshold: 90.0 })
      expect(mock_threshold_validator).to have_received(:validate_threshold).with(90.0)
    end

    it "accepts valid sort_by options" do
      %w[coverage uncovered_lines file_name].each do |sort_option|
        result = analyzer_with_mocks.send(:validate_options, { sort_by: sort_option })
        expect(result[:sort_by]).to eq(sort_option)
      end
    end

    it "raises error for invalid sort_by option" do
      expect {
        analyzer_with_mocks.send(:validate_options, { sort_by: 'invalid_option' })
      }.to raise_error(ArgumentError, /Invalid sort_by option: invalid_option/)
    end

    it "preserves custom options" do
      custom_options = {
        threshold: 95.0,
        adaptive_threshold: true,
        include_patterns: ["**/app/**"],
        exclude_patterns: ["**/tmp/**"],
        detailed_analysis: true,
        sort_by: 'uncovered_lines'
      }
      
      result = analyzer_with_mocks.send(:validate_options, custom_options)
      
      expect(result).to include(
        adaptive_threshold: true,
        include_patterns: ["**/app/**"],
        exclude_patterns: ["**/tmp/**"],
        detailed_analysis: true,
        sort_by: 'uncovered_lines'
      )
    end
  end

  describe "#prioritize_critical_files" do
    let(:under_covered_files) do
      [
        double(priority_score: 85.0),
        double(priority_score: 92.0),
        double(priority_score: 78.0),
        double(priority_score: 88.0)
      ]
    end

    before do
      allow(sample_analysis_result).to receive(:under_covered_files).and_return(under_covered_files)
      allow(mock_file_analyzer).to receive(:calculate_priority_score).and_return(85.0, 92.0, 78.0, 88.0)
    end

    it "returns files sorted by priority score descending" do
      result = analyzer_with_mocks.prioritize_critical_files(sample_analysis_result, 10)
      
      # Should be sorted: 92.0, 88.0, 85.0, 78.0
      expect(result).to eq([
        under_covered_files[1], # 92.0
        under_covered_files[3], # 88.0
        under_covered_files[0], # 85.0
        under_covered_files[2]  # 78.0
      ])
    end

    it "limits results to specified count" do
      result = analyzer_with_mocks.prioritize_critical_files(sample_analysis_result, 2)
      
      expect(result.length).to eq(2)
      expect(result).to eq([
        under_covered_files[1], # 92.0
        under_covered_files[3]  # 88.0
      ])
    end

    it "uses default limit of 10" do
      result = analyzer_with_mocks.prioritize_critical_files(sample_analysis_result)
      
      expect(result.length).to eq(4) # All files since we have less than 10
    end

    it "calculates priority scores for each file" do
      analyzer_with_mocks.prioritize_critical_files(sample_analysis_result)
      
      under_covered_files.each do |file|
        expect(mock_file_analyzer).to have_received(:calculate_priority_score).with(file, sample_analysis_result.threshold)
      end
    end
  end

  describe "#generate_statistics" do
    let(:files) do
      [
        double(coverage_percentage: 90.0, total_lines: 100),
        double(coverage_percentage: 70.0, total_lines: 50),
        double(coverage_percentage: 40.0, total_lines: 150)
      ]
    end

    let(:under_covered_files) do
      [
        double(coverage_percentage: 70.0, total_lines: 50),
        double(coverage_percentage: 40.0, total_lines: 150)
      ]
    end

    let(:base_stats) { { total_files: 3, total_methods: 25 } }

    before do
      allow(sample_analysis_result).to receive(:files).and_return(files)
      allow(sample_analysis_result).to receive(:under_covered_files).and_return(under_covered_files)
      allow(sample_analysis_result).to receive(:threshold).and_return(85.0)
      allow(mock_report_formatter).to receive(:generate_summary_stats).and_return(base_stats)
    end

    it "includes base statistics from report formatter" do
      result = analyzer_with_mocks.generate_statistics(sample_analysis_result)
      
      expect(result).to include(base_stats)
    end

    it "calculates coverage trends" do
      result = analyzer_with_mocks.generate_statistics(sample_analysis_result)
      
      coverage_trends = result[:coverage_trends]
      expect(coverage_trends[:worst_file]).to eq(files[2]) # 40.0%
      expect(coverage_trends[:best_file]).to eq(files[0])  # 90.0%
      expect(coverage_trends[:average_coverage]).to be_within(0.1).of(66.67) # (90+70+40)/3
      expect(coverage_trends[:median_coverage]).to eq(70.0)
    end

    it "calculates urgency metrics" do
      result = analyzer_with_mocks.generate_statistics(sample_analysis_result)
      
      urgency_metrics = result[:urgency_metrics]
      expect(urgency_metrics[:critical_files_count]).to eq(1) # coverage < 50%
      expect(urgency_metrics[:needs_attention_count]).to eq(1) # 50% <= coverage < 85%
      expect(urgency_metrics[:large_uncovered_files]).to eq(1) # >100 lines and <70% coverage
    end
  end

  describe "integration with dependencies" do
    context "with real dependencies" do
      it "creates real instances by default" do
        real_analyzer = described_class.new
        
        expect(real_analyzer.instance_variable_get(:@data_processor)).to be_a(CodingAgentTools::Molecules::CoverageDataProcessor)
        expect(real_analyzer.instance_variable_get(:@file_analyzer)).to be_a(CodingAgentTools::Molecules::FileAnalyzer)
        expect(real_analyzer.instance_variable_get(:@report_formatter)).to be_a(CodingAgentTools::Molecules::ReportFormatter)
        expect(real_analyzer.instance_variable_get(:@threshold_validator)).to be_a(CodingAgentTools::Atoms::ThresholdValidator)
        expect(real_analyzer.instance_variable_get(:@adaptive_threshold_calculator)).to be_a(CodingAgentTools::Atoms::AdaptiveThresholdCalculator)
      end
    end
  end

  describe "error handling" do
    context "when data processor fails" do
      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).and_return(85.0)
        allow(mock_data_processor).to receive(:process_file).and_raise(StandardError, "File not found")
      end

      it "propagates data processor errors" do
        expect {
          analyzer_with_mocks.analyze_coverage("/nonexistent.json")
        }.to raise_error(StandardError, "File not found")
      end
    end

    context "when threshold validator fails" do
      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).and_raise(CodingAgentTools::Atoms::ThresholdValidator::ValidationError, "Invalid threshold")
      end

      it "propagates validation errors" do
        expect {
          analyzer_with_mocks.analyze_coverage("/test.json", { threshold: -10 })
        }.to raise_error(CodingAgentTools::Atoms::ThresholdValidator::ValidationError, "Invalid threshold")
      end
    end

    context "when adaptive threshold calculator fails" do
      let(:adaptive_options) { { adaptive_threshold: true } }

      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).and_return(85.0)
        allow(mock_data_processor).to receive(:process_file).and_return(sample_processed_data)
        allow(mock_adaptive_calculator).to receive(:calculate_optimal_threshold).and_raise(StandardError, "Calculation failed")
      end

      it "propagates adaptive calculator errors" do
        expect {
          analyzer_with_mocks.analyze_coverage("/test.json", adaptive_options)
        }.to raise_error(StandardError, "Calculation failed")
      end
    end
  end

  describe "edge cases" do
    context "with empty coverage data" do
      let(:empty_processed_data) do
        {
          total_files: 0,
          processed_files: 0,
          frameworks: [],
          timestamp: Time.now.to_i,
          file_coverage: {}
        }
      end

      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).and_return(85.0)
        allow(mock_data_processor).to receive(:process_file).and_return(empty_processed_data)
        allow(mock_file_analyzer).to receive(:analyze_files).and_return([])
      end

      it "handles empty coverage data gracefully" do
        result = analyzer_with_mocks.analyze_coverage("/empty.json")
        
        expect(result).to be_a(CodingAgentTools::Models::CoverageAnalysisResult)
        expect(result.files).to eq([])
        expect(result.threshold).to eq(85.0)
      end
    end

    context "with malformed SimpleCov data" do
      let(:malformed_data) do
        {
          "InvalidFramework" => {
            "not_coverage" => "invalid_structure"
          }
        }
      end

      it "extracts empty coverage data from malformed input" do
        result = analyzer.send(:extract_coverage_data, malformed_data)
        expect(result).to eq([])
      end
    end

    context "with mixed valid and invalid files" do
      let(:mixed_data) do
        {
          "RSpec" => {
            "coverage" => {
              "/valid/file.rb" => { "lines" => [nil, 1, 0, 1] },
              "/invalid/file.rb" => "not_an_array_or_hash"
            }
          }
        }
      end

      it "processes valid files and skips invalid ones" do
        result = analyzer.send(:extract_coverage_data, mixed_data)
        expect(result.length).to eq(1)
        expect(result[0][:coverage_percentage]).to be_within(0.1).of(66.67)
      end
    end
  end
end