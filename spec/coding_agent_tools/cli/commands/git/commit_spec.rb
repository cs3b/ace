# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Git::Commit do
  let(:command) { described_class.new }
  let(:project_root) { "/fake/project/root" }
  let(:mock_orchestrator) { instance_double("CodingAgentTools::Organisms::Git::GitOrchestrator") }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe "#call" do
    context "with successful commit operation" do
      let(:success_result) do
        {
          success: true,
          results: {
            "main-repo" => {success: true, stdout: "[main 1234567] feat: implement user authentication"},
            "dev-tools" => {success: true, stdout: "[main abcdefg] fix: update validation logic"}
          },
          repositories_processed: ["main-repo", "dev-tools"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:commit).and_return(success_result)
      end

      it "executes commit operation and displays formatted output" do
        output = capture_stdout { command.call }

        expect(output).to include("[main-repo] [main 1234567] feat: implement user authentication")
        expect(output).to include("[dev-tools] [main abcdefg] fix: update validation logic")
        expect(output).to include("Commit completed across repositories: main-repo, dev-tools")
        expect(mock_orchestrator).to have_received(:commit)
      end

      it "returns 0 for successful execution" do
        capture_stdout { command.call }
        expect(mock_orchestrator).to have_received(:commit)
      end

      it "passes default options to orchestrator" do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(files: [], capture_output: true, repo_only: nil)
        )
      end
    end

    context "with files argument" do
      let(:files) { ["file1.rb", "file2.rb"] }

      before do
        allow(mock_orchestrator).to receive(:commit).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "Commit successful"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "passes files to orchestrator" do
        capture_stdout { command.call(files: files) }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(files: files)
        )
      end
    end

    context "with options" do
      before do
        allow(mock_orchestrator).to receive(:commit).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "Commit successful"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "passes repository option" do
        capture_stdout { command.call(repository: "dev-tools") }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(repository: "dev-tools")
        )
      end

      it "passes main_only option" do
        capture_stdout { command.call(main_only: true) }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(main_only: true)
        )
      end

      it "passes submodules_only option" do
        capture_stdout { command.call(submodules_only: true) }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(submodules_only: true)
        )
      end

      it "passes repo_only option" do
        capture_stdout { command.call(repo_only: true) }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(repo_only: true)
        )
      end

      it "passes commit-specific options" do
        capture_stdout do
          command.call(
            all: true,
            message: "Custom message",
            no_edit: true,
            concurrent: true,
            intention: "fix bug"
          )
        end

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(
            all: true,
            message: "Custom message",
            no_edit: true,
            concurrent: true,
            intention: "fix bug"
          )
        )
      end

      it "handles model option" do
        capture_stdout { command.call(model: "anthropic:claude-3.5-sonnet") }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(model: "anthropic:claude-3.5-sonnet")
        )
      end

      it "handles local option by setting model" do
        capture_stdout { command.call(local: true) }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(model: "lmstudio:mistral-small-3.1-24b-instruct-2503")
        )
      end

      it "prefers explicit model over local flag" do
        capture_stdout { command.call(model: "google:gemini-2.5-flash", local: true) }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_including(model: "google:gemini-2.5-flash")
        )
      end

      it "filters out false boolean options" do
        capture_stdout { command.call(all: false, no_edit: false) }

        expect(mock_orchestrator).to have_received(:commit).with(
          hash_not_including(:all, :no_edit)
        )
      end
    end

    context "with concurrent execution results" do
      let(:concurrent_result) do
        {
          success: true,
          results: {
            "main-repo" => {
              success: true,
              commands: [
                {success: true, stdout: "[main 1234567] feat: add feature"},
                {success: true, stdout: "[main 2345678] fix: minor bug"}
              ]
            }
          },
          repositories_processed: ["main-repo"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:commit).and_return(concurrent_result)
      end

      it "displays results from concurrent commands" do
        output = capture_stdout { command.call(concurrent: true) }

        expect(output).to include("[main-repo] [main 1234567] feat: add feature")
        expect(output).to include("[main-repo] [main 2345678] fix: minor bug")
        expect(output).to include("Commit completed across repositories: main-repo")
      end
    end

    context "with empty output" do
      let(:empty_result) do
        {
          success: true,
          results: {
            "dev-tools" => {success: true, stdout: ""}
          },
          repositories_processed: ["dev-tools"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:commit).and_return(empty_result)
      end

      it "displays success message for empty output" do
        output = capture_stdout { command.call }

        expect(output).to include("[dev-tools] Commit successful")
      end
    end

    context "with errors" do
      let(:error_result) do
        {
          success: false,
          errors: [
            {repository: "main-repo", message: "Nothing to commit"},
            {repository: "dev-tools", message: "Commit failed", error: StandardError.new("Pre-commit hook failed")}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:commit).and_return(error_result)
      end

      it "displays error messages" do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("[main-repo] Error: Nothing to commit")
        expect(stderr_output).to include("[dev-tools] Error: Commit failed")
      end

      it "shows debug information when debug enabled" do
        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include("StandardError: Commit failed")
      end

      it "suggests debug flag when not enabled" do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("Use --debug flag for more information")
      end

      it "returns 1 for failed execution" do
        capture_stderr { command.call }
        expect(mock_orchestrator).to have_received(:commit)
      end
    end

    context "with partial success" do
      let(:partial_result) do
        {
          success: false,
          errors: [
            {repository: "dev-tools", message: "Pre-commit hook failed"}
          ],
          results: {
            "main-repo" => {success: true, stdout: "[main 1234567] feat: implement feature"},
            "dev-tools" => {success: false}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:commit).and_return(partial_result)
      end

      it "shows partial success information" do
        output = capture_stdout do
          capture_stderr { command.call }
        end

        expect(output).to include("Partial success: Committed in repositories: main-repo")
      end
    end

    context "with orchestrator error" do
      let(:orchestrator_error_result) do
        {
          success: false,
          error: "No changes to commit"
        }
      end

      before do
        allow(mock_orchestrator).to receive(:commit).and_return(orchestrator_error_result)
      end

      it "displays orchestrator error" do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("Commit failed: No changes to commit")
      end
    end

    context "with exceptions" do
      it "handles unexpected errors gracefully" do
        allow(mock_orchestrator).to receive(:commit).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("Error: Unexpected error")
        expect(stderr_output).to include("Use --debug flag for more information")
      end

      it "shows backtrace in debug mode" do
        allow(mock_orchestrator).to receive(:commit).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include("StandardError: Unexpected error")
        expect(stderr_output).to include("Backtrace:")
      end
    end
  end

  describe "option building" do
    it "builds minimal options for default call" do
      allow(mock_orchestrator).to receive(:commit).and_return({success: true, results: {}})

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:commit).with(
        hash_including(files: [], capture_output: true, repo_only: nil)
      )
    end

    it "filters out false boolean options" do
      allow(mock_orchestrator).to receive(:commit).and_return({success: true, results: {}})

      capture_stdout { command.call(all: false, no_edit: false) }

      expect(mock_orchestrator).to have_received(:commit).with(
        hash_not_including(:all, :no_edit)
      )
    end

    it "includes true boolean options" do
      allow(mock_orchestrator).to receive(:commit).and_return({success: true, results: {}})

      capture_stdout { command.call(all: true, no_edit: true) }

      expect(mock_orchestrator).to have_received(:commit).with(
        hash_including(all: true, no_edit: true)
      )
    end

    it "handles debug option" do
      allow(mock_orchestrator).to receive(:commit).and_return({success: true, results: {}})

      capture_stdout { command.call(debug: true) }

      expect(mock_orchestrator).to have_received(:commit).with(
        hash_including(debug: true)
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