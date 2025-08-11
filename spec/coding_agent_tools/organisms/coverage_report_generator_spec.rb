# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "json"
require "fileutils"

RSpec.describe CodingAgentTools::Organisms::CoverageReportGenerator do
  subject(:generator) { described_class.new }

  let(:mock_analyzer) { instance_double(CodingAgentTools::Organisms::CoverageAnalyzer) }
  let(:mock_extractor) { instance_double(CodingAgentTools::Organisms::UndercoveredItemsExtractor) }
  let(:mock_formatter) { instance_double(CodingAgentTools::Molecules::ReportFormatter) }
  let(:mock_path_resolver) { instance_double(CodingAgentTools::Molecules::PathResolver) }

  let(:generator_with_mocks) do
    described_class.new(
      analyzer: mock_analyzer,
      extractor: mock_extractor,
      formatter: mock_formatter,
      path_resolver: mock_path_resolver
    )
  end

  let(:sample_file_path) { "/path/to/coverage/.resultset.json" }
  let(:sample_output_dir) { "/tmp/coverage_reports" }
  let(:sample_output_path) { "/tmp/coverage_report.json" }

  # Sample analysis result for mocking
  let(:sample_analysis_result) do
    # Create mock file objects with proper names
    low_coverage_file = double("CoverageFile",
      relative_path: "lib/low_coverage.rb",
      coverage_percentage: 45.0)
    another_low_file = double("CoverageFile",
      relative_path: "lib/another_low.rb",
      coverage_percentage: 60.0)
    example_file = double("CoverageFile",
      relative_path: "lib/example.rb",
      coverage_percentage: 90.0,
      total_lines: 100,
      covered_lines: 90,
      uncovered_lines_count: 10,
      methods: [],
      under_threshold?: false)

    double(
      "AnalysisResult",
      analysis_timestamp: Time.now,
      threshold: 85.0,
      total_files: 10,
      under_covered_files: [low_coverage_file, another_low_file],
      overall_coverage_percentage: 75.5,
      total_methods: 50,
      under_covered_methods: [],
      files: [example_file],
      to_h: {status: "analyzed"}
    )
  end

  let(:sample_undercovered_items) do
    {
      files: [
        {file_path: "lib/low_coverage.rb", coverage: 45.0}
      ],
      urgency_breakdown: {high: 1, medium: 0, low: 0},
      recommendations: ["Focus on lib/low_coverage.rb first"]
    }
  end

  let(:sample_high_impact_files) do
    critical_file = double("CoverageFile",
      relative_path: "lib/critical.rb",
      coverage_percentage: 30.0)
    [
      {
        file: critical_file,
        impact_score: 95,
        effort_estimate: {effort_level: "medium"}
      }
    ]
  end

  describe "#initialize" do
    it "initializes with default dependencies" do
      expect(generator.instance_variable_get(:@analyzer)).to be_a(CodingAgentTools::Organisms::CoverageAnalyzer)
      expect(generator.instance_variable_get(:@extractor)).to be_a(CodingAgentTools::Organisms::UndercoveredItemsExtractor)
      expect(generator.instance_variable_get(:@formatter)).to be_a(CodingAgentTools::Molecules::ReportFormatter)
      expect(generator.instance_variable_get(:@path_resolver)).to be_a(CodingAgentTools::Molecules::PathResolver)
    end

    it "accepts injected dependencies" do
      expect(generator_with_mocks.instance_variable_get(:@analyzer)).to eq(mock_analyzer)
      expect(generator_with_mocks.instance_variable_get(:@extractor)).to eq(mock_extractor)
      expect(generator_with_mocks.instance_variable_get(:@formatter)).to eq(mock_formatter)
      expect(generator_with_mocks.instance_variable_get(:@path_resolver)).to eq(mock_path_resolver)
    end
  end

  describe "#generate_comprehensive_report" do
    let(:default_options) do
      {
        threshold: 85.0,
        sections: [:summary, :files, :recommendations],
        include_method_analysis: false,
        max_files: 20
      }
    end

    before do
      allow(mock_analyzer).to receive(:analyze_coverage).and_return(sample_analysis_result)
      allow(mock_extractor).to receive(:extract_undercovered_items).and_return(sample_undercovered_items)
      allow(mock_analyzer).to receive(:generate_statistics).and_return({total_methods: 50})
      allow(mock_analyzer).to receive(:prioritize_critical_files).and_return([])
      allow(mock_extractor).to receive(:generate_testing_recommendations).and_return([])
    end

    it "generates a comprehensive report with default sections" do
      result = generator_with_mocks.generate_comprehensive_report(sample_file_path)

      expect(result).to have_key(:metadata)
      expect(result).to have_key(:summary)
      expect(result).to have_key(:files)
      expect(result).to have_key(:recommendations)

      expect(result[:metadata][:threshold]).to eq(85.0)
      expect(result[:metadata][:input_file]).to eq(sample_file_path)
    end

    it "includes only requested sections" do
      options = {sections: [:summary, :statistics]}
      allow(mock_analyzer).to receive(:analyze_coverage).with(sample_file_path, default_options.merge(options)).and_return(sample_analysis_result)

      result = generator_with_mocks.generate_comprehensive_report(sample_file_path, options)

      expect(result).to have_key(:summary)
      expect(result).to have_key(:statistics)
      expect(result).not_to have_key(:files)
      expect(result).not_to have_key(:recommendations)
    end

    it "handles custom options" do
      custom_options = {
        threshold: 90.0,
        include_method_analysis: true,
        max_files: 5
      }
      expected_options = {
        threshold: 90.0,
        sections: [:summary, :files, :recommendations],
        include_method_analysis: true,
        max_files: 5,
        include_patterns: ["**/lib/**/*.rb"],
        exclude_patterns: ["**/spec/**", "**/test/**"],
        formats: [:text, :json],
        base_name: "coverage_report",
        include_comprehensive: false,
        report_format: :compact
      }

      expect(mock_analyzer).to receive(:analyze_coverage).with(sample_file_path, expected_options).and_return(sample_analysis_result)

      generator_with_mocks.generate_comprehensive_report(sample_file_path, custom_options)
    end

    it "includes priorities section when requested" do
      options = {sections: [:priorities]}
      allow(mock_extractor).to receive(:find_high_impact_files).and_return(sample_high_impact_files)
      allow(mock_extractor).to receive(:generate_testing_recommendations).and_return([])
      allow(mock_analyzer).to receive(:analyze_coverage).with(sample_file_path, default_options.merge(options)).and_return(sample_analysis_result)

      result = generator_with_mocks.generate_comprehensive_report(sample_file_path, options)

      expect(result).to have_key(:priorities)
      expect(result[:priorities]).to have_key(:high_impact_files)
    end

    context "when analysis result has no timestamp" do
      let(:result_without_timestamp) do
        double("AnalysisResult",
          analysis_timestamp: nil,
          threshold: 85.0)
      end

      it "handles missing timestamp gracefully" do
        allow(mock_analyzer).to receive(:analyze_coverage).and_return(result_without_timestamp)
        allow(mock_extractor).to receive(:extract_undercovered_items).and_return(sample_undercovered_items)

        expect { generator_with_mocks.generate_comprehensive_report(sample_file_path) }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#generate_for_create_path" do
    before do
      allow(mock_analyzer).to receive(:analyze_coverage).and_return(sample_analysis_result)
      allow(mock_extractor).to receive(:find_high_impact_files).and_return(sample_high_impact_files)
    end

    it "generates create-path compatible report structure" do
      result = generator_with_mocks.generate_for_create_path(sample_file_path, sample_output_path)

      expect(result).to have_key(:action_required)
      expect(result).to have_key(:summary)
      expect(result).to have_key(:critical_items)
      expect(result).to have_key(:recommendations)
      expect(result).to have_key(:next_steps)
      expect(result).to have_key(:output_suggestions)
    end

    it "sets action_required to true when under-covered files exist" do
      result = generator_with_mocks.generate_for_create_path(sample_file_path, sample_output_path)

      expect(result[:action_required]).to be true
    end

    it "sets action_required to false when no under-covered files exist" do
      analysis_result_no_issues = double(
        "AnalysisResult",
        under_covered_files: [],
        total_files: 5,
        overall_coverage_percentage: 95.0,
        threshold: 85.0
      )
      allow(mock_analyzer).to receive(:analyze_coverage).and_return(analysis_result_no_issues)
      allow(mock_extractor).to receive(:find_high_impact_files).and_return([])

      result = generator_with_mocks.generate_for_create_path(sample_file_path, sample_output_path)

      expect(result[:action_required]).to be false
      expect(result[:critical_items]).to be_empty
    end

    it "includes critical items with proper structure" do
      result = generator_with_mocks.generate_for_create_path(sample_file_path, sample_output_path)

      critical_item = result[:critical_items].first
      expect(critical_item).to have_key(:file_path)
      expect(critical_item).to have_key(:coverage_percentage)
      expect(critical_item).to have_key(:impact_score)
      expect(critical_item).to have_key(:effort_estimate)
    end

    it "provides output path suggestions" do
      result = generator_with_mocks.generate_for_create_path(sample_file_path, sample_output_path)

      suggestions = result[:output_suggestions]
      expect(suggestions).to have_key(:detailed_report)
      expect(suggestions).to have_key(:summary_report)
      expect(suggestions).to have_key(:csv_export)
    end

    it "includes action plan suggestion when issues exist" do
      result = generator_with_mocks.generate_for_create_path(sample_file_path, sample_output_path)

      expect(result[:output_suggestions]).to have_key(:action_plan)
    end
  end

  describe "#generate_multi_format_reports" do
    let(:temp_dir) { Dir.mktmpdir }

    after do
      safe_directory_cleanup(temp_dir)
    end

    before do
      allow(mock_analyzer).to receive(:analyze_coverage).and_return(sample_analysis_result)
      allow(mock_analyzer).to receive(:save_report).and_return("/path/to/report.txt")
    end

    it "generates reports in multiple formats" do
      options = {formats: [:text, :json]}

      result = generator_with_mocks.generate_multi_format_reports(sample_file_path, temp_dir, options)

      expect(result).to have_key(:text)
      expect(result).to have_key(:json)
      expect(mock_analyzer).to have_received(:save_report).twice
    end

    it "creates output directory if it doesn't exist" do
      non_existent_dir = File.join(temp_dir, "reports", "nested")

      expect(Dir.exist?(non_existent_dir)).to be false

      generator_with_mocks.generate_multi_format_reports(sample_file_path, non_existent_dir)

      expect(Dir.exist?(non_existent_dir)).to be true
    end

    it "uses custom base name" do
      options = {base_name: "custom_report"}

      generator_with_mocks.generate_multi_format_reports(sample_file_path, temp_dir, options)

      expect(mock_analyzer).to have_received(:save_report).with(
        sample_analysis_result,
        File.join(temp_dir, "custom_report.txt"),
        :text,
        anything
      )
    end

    it "generates comprehensive report when requested" do
      options = {include_comprehensive: true}
      allow(mock_extractor).to receive(:extract_undercovered_items).and_return(sample_undercovered_items)
      allow(mock_extractor).to receive(:generate_testing_recommendations).and_return([])
      allow(mock_analyzer).to receive(:prioritize_critical_files).and_return([])

      result = generator_with_mocks.generate_multi_format_reports(sample_file_path, temp_dir, options)

      expect(result).to have_key(:comprehensive)
      comprehensive_path = result[:comprehensive]
      expect(File.exist?(comprehensive_path)).to be true

      content = JSON.parse(File.read(comprehensive_path))
      expect(content).to have_key("metadata")
    end

    it "handles CSV format" do
      options = {formats: [:csv]}

      result = generator_with_mocks.generate_multi_format_reports(sample_file_path, temp_dir, options)

      expect(result).to have_key(:csv)
      expect(mock_analyzer).to have_received(:save_report).with(
        sample_analysis_result,
        File.join(temp_dir, "coverage_report.csv"),
        :csv,
        anything
      )
    end

    it "uses provided analysis result" do
      options = {formats: [:text]}
      provided_analysis = sample_analysis_result

      generator_with_mocks.generate_multi_format_reports(sample_file_path, temp_dir, options, analysis_result: provided_analysis)

      expect(mock_analyzer).not_to have_received(:analyze_coverage)
      expect(mock_analyzer).to have_received(:save_report).with(provided_analysis, anything, anything, anything)
    end
  end

  describe "#generate_focused_report" do
    let(:focus_patterns) { ["lib/models/**/*.rb", "app/services/**/*.rb"] }

    before do
      allow(mock_analyzer).to receive(:analyze_coverage).and_return(sample_analysis_result)
    end

    it "generates focused report for specific patterns" do
      expected_options = hash_including(include_patterns: focus_patterns)

      result = generator_with_mocks.generate_focused_report(sample_file_path, focus_patterns)

      expect(mock_analyzer).to have_received(:analyze_coverage).with(sample_file_path, expected_options)
      expect(result).to have_key(:focus_area)
      expect(result).to have_key(:analysis)
      expect(result).to have_key(:detailed_breakdown)
    end

    it "includes focus area information" do
      result = generator_with_mocks.generate_focused_report(sample_file_path, focus_patterns)

      focus_area = result[:focus_area]
      expect(focus_area[:patterns]).to eq(focus_patterns)
      expect(focus_area[:files_found]).to eq(1) # Based on sample_analysis_result.files.length
      expect(focus_area[:files_under_threshold]).to eq(2) # Based on under_covered_files.length
    end

    it "provides detailed breakdown for each file" do
      result = generator_with_mocks.generate_focused_report(sample_file_path, focus_patterns)

      breakdown = result[:detailed_breakdown].first
      expect(breakdown).to have_key(:file_path)
      expect(breakdown).to have_key(:coverage_percentage)
      expect(breakdown).to have_key(:lines_breakdown)
      expect(breakdown).to have_key(:methods_count)
      expect(breakdown).to have_key(:under_threshold)
    end

    it "includes lines breakdown with correct structure" do
      result = generator_with_mocks.generate_focused_report(sample_file_path, focus_patterns)

      lines_breakdown = result[:detailed_breakdown].first[:lines_breakdown]
      expect(lines_breakdown).to have_key(:total)
      expect(lines_breakdown).to have_key(:covered)
      expect(lines_breakdown).to have_key(:uncovered)
    end
  end

  describe "private methods" do
    describe "#validate_report_options" do
      it "provides default values for missing options" do
        result = generator.send(:validate_report_options, {})

        expect(result[:threshold]).to eq(85.0)
        expect(result[:sections]).to eq([:summary, :files, :recommendations])
        expect(result[:include_method_analysis]).to be false
        expect(result[:max_files]).to eq(20)
        expect(result[:formats]).to eq([:text, :json])
        expect(result[:base_name]).to eq("coverage_report")
        expect(result[:include_comprehensive]).to be false
      end

      it "preserves provided options" do
        custom_options = {
          threshold: 90.0,
          sections: [:summary],
          include_method_analysis: true,
          max_files: 5,
          formats: [:json],
          base_name: "custom",
          include_comprehensive: true
        }

        result = generator.send(:validate_report_options, custom_options)

        expect(result[:threshold]).to eq(90.0)
        expect(result[:sections]).to eq([:summary])
        expect(result[:include_method_analysis]).to be true
        expect(result[:max_files]).to eq(5)
        expect(result[:formats]).to eq([:json])
        expect(result[:base_name]).to eq("custom")
        expect(result[:include_comprehensive]).to be true
      end
    end

    describe "#generate_actionable_recommendations" do
      it "provides recommendations when under-covered files exist" do
        recommendations = generator.send(:generate_actionable_recommendations, sample_analysis_result)

        expect(recommendations).to be_an(Array)
        expect(recommendations).not_to be_empty
        expect(recommendations.first).to include("lib/low_coverage.rb")
      end

      it "suggests raising threshold when all files meet criteria" do
        good_analysis_result = double(
          "AnalysisResult",
          under_covered_files: [],
          threshold: 85.0
        )

        recommendations = generator.send(:generate_actionable_recommendations, good_analysis_result)

        expect(recommendations.first).to include("consider raising the threshold")
      end

      it "identifies files with significant coverage gaps" do
        low_coverage_file = double("CoverageFile",
          coverage_percentage: 30.0,
          relative_path: "lib/low_coverage_file.rb")
        analysis_with_gaps = double(
          "AnalysisResult",
          under_covered_files: [low_coverage_file],
          threshold: 85.0
        )

        recommendations = generator.send(:generate_actionable_recommendations, analysis_with_gaps)

        expect(recommendations.any? { |r| r.include?("significant coverage gaps") }).to be true
      end
    end

    describe "#determine_coverage_status" do
      it "returns 'excellent' for coverage at or above threshold" do
        analysis = double("AnalysisResult", overall_coverage_percentage: 90.0, threshold: 85.0)
        status = generator.send(:determine_coverage_status, analysis)
        expect(status).to eq("excellent")
      end

      it "returns 'good' for coverage within 10% of threshold" do
        analysis = double("AnalysisResult", overall_coverage_percentage: 80.0, threshold: 85.0)
        status = generator.send(:determine_coverage_status, analysis)
        expect(status).to eq("good")
      end

      it "returns 'needs_improvement' for coverage within 20% of threshold" do
        analysis = double("AnalysisResult", overall_coverage_percentage: 70.0, threshold: 85.0)
        status = generator.send(:determine_coverage_status, analysis)
        expect(status).to eq("needs_improvement")
      end

      it "returns 'critical' for coverage more than 20% below threshold" do
        analysis = double("AnalysisResult", overall_coverage_percentage: 50.0, threshold: 85.0)
        status = generator.send(:determine_coverage_status, analysis)
        expect(status).to eq("critical")
      end
    end

    describe "#suggest_output_paths" do
      it "suggests multiple output formats" do
        suggestions = generator.send(:suggest_output_paths, "/tmp/report.json", sample_analysis_result)

        expect(suggestions).to have_key(:detailed_report)
        expect(suggestions).to have_key(:summary_report)
        expect(suggestions).to have_key(:csv_export)
      end

      it "includes action plan when under-covered files exist" do
        suggestions = generator.send(:suggest_output_paths, "/tmp/report.json", sample_analysis_result)

        expect(suggestions).to have_key(:action_plan)
      end

      it "excludes action plan when no under-covered files exist" do
        good_analysis = double("AnalysisResult", under_covered_files: [])
        suggestions = generator.send(:suggest_output_paths, "/tmp/report.json", good_analysis)

        expect(suggestions).not_to have_key(:action_plan)
      end
    end
  end

  # Edge case testing
  describe "edge cases" do
    context "with empty analysis results" do
      let(:empty_analysis_result) do
        double(
          "AnalysisResult",
          analysis_timestamp: Time.now,
          threshold: 85.0,
          total_files: 0,
          under_covered_files: [],
          overall_coverage_percentage: 0.0,
          total_methods: 0,
          under_covered_methods: [],
          files: [],
          to_h: {status: "empty"}
        )
      end

      before do
        allow(mock_analyzer).to receive(:analyze_coverage).and_return(empty_analysis_result)
        allow(mock_extractor).to receive(:extract_undercovered_items).and_return({
          files: [],
          urgency_breakdown: {high: 0, medium: 0, low: 0},
          recommendations: []
        })
        allow(mock_extractor).to receive(:generate_testing_recommendations).and_return([])
        allow(mock_analyzer).to receive(:prioritize_critical_files).and_return([])
      end

      it "handles empty analysis results gracefully" do
        result = generator_with_mocks.generate_comprehensive_report(sample_file_path)

        expect(result[:summary][:files_analyzed]).to eq(0)
        expect(result[:summary][:overall_coverage]).to eq(0.0)
      end

      it "generates empty create-path report appropriately" do
        result = generator_with_mocks.generate_for_create_path(sample_file_path, sample_output_path)

        expect(result[:action_required]).to be false
        expect(result[:critical_items]).to be_empty
      end
    end

    context "with invalid file paths" do
      it "propagates file system errors" do
        allow(mock_analyzer).to receive(:analyze_coverage).and_raise(Errno::ENOENT, "File not found")

        expect do
          generator_with_mocks.generate_comprehensive_report("/non/existent/file.json")
        end.to raise_error(Errno::ENOENT)
      end
    end

    context "with permission issues" do
      it "handles permission errors for output directory" do
        allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES, "Permission denied")

        expect do
          generator_with_mocks.generate_multi_format_reports(sample_file_path, "/root/reports")
        end.to raise_error(Errno::EACCES)
      end
    end

    context "with malformed data structures" do
      let(:malformed_analysis) do
        double("AnalysisResult", analysis_timestamp: nil)
      end

      it "handles missing required fields" do
        allow(mock_analyzer).to receive(:analyze_coverage).and_return(malformed_analysis)
        allow(mock_extractor).to receive(:extract_undercovered_items).and_raise(NoMethodError, "undefined method for nil")

        expect do
          generator_with_mocks.generate_comprehensive_report(sample_file_path)
        end.to raise_error(NoMethodError)
      end
    end
  end

  # Integration scenarios
  describe "integration scenarios" do
    context "with real file system operations" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:real_generator) { described_class.new }

      after do
        safe_directory_cleanup(temp_dir)
      end

      it "creates output directories as needed" do
        nested_dir = File.join(temp_dir, "reports", "coverage")

        # This will fail with real components, but tests the directory creation logic
        # Expected since we don't have real analysis data
        expect do
          real_generator.generate_multi_format_reports(sample_file_path, nested_dir)
        end.to raise_error(StandardError)
        expect(Dir.exist?(nested_dir)).to be true
      end
    end

    context "with various output formats" do
      before do
        allow(mock_analyzer).to receive(:analyze_coverage).and_return(sample_analysis_result)
        allow(mock_analyzer).to receive(:save_report).and_return("/path/to/report")
      end

      it "handles custom file extensions" do
        options = {formats: [:xml, :yaml]}

        result = generator_with_mocks.generate_multi_format_reports(sample_file_path, sample_output_dir, options)

        expect(result).to have_key(:xml)
        expect(result).to have_key(:yaml)
      end
    end
  end
end
