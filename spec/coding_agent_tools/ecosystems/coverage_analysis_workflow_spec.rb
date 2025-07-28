# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/ecosystems/coverage_analysis_workflow"
require "tempfile"
require "fileutils"
require "json"

RSpec.describe CodingAgentTools::Ecosystems::CoverageAnalysisWorkflow do
  let(:workflow) { described_class.new }
  let(:mock_analyzer) { instance_double(CodingAgentTools::Organisms::CoverageAnalyzer) }
  let(:mock_extractor) { instance_double(CodingAgentTools::Organisms::UndercoveredItemsExtractor) }
  let(:mock_report_generator) { instance_double(CodingAgentTools::Organisms::CoverageReportGenerator) }
  let(:mock_path_resolver) { instance_double(CodingAgentTools::Molecules::PathResolver) }
  let(:mock_threshold_validator) { instance_double(CodingAgentTools::Atoms::ThresholdValidator) }
  
  let(:custom_workflow) do
    described_class.new(
      analyzer: mock_analyzer,
      extractor: mock_extractor,
      report_generator: mock_report_generator,
      path_resolver: mock_path_resolver,
      threshold_validator: mock_threshold_validator
    )
  end

  let(:sample_coverage_data) do
    {
      "RSpec" => {
        "coverage" => {
          "/lib/sample.rb" => {
            "lines" => [1, 1, 0, 1, nil, 1]
          }
        },
        "timestamp" => Time.now.to_i
      }
    }
  end

  let(:temp_input_file) do
    file = Tempfile.new(["coverage", ".json"])
    file.write(JSON.pretty_generate(sample_coverage_data))
    file.close
    file.path
  end

  let(:temp_output_dir) { Dir.mktmpdir("coverage_analysis") }

  let(:mock_analysis_result) do
    instance_double(
      CodingAgentTools::Models::CoverageAnalysisResult,
      total_files: 5,
      under_covered_files: [],
      overall_coverage_percentage: 87.5,
      threshold: 85.0
    )
  end

  let(:mock_undercovered_items) do
    {
      urgency_breakdown: {
        critical: { count: 1 },
        high: { count: 2 }
      },
      recommendations: ["Fix file1.rb", "Improve file2.rb"]
    }
  end

  let(:mock_generated_reports) do
    [
      { format: :text, path: "#{temp_output_dir}/report.txt" },
      { format: :json, path: "#{temp_output_dir}/report.json" }
    ]
  end

  after do
    FileUtils.remove_entry(temp_output_dir) if Dir.exist?(temp_output_dir)
    File.unlink(temp_input_file) if File.exist?(temp_input_file)
  end

  describe "#initialize" do
    it "initializes with default dependencies" do
      expect(workflow).to be_a(described_class)
    end

    it "accepts custom dependencies" do
      expect(custom_workflow).to be_a(described_class)
    end
  end

  describe "#execute_full_analysis" do
    context "with valid input and successful analysis" do
      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
        allow(mock_analyzer).to receive(:analyze_coverage).and_return(mock_analysis_result)
        allow(mock_extractor).to receive(:extract_undercovered_items).and_return(mock_undercovered_items)
        allow(mock_report_generator).to receive(:generate_multi_format_reports).and_return(mock_generated_reports)
      end

      it "executes complete workflow successfully" do
        result = custom_workflow.execute_full_analysis(temp_input_file)

        expect(result[:success]).to be true
        expect(result[:analysis_result]).to eq(mock_analysis_result)
        expect(result[:undercovered_items]).to eq(mock_undercovered_items)
        expect(result[:generated_reports]).to eq(mock_generated_reports)
        expect(result[:execution_summary]).to include(:execution_time, :input_file, :analysis_summary)
      end

      it "includes execution summary with correct structure" do
        result = custom_workflow.execute_full_analysis(temp_input_file)

        summary = result[:execution_summary]
        expect(summary).to include(
          :execution_time,
          :input_file,
          :output_directory,
          :analysis_summary,
          :generated_reports,
          :undercovered_summary
        )

        expect(summary[:analysis_summary]).to include(
          :total_files,
          :under_covered_files,
          :overall_coverage,
          :threshold,
          :coverage_status
        )
      end

      it "creates output directory if it doesn't exist" do
        nonexistent_dir = File.join(temp_output_dir, "new_subdir")
        options = { output_dir: nonexistent_dir }

        custom_workflow.execute_full_analysis(temp_input_file, options)

        expect(Dir.exist?(nonexistent_dir)).to be true
      end

      it "handles adaptive threshold option" do
        options = { adaptive_threshold: true }
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)

        result = custom_workflow.execute_full_analysis(temp_input_file, options)

        expect(result[:success]).to be true
      end

      it "handles create_path_integration option" do
        options = { create_path_integration: true }
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
        allow(mock_report_generator).to receive(:generate_for_create_path).and_return({
          action_required: true,
          critical_items: ["item1"],
          recommendations: ["rec1", "rec2"]
        })

        result = custom_workflow.execute_full_analysis(temp_input_file, options)

        expect(result[:create_path_results]).to include(
          :output_file,
          :action_required,
          :critical_items_count,
          :recommendations_count
        )
      end

      it "handles detailed analysis option" do
        options = { detailed_analysis: true }
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)

        custom_workflow.execute_full_analysis(temp_input_file, options)

        expect(mock_extractor).to have_received(:extract_undercovered_items).with(
          mock_analysis_result,
          hash_including(include_method_details: true)
        )
      end
    end

    context "with invalid input file" do
      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
      end

      it "raises error for non-existent file" do
        result = custom_workflow.execute_full_analysis("/nonexistent/file.json")

        expect(result[:success]).to be false
        expect(result[:error]).to include(:type, :message)
        expect(result[:error][:type]).to eq("ArgumentError")
      end

      it "raises error for non-JSON file" do
        text_file = Tempfile.new(["coverage", ".txt"])
        text_file.close

        result = custom_workflow.execute_full_analysis(text_file.path)

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include("must be a JSON file")
        
        File.unlink(text_file.path)
      end

      it "raises error for unreadable file" do
        File.chmod(0000, temp_input_file)
        
        result = custom_workflow.execute_full_analysis(temp_input_file)

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include("not readable")
        
        File.chmod(0644, temp_input_file) # Restore permissions for cleanup
      end
    end

    context "when analysis raises an error" do
      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
        allow(mock_analyzer).to receive(:analyze_coverage).and_raise(StandardError, "Analysis failed")
      end

      it "handles and reports the error" do
        result = custom_workflow.execute_full_analysis(temp_input_file)

        expect(result[:success]).to be false
        expect(result[:error]).to include(:type, :message)
        expect(result[:error][:message]).to eq("Analysis failed")
        expect(result[:suggestions]).to be_an(Array)
      end
    end

    context "when output directory creation fails" do
      it "handles directory creation errors" do
        invalid_dir = "/invalid/path/that/cannot/be/created"
        options = { output_dir: invalid_dir }
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)

        result = custom_workflow.execute_full_analysis(temp_input_file, options)

        expect(result[:success]).to be false
        expect(result[:error][:message]).to include("Failed to create output directory")
      end
    end
  end

  describe "#execute_quick_analysis" do
    before do
      allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
      allow(mock_analyzer).to receive(:analyze_coverage).and_return(mock_analysis_result)
      allow(mock_analyzer).to receive(:prioritize_critical_files).and_return([])
    end

    it "executes quick analysis with simplified options" do
      result = custom_workflow.execute_quick_analysis(temp_input_file)

      expect(result).to include(
        :overall_coverage,
        :threshold,
        :files_under_threshold,
        :total_files,
        :status,
        :critical_files,
        :recommendations
      )
    end

    it "limits analysis to 10 files max" do
      custom_workflow.execute_quick_analysis(temp_input_file)

      expect(mock_analyzer).to have_received(:analyze_coverage) do |_file, options|
        expect(options[:max_files]).to eq(10)
      end
    end

    it "uses only text format for quick analysis" do
      custom_workflow.execute_quick_analysis(temp_input_file)

      expect(mock_analyzer).to have_received(:analyze_coverage) do |_file, options|
        expect(options[:formats]).to eq([:text])
      end
    end

    it "disables detailed analysis for speed" do
      custom_workflow.execute_quick_analysis(temp_input_file)

      expect(mock_analyzer).to have_received(:analyze_coverage) do |_file, options|
        expect(options[:detailed_analysis]).to be false
      end
    end

    it "prioritizes critical files" do
      custom_workflow.execute_quick_analysis(temp_input_file)

      expect(mock_analyzer).to have_received(:prioritize_critical_files).with(mock_analysis_result, 5)
    end
  end

  describe "#execute_focused_analysis" do
    let(:focus_patterns) { ["**/lib/core/**", "**/lib/utils/**"] }
    let(:mock_focused_report) do
      {
        focus_area: {
          files_found: 10,
          files_under_threshold: 3
        },
        detailed_breakdown: [
          { coverage_percentage: 75.0 },
          { coverage_percentage: 85.0 },
          { coverage_percentage: 90.0 }
        ]
      }
    end

    before do
      allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
      allow(mock_report_generator).to receive(:generate_focused_report).and_return(mock_focused_report)
    end

    it "executes focused analysis on specified patterns" do
      result = custom_workflow.execute_focused_analysis(temp_input_file, focus_patterns)

      expect(result).to include(
        :focus_patterns,
        :analysis_result,
        :summary
      )
      expect(result[:focus_patterns]).to eq(focus_patterns)
    end

    it "includes focus patterns in analysis options" do
      custom_workflow.execute_focused_analysis(temp_input_file, focus_patterns)

      expect(mock_report_generator).to have_received(:generate_focused_report) do |_file, patterns, options|
        expect(patterns).to eq(focus_patterns)
        expect(options[:include_patterns]).to eq(focus_patterns)
      end
    end

    it "calculates coverage distribution for focused area" do
      result = custom_workflow.execute_focused_analysis(temp_input_file, focus_patterns)

      distribution = result[:summary][:coverage_distribution]
      expect(distribution).to include(:min_coverage, :max_coverage, :average_coverage)
      expect(distribution[:min_coverage]).to eq(75.0)
      expect(distribution[:max_coverage]).to eq(90.0)
      expect(distribution[:average_coverage]).to eq(83.33)
    end
  end

  describe "#analyze_and_recommend" do
    let(:mock_file_reader) { instance_double(CodingAgentTools::Atoms::CoverageFileReader) }
    let(:mock_frameworks) { ["RSpec"] }
    let(:mock_file_paths) do
      [
        "/project/lib/core.rb",
        "/project/lib/utils.rb",
        "/project/spec/core_spec.rb",
        "/project/test/utils_test.rb"
      ]
    end

    before do
      allow(CodingAgentTools::Atoms::CoverageFileReader).to receive(:new).and_return(mock_file_reader)
      allow(mock_file_reader).to receive(:read).and_return(sample_coverage_data)
      allow(mock_file_reader).to receive(:validate_structure)
      allow(mock_file_reader).to receive(:extract_frameworks).and_return(mock_frameworks)
      allow(mock_file_reader).to receive(:extract_file_paths).and_return(mock_file_paths)
    end

    it "validates SimpleCov file and provides recommendations" do
      result = workflow.analyze_and_recommend(temp_input_file)

      expect(result).to include(
        :file_validation,
        :analysis_recommendations,
        :workflow_suggestions
      )
    end

    it "categorizes files correctly" do
      result = workflow.analyze_and_recommend(temp_input_file)

      validation = result[:file_validation]
      expect(validation[:lib_files]).to eq(2)
      expect(validation[:test_files]).to eq(2)
      expect(validation[:total_files]).to eq(4)
    end

    it "suggests appropriate threshold based on project size" do
      result = workflow.analyze_and_recommend(temp_input_file)

      recommendations = result[:analysis_recommendations]
      expect(recommendations[:suggested_threshold]).to eq(90.0) # Small project (2 lib files)
    end

    it "recommends focused analysis for large projects" do
      large_lib_files = (1..60).map { |i| "/project/lib/file#{i}.rb" }
      all_files = large_lib_files + mock_file_paths.select { |p| !p.include?('/lib/') }
      
      allow(mock_file_reader).to receive(:extract_file_paths).and_return(all_files)

      result = workflow.analyze_and_recommend(temp_input_file)

      recommendations = result[:analysis_recommendations]
      expect(recommendations[:recommended_focus]).to eq("focused_analysis")
      
      suggestions = result[:workflow_suggestions]
      expect(suggestions[:focus_patterns]).not_to be_nil
    end

    it "enables method analysis for small projects" do
      result = workflow.analyze_and_recommend(temp_input_file)

      suggestions = result[:workflow_suggestions]
      expect(suggestions[:include_method_analysis]).to be true
    end

    it "estimates analysis time based on project size" do
      result = workflow.analyze_and_recommend(temp_input_file)

      recommendations = result[:analysis_recommendations]
      expect(recommendations[:estimated_analysis_time]).to eq("< 5 seconds")
    end
  end

  describe "private methods" do
    describe "#validate_and_prepare_options" do
      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
      end

      it "sets default values for all options" do
        result = custom_workflow.send(:validate_and_prepare_options, {})

        expect(result).to include(
          threshold: 85.0,
          adaptive_threshold: false,
          output_dir: "./coverage_analysis",
          formats: [:text, :json],
          create_path_integration: false,
          detailed_analysis: false,
          include_patterns: ["**/lib/**/*.rb"],
          exclude_patterns: ["**/spec/**", "**/test/**"],
          max_files: 20,
          base_name: "coverage_analysis",
          include_comprehensive: false
        )
      end

      it "overrides defaults with provided options" do
        options = {
          threshold: 90.0,
          output_dir: "/custom/output",
          formats: [:json],
          detailed_analysis: true
        }
        
        allow(mock_threshold_validator).to receive(:validate_threshold).with(90.0).and_return(90.0)

        result = custom_workflow.send(:validate_and_prepare_options, options)

        expect(result[:threshold]).to eq(90.0)
        expect(result[:output_dir]).to eq("/custom/output")
        expect(result[:formats]).to eq([:json])
        expect(result[:detailed_analysis]).to be true
      end
    end

    describe "#determine_overall_status" do
      it "returns 'excellent' for perfect coverage" do
        allow(mock_analysis_result).to receive(:overall_coverage_percentage).and_return(90.0)
        allow(mock_analysis_result).to receive(:threshold).and_return(85.0)
        allow(mock_analysis_result).to receive(:under_covered_files).and_return([])

        status = workflow.send(:determine_overall_status, mock_analysis_result)
        expect(status).to eq("excellent")
      end

      it "returns 'good' for coverage slightly below threshold" do
        allow(mock_analysis_result).to receive(:overall_coverage_percentage).and_return(82.0)
        allow(mock_analysis_result).to receive(:threshold).and_return(85.0)
        allow(mock_analysis_result).to receive(:under_covered_files).and_return([])

        status = workflow.send(:determine_overall_status, mock_analysis_result)
        expect(status).to eq("good")
      end

      it "returns 'needs_improvement' for moderate coverage gaps" do
        allow(mock_analysis_result).to receive(:overall_coverage_percentage).and_return(75.0)
        allow(mock_analysis_result).to receive(:threshold).and_return(85.0)

        status = workflow.send(:determine_overall_status, mock_analysis_result)
        expect(status).to eq("needs_improvement")
      end

      it "returns 'critical' for very low coverage" do
        allow(mock_analysis_result).to receive(:overall_coverage_percentage).and_return(50.0)
        allow(mock_analysis_result).to receive(:threshold).and_return(85.0)

        status = workflow.send(:determine_overall_status, mock_analysis_result)
        expect(status).to eq("critical")
      end
    end

    describe "#generate_quick_recommendations" do
      let(:mock_under_covered_files) { [] }

      before do
        allow(mock_analysis_result).to receive(:under_covered_files).and_return(mock_under_covered_files)
      end

      context "with no under-covered files" do
        it "suggests raising the threshold" do
          recommendations = workflow.send(:generate_quick_recommendations, mock_analysis_result)
          
          expect(recommendations.first).to include("All files meet the coverage threshold!")
        end
      end

      context "with under-covered files" do
        let(:worst_file) do
          double("CoverageFile",
            relative_path: "lib/worst.rb",
            coverage_percentage: 45.0
          )
        end
        let(:mock_under_covered_files) { [worst_file] }

        it "recommends starting with the worst file" do
          recommendations = workflow.send(:generate_quick_recommendations, mock_analysis_result)
          
          expect(recommendations).to include("Start with lib/worst.rb (45.0% coverage)")
        end

        context "with many under-covered files" do
          let(:file1) { double("CoverageFile", relative_path: "lib/file1.rb", coverage_percentage: 45.0) }
          let(:file2) { double("CoverageFile", relative_path: "lib/file2.rb", coverage_percentage: 50.0) }
          let(:file3) { double("CoverageFile", relative_path: "lib/file3.rb", coverage_percentage: 55.0) }
          let(:file4) { double("CoverageFile", relative_path: "lib/file4.rb", coverage_percentage: 60.0) }
          let(:file5) { double("CoverageFile", relative_path: "lib/file5.rb", coverage_percentage: 65.0) }
          let(:mock_under_covered_files) { [file1, file2, file3, file4, file5] }

          it "suggests focusing on worst cases first" do
            recommendations = workflow.send(:generate_quick_recommendations, mock_analysis_result)
            
            expect(recommendations).to include("5 files need attention - consider focusing on the worst cases first")
          end
        end

        context "with critical coverage gaps" do
          let(:critical_file) do
            double("CoverageFile",
              relative_path: "lib/critical.rb",
              coverage_percentage: 15.0
            )
          end
          let(:mock_under_covered_files) { [critical_file] }

          it "warns about critical coverage gaps" do
            recommendations = workflow.send(:generate_quick_recommendations, mock_analysis_result)
            
            expect(recommendations).to include("1 file(s) have critical coverage gaps (<25%)")
          end
        end
      end
    end

    describe "#suggest_threshold_based_on_size" do
      it "suggests 90% for very small projects" do
        threshold = workflow.send(:suggest_threshold_based_on_size, 5)
        expect(threshold).to eq(90.0)
      end

      it "suggests 85% for medium projects" do
        threshold = workflow.send(:suggest_threshold_based_on_size, 20)
        expect(threshold).to eq(85.0)
      end

      it "suggests 80% for large projects" do
        threshold = workflow.send(:suggest_threshold_based_on_size, 50)
        expect(threshold).to eq(80.0)
      end

      it "suggests 75% for very large projects" do
        threshold = workflow.send(:suggest_threshold_based_on_size, 150)
        expect(threshold).to eq(75.0)
      end
    end

    describe "#handle_workflow_error" do
      let(:test_error) { StandardError.new("Test error") }
      let(:test_options) { { threshold: 85.0, sensitive_data: "secret" } }

      it "creates error response with sanitized options" do
        result = workflow.send(:handle_workflow_error, test_error, temp_input_file, test_options)

        expect(result[:success]).to be false
        expect(result[:error]).to include(
          type: "StandardError",
          message: "Test error",
          input_file: temp_input_file
        )
        expect(result[:error][:options]).not_to have_key(:sensitive_data)
        expect(result[:suggestions]).to be_an(Array)
      end
    end

    describe "#generate_error_suggestions" do
      it "provides specific suggestions for CoverageFileReader errors" do
        error = CodingAgentTools::Atoms::CoverageFileReader::InvalidFileError.new("Invalid file")
        suggestions = workflow.send(:generate_error_suggestions, error)

        expect(suggestions).to include("Ensure the input file is a valid SimpleCov .resultset.json file")
        expect(suggestions).to include("Check that SimpleCov generated the file correctly")
      end

      it "provides specific suggestions for ArgumentError" do
        error = ArgumentError.new("Bad argument")
        suggestions = workflow.send(:generate_error_suggestions, error)

        expect(suggestions).to include("Check command-line arguments and file paths")
        expect(suggestions).to include("Ensure threshold values are between 0 and 100")
      end

      it "provides generic suggestions for other errors" do
        error = StandardError.new("Generic error")
        suggestions = workflow.send(:generate_error_suggestions, error)

        expect(suggestions).to include("Check file permissions and paths")
        expect(suggestions).to include("Ensure sufficient disk space for output files")
      end
    end
  end

  describe "edge cases and error handling" do
    context "with empty coverage data" do
      let(:empty_coverage_data) do
        {
          "RSpec" => {
            "coverage" => {},
            "timestamp" => Time.now.to_i
          }
        }
      end

      let(:empty_temp_file) do
        file = Tempfile.new(["empty_coverage", ".json"])
        file.write(JSON.pretty_generate(empty_coverage_data))
        file.close
        file.path
      end

      after do
        File.unlink(empty_temp_file) if File.exist?(empty_temp_file)
      end

      it "handles empty coverage data gracefully" do
        result = workflow.analyze_and_recommend(empty_temp_file)

        expect(result[:file_validation][:valid]).to be true
        expect(result[:file_validation][:total_files]).to eq(0)
      end
    end

    context "with malformed JSON" do
      let(:malformed_temp_file) do
        file = Tempfile.new(["malformed", ".json"])
        file.write("{ invalid json")
        file.close
        file.path
      end

      after do
        File.unlink(malformed_temp_file) if File.exist?(malformed_temp_file)
      end

      it "handles malformed JSON gracefully" do
        mock_file_reader = instance_double(CodingAgentTools::Atoms::CoverageFileReader)
        allow(CodingAgentTools::Atoms::CoverageFileReader).to receive(:new).and_return(mock_file_reader)
        allow(mock_file_reader).to receive(:read).and_raise(JSON::ParserError)

        expect {
          workflow.analyze_and_recommend(malformed_temp_file)
        }.to raise_error(JSON::ParserError)
      end
    end

    context "with permission denied scenarios" do
      it "handles unreadable output directory" do
        protected_dir = File.join(temp_output_dir, "protected")
        Dir.mkdir(protected_dir)
        File.chmod(0000, protected_dir)

        options = { output_dir: File.join(protected_dir, "subdir") }
        result = workflow.execute_full_analysis(temp_input_file, options)

        expect(result[:success]).to be false
        
        File.chmod(0755, protected_dir) # Restore for cleanup
      end
    end

    context "with very large file counts" do
      it "handles max_files limit correctly" do
        large_options = { max_files: 5 }
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
        allow(mock_analyzer).to receive(:analyze_coverage).and_return(mock_analysis_result)
        allow(mock_extractor).to receive(:extract_undercovered_items).and_return(mock_undercovered_items)
        allow(mock_report_generator).to receive(:generate_multi_format_reports).and_return(mock_generated_reports)

        custom_workflow.execute_full_analysis(temp_input_file, large_options)

        expect(mock_extractor).to have_received(:extract_undercovered_items) do |_result, options|
          expect(options[:max_files]).to eq(5)
        end
      end
    end
  end

  describe "integration scenarios" do
    context "when all dependencies succeed" do
      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).and_return(85.0)
        allow(mock_analyzer).to receive(:analyze_coverage).and_return(mock_analysis_result)
        allow(mock_extractor).to receive(:extract_undercovered_items).and_return(mock_undercovered_items)
        allow(mock_report_generator).to receive(:generate_multi_format_reports).and_return(mock_generated_reports)
      end

      it "coordinates all components successfully" do
        result = custom_workflow.execute_full_analysis(temp_input_file)

        expect(mock_analyzer).to have_received(:analyze_coverage)
        expect(mock_extractor).to have_received(:extract_undercovered_items)
        expect(mock_report_generator).to have_received(:generate_multi_format_reports)
        expect(result[:success]).to be true
      end
    end

    context "when dependencies propagate errors" do
      before do
        allow(mock_threshold_validator).to receive(:validate_threshold).with(85.0).and_return(85.0)
        allow(mock_analyzer).to receive(:analyze_coverage).and_raise(StandardError, "Analyzer failed")
        allow(mock_extractor).to receive(:extract_undercovered_items)
        allow(mock_report_generator).to receive(:generate_multi_format_reports)
      end

      it "handles cascading failures appropriately" do
        result = custom_workflow.execute_full_analysis(temp_input_file)

        expect(result[:success]).to be false
        expect(result[:error][:message]).to eq("Analyzer failed")
        expect(mock_extractor).not_to have_received(:extract_undercovered_items)
        expect(mock_report_generator).not_to have_received(:generate_multi_format_reports)
      end
    end
  end
end