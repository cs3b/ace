# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Code::ReviewSynthesize do
  let(:command) { described_class.new }
  let(:mock_report_collector) { instance_double("CodingAgentTools::Molecules::Code::ReportCollector") }
  let(:mock_session_path_inferrer) { instance_double("CodingAgentTools::Molecules::Code::SessionPathInferrer") }
  let(:mock_synthesis_orchestrator) { instance_double("CodingAgentTools::Molecules::Code::SynthesisOrchestrator") }
  let(:temp_dir) { Dir.mktmpdir }
  let(:report1) { File.join(temp_dir, "report1.md") }
  let(:report2) { File.join(temp_dir, "report2.md") }

  before do
    FileUtils.mkdir_p(temp_dir)
    File.write(report1, "# Report 1\nContent 1")
    File.write(report2, "# Report 2\nContent 2")

    allow(CodingAgentTools::Molecules::Code::ReportCollector).to receive(:new).and_return(mock_report_collector)
    allow(CodingAgentTools::Molecules::Code::SessionPathInferrer).to receive(:new).and_return(mock_session_path_inferrer)
    allow(CodingAgentTools::Molecules::Code::SynthesisOrchestrator).to receive(:new).and_return(mock_synthesis_orchestrator)

    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#call" do
    context "with minimum valid reports" do
      let(:synthesis_result) do
        {
          success: true,
          output_file: "/path/to/synthesis.md",
          synthesis_content: "Synthesized content"
        }
      end

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: [
            {path: report1, content: "Content 1"},
            {path: report2, content: "Content 2"}
          ]
        })
        allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
        allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return(synthesis_result)
      end

      it "synthesizes reports successfully" do
        result = command.call(reports: [report1, report2])

        expect(result).to eq(0)
        expect(mock_report_collector).to have_received(:collect_reports).with([report1, report2])
        expect(mock_synthesis_orchestrator).to have_received(:synthesize)
      end

      it "uses default model when not specified" do
        command.call(reports: [report1, report2])

        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(model: "google:gemini-2.5-pro")
        )
      end

      it "uses custom model when specified" do
        command.call(reports: [report1, report2], model: "anthropic:claude-4-0-sonnet-latest")

        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(model: "anthropic:claude-4-0-sonnet-latest")
        )
      end

      it "uses inferred output path when not specified" do
        command.call(reports: [report1, report2])

        expect(mock_session_path_inferrer).to have_received(:infer_output_path).with([report1, report2])
      end

      it "uses custom output path when specified" do
        custom_output = "/custom/output.md"
        command.call(reports: [report1, report2], output: custom_output)

        expect(mock_session_path_inferrer).not_to have_received(:infer_output_path)
        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(output_file: custom_output)
        )
      end

      it "uses default format when not specified" do
        command.call(reports: [report1, report2])

        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(format: "markdown")
        )
      end

      it "uses custom format when specified" do
        command.call(reports: [report1, report2], format: "json")

        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(format: "json")
        )
      end

      it "handles custom system prompt" do
        system_prompt_file = File.join(temp_dir, "system.md")
        File.write(system_prompt_file, "Custom system prompt")

        command.call(reports: [report1, report2], system_prompt: system_prompt_file)

        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(system_prompt: system_prompt_file)
        )
      end

      it "handles force option" do
        command.call(reports: [report1, report2], force: true)

        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(force: true)
        )
      end

      it "displays success information" do
        command.call(reports: [report1, report2])

        expect($stdout).to have_received(:puts).with(match(/✅.*synthesis/i))
      end
    end

    context "with insufficient reports" do
      it "rejects single report" do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: [{path: report1, content: "Content 1"}]
        })
        result = command.call(reports: [report1])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: At least 2 report files are required for synthesis\n")
      end

      it "rejects empty report list" do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: []
        })
        result = command.call(reports: [])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: At least 2 report files are required for synthesis\n")
      end
    end

    context "with report collection failures" do
      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: false,
          error: "Report file not found"
        })
      end

      it "handles report collection errors" do
        result = command.call(reports: [report1, report2])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Report file not found\n")
      end
    end

    context "with synthesis failures" do
      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
        })
        allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
        allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return({
          success: false,
          error: "Synthesis failed"
        })
      end

      it "handles synthesis errors" do
        result = command.call(reports: [report1, report2])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Synthesis failed\n")
      end
    end

    context "with dry run option" do
      let(:dry_run_result) do
        {
          success: true,
          dry_run: true,
          reports_found: 2,
          output_file: "/path/to/output.md",
          model: "google:gemini-2.5-pro"
        }
      end

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
        })
        allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
        allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return(dry_run_result)
      end

      it "performs dry run without actual synthesis" do
        result = command.call(reports: [report1, report2], dry_run: true)

        expect(result).to eq(0)
        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(dry_run: true)
        )
      end

      it "displays dry run information" do
        command.call(reports: [report1, report2], dry_run: true)

        expect($stdout).to have_received(:puts).with(match(/dry run/i))
      end
    end

    context "with debug option" do
      let(:synthesis_result) do
        {
          success: true,
          output_file: "/path/to/synthesis.md",
          synthesis_content: "Synthesized content",
          debug_info: "Debug information"
        }
      end

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
        })
        allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
        allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return(synthesis_result)
      end

      it "enables debug output" do
        result = command.call(reports: [report1, report2], debug: true)

        expect(result).to eq(0)
        expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
          hash_including(debug: true)
        )
      end
    end

    context "with file validation" do
      it "validates system prompt file exists" do
        nonexistent_prompt = "/nonexistent/prompt.md"

        result = command.call(reports: [report1, report2], system_prompt: nonexistent_prompt)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(match(/system prompt.*not found/i))
      end

      it "validates report files exist" do
        nonexistent_report = "/nonexistent/report.md"

        # This depends on how report_collector handles missing files
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: false,
          error: "Report file not found: #{nonexistent_report}"
        })

        result = command.call(reports: [report1, nonexistent_report])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Report file not found: #{nonexistent_report}\n")
      end
    end

    context "with multiple report files" do
      let(:report3) { File.join(temp_dir, "report3.md") }
      let(:report4) { File.join(temp_dir, "report4.md") }

      before do
        File.write(report3, "# Report 3\nContent 3")
        File.write(report4, "# Report 4\nContent 4")

        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: [
            {path: report1, content: "Content 1"},
            {path: report2, content: "Content 2"},
            {path: report3, content: "Content 3"},
            {path: report4, content: "Content 4"}
          ]
        })
        allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
        allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return({
          success: true,
          output_file: "/path/to/synthesis.md"
        })
      end

      it "handles multiple report files" do
        result = command.call(reports: [report1, report2, report3, report4])

        expect(result).to eq(0)
        expect(mock_report_collector).to have_received(:collect_reports).with([report1, report2, report3, report4])
      end
    end

    context "with different output formats" do
      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
        })
        allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
        allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return({
          success: true,
          output_file: "/path/to/synthesis"
        })
      end

      %w[text json markdown].each do |format|
        it "handles #{format} format" do
          result = command.call(reports: [report1, report2], format: format)

          expect(result).to eq(0)
          expect(mock_synthesis_orchestrator).to have_received(:synthesize).with(
            hash_including(format: format)
          )
        end
      end
    end

    context "with exception handling" do
      before do
        allow(mock_report_collector).to receive(:collect_reports).and_raise(StandardError, "Unexpected error")
      end

      it "handles unexpected exceptions gracefully" do
        result = command.call(reports: [report1, report2])

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Unexpected error\n")
      end

      it "shows debug information with debug flag" do
        result = command.call(reports: [report1, report2], debug: true)

        expect(result).to eq(1)
        # Debug mode might show stack trace or additional information
        expect($stderr).to have_received(:write).with(match(/error/i)).at_least(:once)
      end
    end

    context "with glob patterns in report paths" do
      let(:glob_pattern) { File.join(temp_dir, "*.md") }

      before do
        allow(mock_report_collector).to receive(:collect_reports).and_return({
          success: true,
          reports: [
            {path: report1, content: "Content 1"},
            {path: report2, content: "Content 2"}
          ]
        })
        allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
        allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return({
          success: true,
          output_file: "/path/to/synthesis.md"
        })
      end

      it "handles glob patterns in report paths" do
        result = command.call(reports: [glob_pattern])

        expect(result).to eq(0)
        expect(mock_report_collector).to have_received(:collect_reports).with([glob_pattern])
      end
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.description).to eq("Synthesize multiple code review reports into unified analysis")
    end

    it "requires reports argument" do
      expect { command.call }.to raise_error(ArgumentError)
    end

    it "has default model option" do
      # This is tested in the successful synthesis context above
      expect(described_class.new).to respond_to(:call)
    end

    it "validates format option values" do
      # Test that only valid format values are accepted
      # This might be enforced by Dry::CLI validation
      
      # Set up mocks for the format validation test
      allow(mock_report_collector).to receive(:collect_reports).and_return({
        success: true,
        reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
      })
      allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
      allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return({
        success: true,
        output_file: "/path/to/synthesis.md"
      })
      
      %w[text json markdown].each do |valid_format|
        expect { command.call(reports: [report1, report2], format: valid_format) }.not_to raise_error
      end
    end

    it "has usage examples defined" do
      expect(described_class).to respond_to(:example)
    end
  end

  describe "integration with dependencies" do
    it "creates required component instances" do
      mock_collector = instance_double("CodingAgentTools::Molecules::Code::ReportCollector")
      mock_inferrer = instance_double("CodingAgentTools::Molecules::Code::SessionPathInferrer")
      mock_orchestrator = instance_double("CodingAgentTools::Molecules::Code::SynthesisOrchestrator")

      allow(mock_collector).to receive(:collect_reports).and_return({
        success: true,
        reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
      })
      allow(mock_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
      allow(mock_orchestrator).to receive(:synthesize).and_return({success: true})

      expect(CodingAgentTools::Molecules::Code::ReportCollector).to receive(:new).and_return(mock_collector)
      expect(CodingAgentTools::Molecules::Code::SessionPathInferrer).to receive(:new).and_return(mock_inferrer)
      expect(CodingAgentTools::Molecules::Code::SynthesisOrchestrator).to receive(:new).and_return(mock_orchestrator)

      command.call(reports: [report1, report2])
    end

    it "coordinates components correctly" do
      allow(mock_report_collector).to receive(:collect_reports).and_return({
        success: true,
        reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
      })
      allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/inferred/path.md")
      allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return({success: true})

      # Verify the workflow coordination
      expect(mock_report_collector).to receive(:collect_reports).ordered
      expect(mock_session_path_inferrer).to receive(:infer_output_path).ordered
      expect(mock_synthesis_orchestrator).to receive(:synthesize).ordered

      command.call(reports: [report1, report2])
    end
  end

  describe "return codes" do
    it "returns 0 for successful synthesis" do
      allow(mock_report_collector).to receive(:collect_reports).and_return({
        success: true,
        reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
      })
      allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/path.md")
      allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return({success: true})

      result = command.call(reports: [report1, report2])
      expect(result).to eq(0)
    end

    it "returns 1 for insufficient reports" do
      allow(mock_report_collector).to receive(:collect_reports).and_return({
        success: true,
        reports: [{path: report1, content: "Content 1"}]
      })
      result = command.call(reports: [report1])
      expect(result).to eq(1)
    end

    it "returns 1 for collection errors" do
      allow(mock_report_collector).to receive(:collect_reports).and_return({success: false, error: "Error"})
      result = command.call(reports: [report1, report2])
      expect(result).to eq(1)
    end

    it "returns 1 for synthesis errors" do
      allow(mock_report_collector).to receive(:collect_reports).and_return({
        success: true,
        reports: [{path: report1, content: "Content 1"}, {path: report2, content: "Content 2"}]
      })
      allow(mock_session_path_inferrer).to receive(:infer_output_path).and_return("/path.md")
      allow(mock_synthesis_orchestrator).to receive(:synthesize).and_return({success: false, error: "Error"})

      result = command.call(reports: [report1, report2])
      expect(result).to eq(1)
    end

    it "returns 1 for exceptions" do
      allow(mock_report_collector).to receive(:collect_reports).and_raise(StandardError)
      result = command.call(reports: [report1, report2])
      expect(result).to eq(1)
    end
  end
end
