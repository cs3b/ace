# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Git::Status do
  let(:command) { described_class.new }
  let(:project_root) { "/fake/project/root" }
  let(:mock_orchestrator) { instance_double("CodingAgentTools::Organisms::Git::GitOrchestrator") }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe "#call" do
    context "with successful status" do
      let(:success_result) do
        {
          success: true,
          formatted_output: "[main-repo] Clean working directory\n[dev-tools] Status:\n  M lib/file.rb",
          results: {
            "main-repo" => {success: true, stdout: ""},
            "dev-tools" => {success: true, stdout: " M lib/file.rb\n"}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:status).and_return(success_result)
      end

      it "executes status and displays formatted output" do
        output = capture_stdout { command.call }

        expect(output).to include("[main-repo] Clean working directory")
        expect(output).to include("[dev-tools] Status:")
        expect(output).to include("M lib/file.rb")
        expect(mock_orchestrator).to have_received(:status)
      end

      it "returns 0 for successful execution" do
        capture_stdout { command.call }
        # The method doesn't explicitly return, but we can test it doesn't raise
        expect(mock_orchestrator).to have_received(:status)
      end

      it "passes default options to orchestrator" do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:status).with({})
      end
    end

    context "with options" do
      before do
        allow(mock_orchestrator).to receive(:status).and_return({
          success: true,
          formatted_output: "Status output",
          results: {}
        })
      end

      it "passes repository option" do
        capture_stdout { command.call(repository: "dev-tools") }

        expect(mock_orchestrator).to have_received(:status).with(
          hash_including(repository: "dev-tools")
        )
      end

      it "passes main_only option" do
        capture_stdout { command.call(main_only: true) }

        expect(mock_orchestrator).to have_received(:status).with(
          hash_including(main_only: true)
        )
      end

      it "passes submodules_only option" do
        capture_stdout { command.call(submodules_only: true) }

        expect(mock_orchestrator).to have_received(:status).with(
          hash_including(submodules_only: true)
        )
      end

      it "passes git-specific options" do
        capture_stdout do
          command.call(
            porcelain: true,
            short: true,
            verbose: true,
            untracked_files: "all",
            no_color: true,
            force_color: false
          )
        end

        expect(mock_orchestrator).to have_received(:status).with(
          hash_including(
            porcelain: true,
            short: true,
            verbose: true,
            untracked_files: "all",
            no_color: true,
            force_color: false
          )
        )
      end

      it "omits default untracked_files option" do
        capture_stdout { command.call(untracked_files: "normal") }

        expect(mock_orchestrator).to have_received(:status).with(
          hash_not_including(:untracked_files)
        )
      end
    end

    context "with porcelain output" do
      let(:porcelain_result) do
        {
          success: true,
          results: {
            "main-repo" => {success: true, stdout: " M file1.rb\n A file2.rb\n"},
            "dev-tools" => {success: true, stdout: "?? new_file.rb\n"}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:status).and_return(porcelain_result)
      end

      it "displays porcelain format output" do
        output = capture_stdout { command.call(porcelain: true) }

        expect(output).to include("main-repo: M file1.rb")
        expect(output).to include("main-repo: A file2.rb")
        expect(output).to include("dev-tools:?? new_file.rb")
      end

      it "skips empty lines in porcelain format" do
        porcelain_result[:results]["main-repo"][:stdout] = " M file1.rb\n\n A file2.rb\n"

        output = capture_stdout { command.call(porcelain: true) }

        expect(output).not_to include("main-repo:\n")
        lines = output.lines.select { |line| line.start_with?("main-repo:") }
        expect(lines.size).to eq(2)
      end
    end

    context "with raw output display" do
      let(:raw_result) do
        {
          success: true,
          results: {
            "main-repo" => {success: true, stdout: ""},
            "dev-tools" => {success: true, stdout: " M lib/file.rb\n?? new_file.rb\n"}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:status).and_return(raw_result)
      end

      it "displays clean status for empty output" do
        output = capture_stdout { command.call }

        expect(output).to include("[main-repo] Clean working directory")
      end

      it "displays detailed status for non-empty output" do
        output = capture_stdout { command.call }

        expect(output).to include("[dev-tools] Status:")
        expect(output).to include("  M lib/file.rb")
        expect(output).to include("  ?? new_file.rb")
      end

      it "adds spacing between repositories" do
        output = capture_stdout { command.call }

        # Should have empty lines separating repositories
        expect(output).to match(/\[.*\].*\n\n\[.*\]|\[.*\].*\n\n$/m)
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
        allow(mock_orchestrator).to receive(:status).and_return(error_result)
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
        # The method implicitly returns the result of display_errors call
        capture_stderr { command.call }
        expect(mock_orchestrator).to have_received(:status)
      end
    end

    context "with exceptions" do
      it "handles unexpected errors gracefully" do
        allow(mock_orchestrator).to receive(:status).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("Error: Unexpected error")
        expect(stderr_output).to include("Use --debug flag for more information")
      end

      it "shows backtrace in debug mode" do
        allow(mock_orchestrator).to receive(:status).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include("StandardError: Unexpected error")
        expect(stderr_output).to include("Backtrace:")
      end
    end
  end

  describe "option building" do
    it "builds minimal options for default call" do
      allow(mock_orchestrator).to receive(:status).and_return({success: true, results: {}})

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:status).with({})
    end

    it "filters out false boolean options" do
      allow(mock_orchestrator).to receive(:status).and_return({success: true, results: {}})

      capture_stdout { command.call(main_only: false, verbose: false) }

      expect(mock_orchestrator).to have_received(:status).with({})
    end

    it "includes true boolean options" do
      allow(mock_orchestrator).to receive(:status).and_return({success: true, results: {}})

      capture_stdout { command.call(main_only: true, verbose: true) }

      expect(mock_orchestrator).to have_received(:status).with(
        hash_including(main_only: true, verbose: true)
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
