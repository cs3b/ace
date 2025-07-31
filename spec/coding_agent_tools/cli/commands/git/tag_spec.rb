# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Git::Tag do
  let(:command) { described_class.new }
  let(:project_root) { "/fake/project/root" }
  let(:mock_orchestrator) { instance_double("CodingAgentTools::Organisms::Git::GitOrchestrator") }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe "#call" do
    context "with successful tag operation" do
      let(:success_result) do
        {
          success: true,
          results: {
            "main-repo" => {success: true, stdout: ""},
            "dev-tools" => {success: true, stdout: "v1.0.0\nv1.1.0\n"}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:tag).and_return(success_result)
      end

      it "executes tag and displays output" do
        output = capture_stdout { command.call }

        expect(output).to include("[main-repo] Clean working directory")
        expect(output).to include("[dev-tools] Output:")
        expect(output).to include("v1.0.0")
        expect(mock_orchestrator).to have_received(:tag)
      end

      it "returns 0 for successful execution" do
        result = command.call
        expect(result).to eq(0)
        expect(mock_orchestrator).to have_received(:tag)
      end

      it "passes default options to orchestrator" do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:tag).with(nil, nil, {})
      end
    end

    context "with options" do
      before do
        allow(mock_orchestrator).to receive(:tag).and_return({
          success: true,
          results: {}
        })
      end

      it "passes repository option" do
        capture_stdout { command.call(repository: "dev-tools") }

        expect(mock_orchestrator).to have_received(:tag).with(
          nil, nil, hash_including(repository: "dev-tools")
        )
      end

      it "passes main_only option" do
        capture_stdout { command.call(main_only: true) }

        expect(mock_orchestrator).to have_received(:tag).with(
          nil, nil, hash_including(main_only: true)
        )
      end

      it "passes submodules_only option" do
        capture_stdout { command.call(submodules_only: true) }

        expect(mock_orchestrator).to have_received(:tag).with(
          nil, nil, hash_including(submodules_only: true)
        )
      end

      it "passes git-specific options" do
        capture_stdout do
          command.call(
            annotate: true,
            sign: true,
            force: true,
            delete: true,
            list: true,
            message: "Test message"
          )
        end

        expect(mock_orchestrator).to have_received(:tag).with(
          nil, nil, hash_including(
            annotate: true,
            sign: true,
            force: true,
            delete: true,
            list: true,
            message: "Test message"
          )
        )
      end
    end

    context "with errors" do
      let(:error_result) do
        {
          success: false,
          errors: [
            {repository: "main-repo", message: "Not a git repository"},
            {repository: "dev-tools", message: "Permission denied", error: StandardError.new("Access denied")}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:tag).and_return(error_result)
      end

      it "displays error messages" do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("[main-repo] Error: Not a git repository")
        expect(stderr_output).to include("[dev-tools] Error: Permission denied")
      end

      it "shows debug information when debug enabled" do
        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include("StandardError: Permission denied")
      end

      it "suggests debug flag when not enabled" do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("Use --debug flag for more information")
      end

      it "returns 1 for failed execution" do
        result = capture_stderr { command.call }
        expect(command.call).to eq(1)
      end
    end

    context "with exceptions" do
      it "handles unexpected errors gracefully" do
        allow(mock_orchestrator).to receive(:tag).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("Error: Unexpected error")
        expect(stderr_output).to include("Use --debug flag for more information")
      end

      it "shows backtrace in debug mode" do
        allow(mock_orchestrator).to receive(:tag).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include("StandardError: Unexpected error")
        expect(stderr_output).to include("Backtrace:")
      end
    end

    context "with arguments" do
      before do
        allow(mock_orchestrator).to receive(:tag).and_return({
          success: true,
          results: {}
        })
      end

      it "passes tagname argument" do
        capture_stdout { command.call(tagname: "v1.0.0") }

        expect(mock_orchestrator).to have_received(:tag).with(
          "v1.0.0", nil, {}
        )
      end

      it "passes both tagname and commit arguments" do
        capture_stdout { command.call(tagname: "v1.0.0", commit: "abc123") }

        expect(mock_orchestrator).to have_received(:tag).with(
          "v1.0.0", "abc123", {}
        )
      end

      it "combines arguments with options" do
        capture_stdout { command.call(tagname: "v1.0.0", annotate: true, message: "Release") }

        expect(mock_orchestrator).to have_received(:tag).with(
          "v1.0.0", nil, hash_including(annotate: true, message: "Release")
        )
      end
    end
  end

  describe "option building" do
    it "builds minimal options for default call" do
      allow(mock_orchestrator).to receive(:tag).and_return({success: true, results: {}})

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:tag).with(nil, nil, {})
    end

    it "filters out false boolean options" do
      allow(mock_orchestrator).to receive(:tag).and_return({success: true, results: {}})

      capture_stdout { command.call(main_only: false, annotate: false) }

      expect(mock_orchestrator).to have_received(:tag).with(nil, nil, {})
    end

    it "includes true boolean options" do
      allow(mock_orchestrator).to receive(:tag).and_return({success: true, results: {}})

      capture_stdout { command.call(main_only: true, annotate: true) }

      expect(mock_orchestrator).to have_received(:tag).with(
        nil, nil, hash_including(main_only: true, annotate: true)
      )
    end
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end
end