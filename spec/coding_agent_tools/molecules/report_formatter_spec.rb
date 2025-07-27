# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CodingAgentTools::Molecules::ReportFormatter do
  subject { described_class.new }

  let(:sample_coverage_results) do
    low_coverage_file = instance_double(CodingAgentTools::Models::CoverageResult,
      file_path: "/test/lib/low_coverage.rb",
      relative_path: "lib/low_coverage.rb",
      total_lines: 20,
      covered_lines: 10,
      coverage_percentage: 50.0,
      uncovered_lines_count: 10,
      methods: [],
      to_h: {
        file_path: "/test/lib/low_coverage.rb",
        relative_path: "lib/low_coverage.rb",
        coverage_percentage: 50.0,
        total_lines: 20,
        covered_lines: 10
      }
    )
    allow(low_coverage_file).to receive(:under_threshold?).with(80.0).and_return(true)
    
    high_coverage_file = instance_double(CodingAgentTools::Models::CoverageResult,
      file_path: "/test/lib/high_coverage.rb", 
      relative_path: "lib/high_coverage.rb",
      total_lines: 15,
      covered_lines: 14,
      coverage_percentage: 93.3,
      uncovered_lines_count: 1,
      methods: [],
      to_h: {
        file_path: "/test/lib/high_coverage.rb",
        relative_path: "lib/high_coverage.rb",
        coverage_percentage: 93.3,
        total_lines: 15,
        covered_lines: 14
      }
    )
    allow(high_coverage_file).to receive(:under_threshold?).with(80.0).and_return(false)
    
    [low_coverage_file, high_coverage_file]
  end

  let(:sample_analysis_result) do
    analysis_result = instance_double(CodingAgentTools::Models::CoverageAnalysisResult,
      files: sample_coverage_results,
      under_covered_files: [sample_coverage_results.first],
      total_files: 2,
      threshold: 80.0,
      overall_coverage_percentage: 68.6,
      analysis_timestamp: Time.new(2025, 1, 15, 10, 30, 0),
      to_h: {
        summary: {
          total_files: 2,
          total_methods: 0,
          under_covered_files_count: 1,
          under_covered_methods_count: 0,
          overall_coverage_percentage: 68.6,
          threshold: 80.0,
          analysis_timestamp: "2025-01-15T10:30:00Z"
        },
        under_covered_files: [sample_coverage_results.first.to_h],
        under_covered_methods: []
      }
    )
    
    # Mock private methods
    allow(analysis_result).to receive(:total_executable_lines).and_return(35)
    allow(analysis_result).to receive(:total_covered_lines).and_return(24)
    
    analysis_result
  end

  describe "#format_text_report" do
    it "generates a comprehensive text report" do
      report = subject.format_text_report(sample_analysis_result)

      expect(report).to include("Coverage Analysis Report")
      expect(report).to include("Overall Coverage: 68.6%")
      expect(report).to include("Threshold: 80.0%")
      expect(report).to include("Files Under Threshold: 1 of 2")
      expect(report).to include("lib/low_coverage.rb")
      expect(report).to include("50.0%")
    end

    it "includes summary statistics" do
      report = subject.format_text_report(sample_analysis_result)

      expect(report).to include("Total Lines: 35")
      expect(report).to include("Covered Lines: 24")
      expect(report).to include("Overall Coverage: 68.6%")
    end

    it "lists under-covered files with details" do
      report = subject.format_text_report(sample_analysis_result)

      expect(report).to include("Under-Covered Files:")
      expect(report).to include("lib/low_coverage.rb")
      expect(report).to include("20 lines")
      expect(report).to include("10 uncovered")
    end

    context "with detailed analysis" do
      let(:detailed_analysis) do
        {
          file_info: {
            under_threshold: true,
            relative_path: "lib/example.rb"
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
          frameworks: ["RSpec"],
          priority_score: 85.5
        }
      end

      it "includes method-level analysis when available" do
        report = subject.format_detailed_file_report(detailed_analysis)

        expect(report).to include("Method Analysis:")
        expect(report).to include("Total Methods: 3")
        expect(report).to include("Under-Covered Methods: 2")
        expect(report).to include("Completely Uncovered: 1")
      end

      it "shows uncovered line ranges" do
        report = subject.format_detailed_file_report(detailed_analysis)

        expect(report).to include("Uncovered Areas:")
        expect(report).to include("Lines 5-8")
        expect(report).to include("Lines 12-15")
      end

      it "includes priority score" do
        report = subject.format_detailed_file_report(detailed_analysis)

        expect(report).to include("Priority Score: 85.5")
      end
    end

    context "when no under-covered files found" do
      let(:good_analysis_result) do
        result = instance_double(CodingAgentTools::Models::CoverageAnalysisResult,
          under_covered_files: [],
          total_files: 1,
          threshold: 80.0,
          overall_coverage_percentage: 95.0
        )
        
        # Mock private methods
        allow(result).to receive(:total_executable_lines).and_return(100)
        allow(result).to receive(:total_covered_lines).and_return(95)
        
        result
      end

      it "shows positive message" do
        report = subject.format_text_report(good_analysis_result)

        expect(report).to include("All files meet the coverage threshold!")
        expect(report).to include("Overall Coverage: 95.0%")
      end
    end
  end

  describe "#format_json_report" do
    it "generates valid JSON with complete data" do
      json_report = subject.format_json_report(sample_analysis_result)
      parsed = JSON.parse(json_report)

      expect(parsed).to have_key("summary")
      expect(parsed).to have_key("under_covered_files")
      expect(parsed["summary"]["total_files"]).to eq(2)
      expect(parsed["summary"]["under_covered_files_count"]).to eq(1)
      expect(parsed["summary"]["threshold"]).to eq(80.0)
    end

    it "includes metadata and timestamps" do
      json_report = subject.format_json_report(sample_analysis_result)
      parsed = JSON.parse(json_report)

      expect(parsed).to have_key("metadata")
      expect(parsed["metadata"]).to have_key("generated_at")
      expect(parsed["metadata"]).to have_key("analysis_timestamp")
      expect(parsed["metadata"]["analysis_timestamp"]).to match(/2025-01-15T10:30:00/)
    end

    it "preserves numeric precision" do
      json_report = subject.format_json_report(sample_analysis_result)
      parsed = JSON.parse(json_report)

      expect(parsed["summary"]["overall_coverage_percentage"]).to eq(68.6)
      expect(parsed["under_covered_files"].first["coverage_percentage"]).to eq(50.0)
    end
  end

  describe "#format_csv_report" do
    it "generates CSV with proper headers" do
      csv_report = subject.format_csv_report(sample_analysis_result)
      lines = csv_report.split("\n")

      expect(lines.first).to eq("file_path,coverage_percentage,total_lines,covered_lines,uncovered_lines,under_threshold")
      expect(lines.length).to eq(3)  # Header + 2 data rows
    end

    it "includes file data in correct format" do
      csv_report = subject.format_csv_report(sample_analysis_result)
      lines = csv_report.split("\n")

      expect(lines[1]).to include("lib/low_coverage.rb,50.0,20,10,10,true")
      expect(lines[2]).to include("lib/high_coverage.rb,93.3,15,14,1,false")
    end

    it "handles special characters in file paths" do
      special_result = instance_double(CodingAgentTools::Models::CoverageResult,
        relative_path: "lib/file with spaces & symbols.rb",
        coverage_percentage: 75.0,
        total_lines: 10,
        covered_lines: 7,
        uncovered_lines_count: 3
      )
      allow(special_result).to receive(:under_threshold?).with(80.0).and_return(true)

      allow(sample_analysis_result).to receive(:files).and_return([special_result])

      csv_report = subject.format_csv_report(sample_analysis_result)
      
      expect(csv_report).to include("lib/file with spaces & symbols.rb")
    end

    context "with empty results" do
      let(:empty_analysis_result) do
        instance_double(CodingAgentTools::Models::CoverageAnalysisResult,
          files: []
        )
      end

      it "generates header-only CSV" do
        csv_report = subject.format_csv_report(empty_analysis_result)
        lines = csv_report.split("\n")

        expect(lines.length).to eq(1)
        expect(lines.first).to include("file_path,coverage_percentage")
      end
    end
  end

  describe "#save_report" do
    let(:temp_file) { Tempfile.new(["coverage_report", ".txt"]) }

    after { temp_file.unlink }

    it "saves text report to file" do
      report_content = subject.format_text_report(sample_analysis_result)
      
      subject.save_report(report_content, temp_file.path)
      
      saved_content = File.read(temp_file.path)
      expect(saved_content).to eq(report_content)
    end

    it "creates directories if they don't exist" do
      nested_path = File.join(Dir.tmpdir, "coverage", "reports", "test_report.txt")
      
      begin
        subject.save_report("test content", nested_path)
        
        expect(File.exist?(nested_path)).to be true
        expect(File.read(nested_path)).to eq("test content")
      ensure
        FileUtils.rm_rf(File.dirname(nested_path)) if File.exist?(nested_path)
      end
    end

    it "handles file write errors gracefully" do
      invalid_path = "/root/readonly/report.txt"
      
      expect {
        subject.save_report("content", invalid_path)
      }.to raise_error(CodingAgentTools::Molecules::ReportFormatter::SaveError)
    end
  end

  describe "#generate_summary_stats" do
    it "calculates comprehensive statistics" do
      stats = subject.generate_summary_stats(sample_analysis_result)

      expect(stats).to have_key(:files_summary)
      expect(stats).to have_key(:coverage_distribution)
      expect(stats).to have_key(:line_coverage_stats)
      
      expect(stats[:files_summary][:total_files]).to eq(2)
      expect(stats[:files_summary][:under_threshold_count]).to eq(1)
      expect(stats[:files_summary][:percentage_under_threshold]).to eq(50.0)
    end

    it "groups files by coverage ranges" do
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

  describe "format detection and validation" do
    describe "#detect_output_format" do
      it "detects format from file extension" do
        expect(subject.detect_output_format("report.json")).to eq(:json)
        expect(subject.detect_output_format("report.csv")).to eq(:csv)
        expect(subject.detect_output_format("report.txt")).to eq(:text)
      end

      it "defaults to text format for unknown extensions" do
        expect(subject.detect_output_format("report.unknown")).to eq(:text)
        expect(subject.detect_output_format("report")).to eq(:text)
      end
    end

    describe "#validate_format" do
      it "accepts valid formats" do
        expect { subject.validate_format(:text) }.not_to raise_error
        expect { subject.validate_format(:json) }.not_to raise_error
        expect { subject.validate_format(:csv) }.not_to raise_error
      end

      it "rejects invalid formats" do
        expect {
          subject.validate_format(:xml)
        }.to raise_error(CodingAgentTools::Molecules::ReportFormatter::InvalidFormatError)
      end
    end
  end

  describe "private helper methods" do
    describe "#format_coverage_percentage" do
      it "formats percentages with one decimal place" do
        expect(subject.send(:format_coverage_percentage, 85.666)).to eq("85.7%")
        expect(subject.send(:format_coverage_percentage, 100.0)).to eq("100.0%")
        expect(subject.send(:format_coverage_percentage, 0.0)).to eq("0.0%")
      end
    end

    describe "#format_file_size" do
      it "formats line counts appropriately" do
        expect(subject.send(:format_file_size, 1)).to eq("1 line")
        expect(subject.send(:format_file_size, 50)).to eq("50 lines")
        expect(subject.send(:format_file_size, 1000)).to eq("1,000 lines")
      end
    end

    describe "#prioritize_results_by_severity" do
      it "sorts files by coverage severity" do
        sorted = subject.send(:prioritize_results_by_severity, sample_coverage_results)
        
        expect(sorted.first.coverage_percentage).to eq(50.0)  # Worst first
        expect(sorted.last.coverage_percentage).to eq(93.3)   # Best last
      end
    end
  end

  describe "integration with create-path workflow" do
    context "when generating reports for create-path integration" do
      it "formats reports in create-path compatible structure" do
        report_data = subject.format_for_create_path(sample_analysis_result)

        expect(report_data).to have_key(:summary)
        expect(report_data).to have_key(:details)
        expect(report_data).to have_key(:recommendations)
        
        expect(report_data[:summary][:action_required]).to be true
        expect(report_data[:details][:under_covered_files]).to be_an(Array)
      end

      it "includes actionable recommendations" do
        report_data = subject.format_for_create_path(sample_analysis_result)
        recommendations = report_data[:recommendations]

        expect(recommendations).to include("Focus testing efforts on lib/low_coverage.rb (50.0% coverage)")
        expect(recommendations).to include("1 file below 80.0% threshold requires attention")
      end
    end
  end
end