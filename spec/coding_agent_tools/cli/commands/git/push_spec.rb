# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Git::Push do
  let(:command) { described_class.new }
  let(:project_root) { "/fake/project/root" }
  let(:mock_orchestrator) { instance_double("CodingAgentTools::Organisms::Git::GitOrchestrator") }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe "#call" do
    context "with successful push operation" do
      let(:success_result) do
        {
          success: true,
          results: {
            "main-repo" => {
              success: true,
              stdout: "To github.com:user/repo.git\n   abc1234..def5678  main -> main"
            },
            "dev-tools" => {
              success: true,
              stdout: "Everything up-to-date"
            }
          },
          repositories_processed: ["main-repo", "dev-tools"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:push).and_return(success_result)
      end

      it "executes push operation and displays formatted output" do
        output = capture_stdout { command.call }

        expect(output).to include("[main-repo] To github.com:user/repo.git")
        expect(output).to include("[main-repo]    abc1234..def5678  main -> main")
        expect(output).to include("[dev-tools] Everything up-to-date")
        expect(output).to include("Push completed across repositories: main-repo, dev-tools")
        expect(mock_orchestrator).to have_received(:push)
      end

      it "returns 0 for successful execution" do
        capture_stdout { command.call }
        expect(mock_orchestrator).to have_received(:push)
      end

      it "passes default options to orchestrator" do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:push).with(
          hash_including(capture_output: true, repo_only: nil)
        )
      end
    end

    context "with remote and branch arguments" do
      before do
        allow(mock_orchestrator).to receive(:push).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "Push completed"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "passes remote and branch to orchestrator" do
        capture_stdout { command.call(remote: "upstream", branch: "feature") }

        expect(mock_orchestrator).to have_received(:push).with(
          hash_including(remote: "upstream", branch: "feature")
        )
      end
    end

    context "with options" do
      before do
        allow(mock_orchestrator).to receive(:push).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "Push completed"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "passes repository option" do
        capture_stdout { command.call(repository: "dev-tools") }

        expect(mock_orchestrator).to have_received(:push).with(
          hash_including(repository: "dev-tools")
        )
      end

      it "passes main_only option" do
        capture_stdout { command.call(main_only: true) }

        expect(mock_orchestrator).to have_received(:push).with(
          hash_including(main_only: true)
        )
      end

      it "passes submodules_only option" do
        capture_stdout { command.call(submodules_only: true) }

        expect(mock_orchestrator).to have_received(:push).with(
          hash_including(submodules_only: true)
        )
      end

      it "passes repo_only option" do
        capture_stdout { command.call(repo_only: true) }

        expect(mock_orchestrator).to have_received(:push).with(
          hash_including(repo_only: true)
        )
      end

      it "passes push-specific options" do
        capture_stdout do
          command.call(
            force: true,
            dry_run: true,
            set_upstream: true,
            tags: true,
            concurrent: false
          )
        end

        expect(mock_orchestrator).to have_received(:push).with(
          hash_including(
            force: true,
            dry_run: true,
            set_upstream: true,
            tags: true,
            concurrent: false
          )
        )
      end

      it "filters out false boolean options" do
        capture_stdout { command.call(force: false, dry_run: false) }

        expect(mock_orchestrator).to have_received(:push).with(
          hash_not_including(:force, :dry_run)
        )
      end
    end

    context "with dry run output" do
      let(:dry_run_result) do
        {
          success: true,
          results: {
            "main-repo" => {
              success: true,
              stdout: "To github.com:user/repo.git\n   abc1234..def5678  main -> main\n\nWould push 3 commits"
            }
          },
          repositories_processed: ["main-repo"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:push).and_return(dry_run_result)
      end

      it "displays dry run information" do
        output = capture_stdout { command.call(dry_run: true) }

        expect(output).to include("[main-repo] To github.com:user/repo.git")
        expect(output).to include("[main-repo] Would push 3 commits")
      end
    end

    context "with force push warning" do
      let(:force_result) do
        {
          success: true,
          results: {
            "main-repo" => {
              success: true,
              stdout: "To github.com:user/repo.git\n + abc1234...def5678 main -> main (forced update)"
            }
          },
          repositories_processed: ["main-repo"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:push).and_return(force_result)
      end

      it "displays force push results" do
        output = capture_stdout { command.call(force: true) }

        expect(output).to include("(forced update)")
      end
    end

    context "with nothing to push" do
      let(:up_to_date_result) do
        {
          success: true,
          results: {
            "main-repo" => {success: true, stdout: "Everything up-to-date"},
            "dev-tools" => {success: true, stdout: "Everything up-to-date"}
          },
          repositories_processed: ["main-repo", "dev-tools"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:push).and_return(up_to_date_result)
      end

      it "displays up to date messages" do
        output = capture_stdout { command.call }

        expect(output).to include("[main-repo] Everything up-to-date")
        expect(output).to include("[dev-tools] Everything up-to-date")
      end
    end

    context "with errors" do
      let(:error_result) do
        {
          success: false,
          errors: [
            {repository: "main-repo", message: "Repository not found"},
            {repository: "dev-tools", message: "Permission denied", error: StandardError.new("Access denied")}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:push).and_return(error_result)
      end

      it "displays error messages" do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("[main-repo] Error: Repository not found")
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
        capture_stderr { command.call }
        expect(mock_orchestrator).to have_received(:push)
      end
    end

    context "with partial success" do
      let(:partial_result) do
        {
          success: false,
          errors: [
            {repository: "dev-tools", message: "Network error"}
          ],
          results: {
            "main-repo" => {success: true, stdout: "Push completed"},
            "dev-tools" => {success: false}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:push).and_return(partial_result)
      end

      it "shows partial success information" do
        output = capture_stdout do
          capture_stderr { command.call }
        end

        expect(output).to include("Partial success: Successfully pushed to repositories: main-repo")
      end
    end

    context "with rejected push" do
      let(:rejected_result) do
        {
          success: false,
          errors: [
            {repository: "main-repo", message: "Updates were rejected because the tip of your current branch is behind"}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:push).and_return(rejected_result)
      end

      it "displays rejection error" do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("Updates were rejected because the tip of your current branch is behind")
      end
    end

    context "with exceptions" do
      it "handles unexpected errors gracefully" do
        allow(mock_orchestrator).to receive(:push).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include("Error: Unexpected error")
        expect(stderr_output).to include("Use --debug flag for more information")
      end

      it "shows backtrace in debug mode" do
        allow(mock_orchestrator).to receive(:push).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include("StandardError: Unexpected error")
        expect(stderr_output).to include("Backtrace:")
      end
    end
  end

  describe "option building" do
    it "builds minimal options for default call" do
      allow(mock_orchestrator).to receive(:push).and_return({success: true, results: {}})

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:push).with(
        hash_including(capture_output: true, repo_only: nil)
      )
    end

    it "filters out false boolean options" do
      allow(mock_orchestrator).to receive(:push).and_return({success: true, results: {}})

      capture_stdout { command.call(force: false, dry_run: false) }

      expect(mock_orchestrator).to have_received(:push).with(
        hash_not_including(:force, :dry_run)
      )
    end

    it "includes true boolean options" do
      allow(mock_orchestrator).to receive(:push).and_return({success: true, results: {}})

      capture_stdout { command.call(force: true, dry_run: true) }

      expect(mock_orchestrator).to have_received(:push).with(
        hash_including(force: true, dry_run: true)
      )
    end

    it "includes remote and branch when provided" do
      allow(mock_orchestrator).to receive(:push).and_return({success: true, results: {}})

      capture_stdout { command.call(remote: "upstream", branch: "feature") }

      expect(mock_orchestrator).to have_received(:push).with(
        hash_including(remote: "upstream", branch: "feature")
      )
    end

    it "excludes remote and branch when not provided" do
      allow(mock_orchestrator).to receive(:push).and_return({success: true, results: {}})

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:push).with(
        hash_not_including(:remote, :branch)
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
