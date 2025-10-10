# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "open3"

RSpec.describe CodingAgentTools::Molecules::Code::SynthesisOrchestrator do
  subject(:orchestrator) { described_class.new }

  let(:mock_session_info) do
    double("SessionInfo",
      has_session?: true,
      session_directory: "/path/to/session",
      session_type: "code_review",
      session_id: "123",
      metadata: {"project" => "test-app"})
  end

  let(:mock_session_info_no_session) do
    double("SessionInfo", has_session?: false)
  end

  let(:sample_reports) do
    [
      "/path/to/report1.md",
      "/path/to/report2.md"
    ]
  end

  let(:report1_content) { "# Report 1\n\nThis is the first review report." }
  let(:report2_content) { "# Report 2\n\nThis is the second review report." }
  let(:system_prompt_content) { "You are a code review synthesis expert." }

  describe "#synthesize_reports" do
    context "with successful synthesis" do
      before do
        # Mock file reading - handle encoding parameter properly
        allow(File).to receive(:read).with(sample_reports[0], encoding: "UTF-8").and_return(report1_content)
        allow(File).to receive(:read).with(sample_reports[1], encoding: "UTF-8").and_return(report2_content)
        allow(File).to receive(:read).with(described_class::DEFAULT_SYSTEM_PROMPT, encoding: "UTF-8").and_return(system_prompt_content)
        allow(File).to receive(:exist?).with(described_class::DEFAULT_SYSTEM_PROMPT).and_return(true)
        allow(File).to receive(:exist?).with("/output/synthesis.md").and_return(false)

        # Mock file operations for temporary files
        allow(File).to receive(:exist?).and_return(false) # Default for any other files
        allow(File).to receive(:unlink).and_return(true)

        # Mock tempfile creation
        allow(Tempfile).to receive(:new).and_return(mock_tempfile)

        # Mock Open3 for successful LLM call
        allow(Open3).to receive(:capture3).and_return([
          "Synthesis completed successfully\nInput: 500 tokens\nOutput: 200 tokens\nCost: $0.05",
          "",
          double("status", success?: true)
        ])

        # Mock llm-query executable finding
        allow(File).to receive(:executable?).and_return(false)
        allow(orchestrator).to receive(:`).with("which llm-query 2>/dev/null").and_return("/usr/local/bin/llm-query")
      end

      let(:mock_tempfile) do
        double("Tempfile").tap do |tf|
          allow(tf).to receive(:write)
          allow(tf).to receive(:close)
          allow(tf).to receive(:path).and_return("/tmp/synthesis-prompt123.md")
        end
      end

      it "returns successful synthesis result" do
        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md",
          format: "markdown"
        )

        expect(result).to be_a(described_class::SynthesisResult)
        expect(result.success?).to be true
        expect(result.output_path).to eq("/output/synthesis.md")
        expect(result.metrics[:reports_count]).to eq(2)
        expect(result.metrics[:input_tokens]).to eq(500)
        expect(result.metrics[:output_tokens]).to eq(200)
        expect(result.metrics[:cost]).to eq(0.05)
        expect(result.error).to be_nil
      end

      it "builds comprehensive synthesis prompt" do
        expect(orchestrator).to receive(:build_synthesis_prompt).with(
          sample_reports,
          mock_session_info,
          nil
        ).and_call_original

        orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md"
        )
      end

      it "executes LLM synthesis with correct command" do
        expected_cmd = [
          "/usr/local/bin/llm-query",
          "google:gemini-2.5-pro",
          "/tmp/synthesis-prompt123.md",
          "--output", "/output/synthesis.md",
          "--format", "markdown",
          "--force"
        ]

        expect(Open3).to receive(:capture3).with(*expected_cmd).and_return([
          "Success", "", double("status", success?: true)
        ])

        orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md",
          format: "markdown"
        )
      end

      it "cleans up temporary prompt file" do
        # The cleanup checks if file exists first, then unlinks
        expect(File).to receive(:exist?).with("/tmp/synthesis-prompt123.md").and_return(true)
        expect(File).to receive(:unlink).with("/tmp/synthesis-prompt123.md").and_return(true)

        orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md"
        )
      end
    end

    context "with custom system prompt" do
      let(:custom_prompt_path) { "/custom/system.prompt.md" }
      let(:custom_prompt_content) { "Custom synthesis instructions." }

      before do
        allow(File).to receive(:read).with(sample_reports[0], encoding: "UTF-8").and_return(report1_content)
        allow(File).to receive(:read).with(sample_reports[1], encoding: "UTF-8").and_return(report2_content)
        allow(File).to receive(:read).with(custom_prompt_path, encoding: "UTF-8").and_return(custom_prompt_content)
        allow(File).to receive(:exist?).with(custom_prompt_path).and_return(true)
        allow(File).to receive(:exist?).with("/output/synthesis.md").and_return(false)

        mock_successful_llm_call
      end

      it "uses custom system prompt when provided" do
        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md",
          system_prompt_path: custom_prompt_path
        )

        expect(result.success?).to be true
      end
    end

    context "with output file sequencing" do
      before do
        allow(File).to receive(:read).with(sample_reports[0], encoding: "UTF-8").and_return(report1_content)
        allow(File).to receive(:read).with(sample_reports[1], encoding: "UTF-8").and_return(report2_content)
        allow(File).to receive(:exist?).with(described_class::DEFAULT_SYSTEM_PROMPT).and_return(false)

        mock_successful_llm_call
      end

      it "sequences output file when file exists and force is false" do
        allow(File).to receive(:exist?).with("/output/synthesis.md").and_return(true)
        allow(File).to receive(:exist?).with("/output/synthesis.1.md").and_return(false)

        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md",
          force: false
        )

        expect(result.success?).to be true
        expect(result.output_path).to eq("/output/synthesis.1.md")
      end

      it "uses original path when force is true" do
        allow(File).to receive(:exist?).with("/output/synthesis.md").and_return(true)

        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md",
          force: true
        )

        expect(result.success?).to be true
        expect(result.output_path).to eq("/output/synthesis.md")
      end

      it "finds next available sequence number" do
        allow(File).to receive(:exist?).with("/output/synthesis.md").and_return(true)
        allow(File).to receive(:exist?).with("/output/synthesis.1.md").and_return(true)
        allow(File).to receive(:exist?).with("/output/synthesis.2.md").and_return(true)
        allow(File).to receive(:exist?).with("/output/synthesis.3.md").and_return(false)

        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md",
          force: false
        )

        expect(result.success?).to be true
        expect(result.output_path).to eq("/output/synthesis.3.md")
      end
    end

    context "with LLM execution failures" do
      before do
        allow(File).to receive(:read).with(sample_reports[0], encoding: "UTF-8").and_return(report1_content)
        allow(File).to receive(:read).with(sample_reports[1], encoding: "UTF-8").and_return(report2_content)
        allow(File).to receive(:exist?).with(described_class::DEFAULT_SYSTEM_PROMPT).and_return(false)
        allow(File).to receive(:exist?).with("/output/synthesis.md").and_return(false)

        mock_tempfile_operations
      end

      it "handles LLM command failures" do
        allow(Open3).to receive(:capture3).and_return([
          "",
          "Model not found error",
          double("status", success?: false)
        ])

        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "invalid:model",
          output_path: "/output/synthesis.md"
        )

        expect(result.success?).to be false
        expect(result.error).to include("LLM query failed")
        expect(result.error).to include("Model not found error")
      end

      it "handles exceptions during synthesis" do
        allow(Open3).to receive(:capture3).and_raise(StandardError.new("Network error"))

        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md"
        )

        expect(result.success?).to be false
        expect(result.error).to include("Synthesis orchestration failed")
        expect(result.error).to include("Network error")
      end
    end

    context "with file reading errors" do
      before do
        allow(File).to receive(:exist?).with(described_class::DEFAULT_SYSTEM_PROMPT).and_return(false)
        allow(File).to receive(:exist?).with("/output/synthesis.md").and_return(false)

        mock_tempfile_operations
        mock_successful_llm_call
      end

      it "handles report file reading errors gracefully" do
        allow(File).to receive(:read).with(sample_reports[0], encoding: "UTF-8").and_return(report1_content)
        allow(File).to receive(:read).with(sample_reports[1], encoding: "UTF-8").and_raise(StandardError.new("Permission denied"))

        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md"
        )

        # Should still succeed but include error message in prompt
        expect(result.success?).to be true
      end
    end

    context "without session info" do
      before do
        allow(File).to receive(:read).with(sample_reports[0], encoding: "UTF-8").and_return(report1_content)
        allow(File).to receive(:read).with(sample_reports[1], encoding: "UTF-8").and_return(report2_content)
        allow(File).to receive(:exist?).with(described_class::DEFAULT_SYSTEM_PROMPT).and_return(false)
        allow(File).to receive(:exist?).with("/output/synthesis.md").and_return(false)

        mock_tempfile_operations
        mock_successful_llm_call
      end

      it "works without session information" do
        result = orchestrator.synthesize_reports(
          reports: sample_reports,
          session_info: mock_session_info_no_session,
          model: "google:gemini-2.5-pro",
          output_path: "/output/synthesis.md"
        )

        expect(result.success?).to be true
      end
    end
  end

  describe "#synthesize" do
    context "with dry run mode" do
      it "returns dry run result without executing LLM" do
        result = orchestrator.synthesize(
          dry_run: true,
          reports: sample_reports,
          output_file: "/output/synthesis.md",
          model: "google:gemini-2.5-pro"
        )

        expect(result[:success]).to be true
        expect(result[:dry_run]).to be true
        expect(result[:reports_found]).to eq(2)
        expect(result[:output_file]).to eq("/output/synthesis.md")
        expect(result[:model]).to eq("google:gemini-2.5-pro")
      end
    end

    context "with regular synthesis" do
      before do
        mock_successful_synthesis_reports
      end

      it "delegates to synthesize_reports and converts result format" do
        result = orchestrator.synthesize(
          reports: sample_reports,
          output_file: "/output/synthesis.md",
          model: "google:gemini-2.5-pro",
          format: "markdown",
          force: true,
          debug: false
        )

        expect(result[:success]).to be true
        expect(result[:output_file]).to eq("/output/synthesis.md")
        expect(result[:error]).to be_nil
      end

      it "uses default values for missing options" do
        expect(orchestrator).to receive(:synthesize_reports).with(
          reports: [],
          session_info: nil,
          model: "google:gemini-2.5-pro",
          output_path: "cr-report.md",
          format: "markdown",
          system_prompt_path: nil,
          force: false,
          debug: false
        ).and_call_original

        orchestrator.synthesize
      end

      it "handles synthesis errors and returns hash format" do
        allow(orchestrator).to receive(:synthesize_reports).and_raise(StandardError.new("Synthesis failed"))

        result = orchestrator.synthesize(
          reports: sample_reports,
          output_file: "/output/synthesis.md"
        )

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Synthesis failed")
      end
    end
  end

  describe "SynthesisResult class" do
    describe "#initialize" do
      it "creates result with default values" do
        result = described_class::SynthesisResult.new

        expect(result.output_path).to be_nil
        expect(result.metrics).to eq({})
        expect(result.error).to be_nil
        expect(result.success?).to be false
        expect(result.failure?).to be true
      end

      it "creates result with provided values" do
        result = described_class::SynthesisResult.new(
          output_path: "/test.md",
          metrics: {cost: 0.02},
          error: "Test error",
          success: true
        )

        expect(result.output_path).to eq("/test.md")
        expect(result.metrics).to eq({cost: 0.02})
        expect(result.error).to eq("Test error")
        expect(result.success?).to be true
        expect(result.failure?).to be false
      end
    end
  end

  describe "private methods" do
    describe "#build_synthesis_prompt" do
      before do
        allow(File).to receive(:read).with(sample_reports[0], encoding: "UTF-8").and_return(report1_content)
        allow(File).to receive(:read).with(sample_reports[1], encoding: "UTF-8").and_return(report2_content)
        allow(File).to receive(:exist?).with(described_class::DEFAULT_SYSTEM_PROMPT).and_return(true)
        allow(File).to receive(:read).with(described_class::DEFAULT_SYSTEM_PROMPT, encoding: "UTF-8").and_return(system_prompt_content)
      end

      it "builds comprehensive prompt with all sections" do
        prompt = orchestrator.send(:build_synthesis_prompt, sample_reports, mock_session_info, nil)

        expect(prompt).to include("# System Instructions")
        expect(prompt).to include(system_prompt_content)
        expect(prompt).to include("# Session Context")
        expect(prompt).to include("**Session Directory**: /path/to/session")
        expect(prompt).to include("# Review Reports to Synthesize")
        expect(prompt).to include(report1_content)
        expect(prompt).to include(report2_content)
        expect(prompt).to include("# Synthesis Instructions")
        expect(prompt).to include("## Synthesis Goals")
      end

      it "omits session context when session info unavailable" do
        prompt = orchestrator.send(:build_synthesis_prompt, sample_reports, mock_session_info_no_session, nil)

        expect(prompt).not_to include("# Session Context")
      end
    end

    describe "#handle_output_sequencing" do
      it "returns original path when file doesn't exist" do
        allow(File).to receive(:exist?).with("/test.md").and_return(false)

        result = orchestrator.send(:handle_output_sequencing, "/test.md", false)
        expect(result).to eq("/test.md")
      end

      it "returns original path when force is true" do
        allow(File).to receive(:exist?).with("/test.md").and_return(true)

        result = orchestrator.send(:handle_output_sequencing, "/test.md", true)
        expect(result).to eq("/test.md")
      end

      it "returns sequenced path when file exists" do
        allow(File).to receive(:exist?).with("/test.md").and_return(true)
        allow(File).to receive(:exist?).with("/test.1.md").and_return(false)

        result = orchestrator.send(:handle_output_sequencing, "/test.md", false)
        expect(result).to eq("/test.1.md")
      end
    end

    describe "#parse_llm_query_output" do
      it "extracts metrics from LLM output" do
        output = "Processing complete\nInput: 750 tokens\nOutput: 300 tokens\nCost: $0.08"

        metrics = orchestrator.send(:parse_llm_query_output, output, "")

        expect(metrics[:input_tokens]).to eq(750)
        expect(metrics[:output_tokens]).to eq(300)
        expect(metrics[:cost]).to eq(0.08)
      end

      it "handles missing metrics gracefully" do
        output = "Processing complete"

        metrics = orchestrator.send(:parse_llm_query_output, output, "")

        expect(metrics).to eq({})
      end
    end

    describe "#find_llm_query_executable" do
      it "returns relative path when executable exists" do
        # The implementation calculates relative path from synthesis_orchestrator.rb to exe/llm-query
        relative_path = "/Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-tools/exe/llm-query"

        allow(File).to receive(:executable?).with(anything).and_return(false)
        allow(File).to receive(:executable?).with(relative_path).and_return(true)

        result = orchestrator.send(:find_llm_query_executable)
        expect(result).to eq(relative_path)
      end

      it "returns PATH result when relative path doesn't exist" do
        allow(File).to receive(:executable?).and_return(false)
        allow(orchestrator).to receive(:`).with("which llm-query 2>/dev/null").and_return("/usr/bin/llm-query\n")

        result = orchestrator.send(:find_llm_query_executable)
        expect(result).to eq("/usr/bin/llm-query")
      end

      it "returns fallback when neither relative nor PATH works" do
        allow(File).to receive(:executable?).and_return(false)
        allow(orchestrator).to receive(:`).with("which llm-query 2>/dev/null").and_return("")

        result = orchestrator.send(:find_llm_query_executable)
        expect(result).to eq("llm-query")
      end
    end
  end

  private

  def mock_tempfile_operations
    mock_tempfile = double("Tempfile")
    allow(mock_tempfile).to receive(:write)
    allow(mock_tempfile).to receive(:close)
    allow(mock_tempfile).to receive(:path).and_return("/tmp/synthesis-prompt123.md")
    allow(Tempfile).to receive(:new).and_return(mock_tempfile)

    # Allow any unlink operation
    allow(File).to receive(:unlink).and_return(true)
    # Allow any exist? check for temporary files
    allow(File).to receive(:exist?).and_return(false)
  end

  def mock_successful_llm_call
    mock_tempfile_operations

    allow(File).to receive(:executable?).and_return(false)
    allow(orchestrator).to receive(:`).with("which llm-query 2>/dev/null").and_return("/usr/local/bin/llm-query")

    allow(Open3).to receive(:capture3).and_return([
      "Success\nInput: 400 tokens\nOutput: 150 tokens\nCost: $0.03",
      "",
      double("status", success?: true)
    ])
  end

  def mock_successful_synthesis_reports
    result = described_class::SynthesisResult.new(
      output_path: "/output/synthesis.md",
      metrics: {cost: 0.02},
      success: true
    )

    allow(orchestrator).to receive(:synthesize_reports).and_return(result)
  end
end
