# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe CodingAgentTools::Cli::Commands::Git::Restore do
  let(:command) { described_class.new }
  let(:project_root) { "/fake/project/root" }
  let(:mock_orchestrator) { instance_double("CodingAgentTools::Organisms::Git::GitOrchestrator") }
  let(:pathspecs) { ["file.rb"] }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe "#call" do
    context "with successful restore operation" do
      let(:success_result) do
        {
          success: true,
          results: {
            "main-repo" => {success: true, stdout: ""},
            "dev-tools" => {success: true, stdout: ""}
          },
          repositories_processed: ["main-repo", "dev-tools"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:restore).and_return(success_result)
      end

      it "executes restore operation and displays formatted output" do
        output = capture_stdout { command.call(pathspecs: pathspecs) }

        expect(output).to include("[main-repo] Restore completed successfully")
        expect(output).to include("[dev-tools] Restore completed successfully")
        expect(output).to include("Restore operations completed across repositories: main-repo, dev-tools")
        expect(mock_orchestrator).to have_received(:restore).with(pathspecs, hash_including(capture_output: true))
      end

      it "returns 0 for successful execution" do
        capture_stdout { command.call(pathspecs: pathspecs) }
        expect(mock_orchestrator).to have_received(:restore)
      end

      it "passes pathspecs and default options to orchestrator" do
        capture_stdout { command.call(pathspecs: pathspecs) }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:restore).with(
          pathspecs,
          hash_including(capture_output: true)
        )
      end
    end

    context "with multiple pathspecs" do
      let(:multiple_pathspecs) { ["file1.rb", "file2.rb", "directory/"] }

      before do
        allow(mock_orchestrator).to receive(:restore).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "Restored 3 files"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "handles multiple pathspecs correctly" do
        output = capture_stdout { command.call(pathspecs: multiple_pathspecs) }

        expect(output).to include("[main-repo] Restored 3 files")
        expect(mock_orchestrator).to have_received(:restore).with(
          multiple_pathspecs,
          hash_including(capture_output: true)
        )
      end
    end

    context "with options" do
      before do
        allow(mock_orchestrator).to receive(:restore).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "Restore completed"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "passes repository option" do
        capture_stdout { command.call(pathspecs: pathspecs, repository: "dev-tools") }

        expect(mock_orchestrator).to have_received(:restore).with(
          pathspecs,
          hash_including(repository: "dev-tools")
        )
      end

      it "passes main_only option" do
        capture_stdout { command.call(pathspecs: pathspecs, main_only: true) }

        expect(mock_orchestrator).to have_received(:restore).with(
          pathspecs,
          hash_including(main_only: true)
        )
      end

      it "passes submodules_only option" do
        capture_stdout { command.call(pathspecs: pathspecs, submodules_only: true) }

        expect(mock_orchestrator).to have_received(:restore).with(
          pathspecs,
          hash_including(submodules_only: true)
        )
      end

      it "passes restore-specific options" do
        capture_stdout do
          command.call(
            pathspecs: pathspecs,
            source: "HEAD~1",
            staged: true,
            worktree: true,
            merge: true,
            conflict: "diff3",
            ours: true,
            theirs: false,
            patch: true,
            quiet: true,
            progress: true,
            concurrent: true
          )
        end

        expect(mock_orchestrator).to have_received(:restore).with(
          pathspecs,
          hash_including(
            source: "HEAD~1",
            staged: true,
            worktree: true,
            merge: true,
            conflict: "diff3",
            ours: true,
            patch: true,
            quiet: true,
            progress: true,
            concurrent: true
          )
        )
      end
    end

    context "with quiet option" do
      before do
        allow(mock_orchestrator).to receive(:restore).and_return({
          success: true,
          results: {
            "main-repo" => {success: true, stdout: "Restored file.rb"}
          },
          repositories_processed: ["main-repo"]
        })
      end

      it "suppresses output when quiet is true" do
        output = capture_stdout { command.call(pathspecs: pathspecs, quiet: true) }

        expect(output).not_to include("Restore operations completed across repositories")
        expect(output).to be_empty
      end

      it "shows output when quiet is false" do
        output = capture_stdout { command.call(pathspecs: pathspecs, quiet: false) }

        expect(output).to include("[main-repo] Restored file.rb")
        expect(output).to include("Restore operations completed across repositories")
      end
    end

    context "with restore failure" do
      let(:error_result) do
        {
          success: false,
          error: "Restore failed: error: pathspec 'nonexistent-file.rb' did not match any file(s) known to git",
          errors: [
            {repository: "main-repo", message: "pathspec 'nonexistent-file.rb' did not match any file(s) known to git"},
            {repository: "dev-tools", message: "pathspec 'nonexistent-file.rb' did not match any file(s) known to git"}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:restore).and_return(error_result)
      end

      it "displays error messages and returns 1" do
        output = capture_stderr { command.call(pathspecs: ["nonexistent-file.rb"]) }

        expect(output).to include("Restore failed: error: pathspec 'nonexistent-file.rb' did not match any file(s) known to git")
        expect(output).to include("[main-repo] Error: pathspec 'nonexistent-file.rb' did not match any file(s) known to git")
        expect(output).to include("[dev-tools] Error: pathspec 'nonexistent-file.rb' did not match any file(s) known to git")
        expect(output).to include("Use --debug flag for more information")
      end
    end

    context "with partial success" do
      let(:partial_result) do
        {
          success: false,
          results: {
            "main-repo" => {success: true, stdout: "Restored file.rb"},
            "dev-tools" => {success: false, error: "pathspec 'file.rb' did not match any file(s) known to git"}
          },
          errors: [
            {repository: "dev-tools", message: "pathspec 'file.rb' did not match any file(s) known to git"}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:restore).and_return(partial_result)
      end

      it "shows partial successes and errors" do
        output = capture_output { command.call(pathspecs: pathspecs) }

        expect(output).to include("Partial success: Restore completed in repositories: main-repo")
        expect(output).to include("[dev-tools] Error: pathspec 'file.rb' did not match any file(s) known to git")
      end
    end

    context "with debug option" do
      let(:error_with_debug) do
        {
          success: false,
          errors: [
            {
              repository: "main-repo",
              message: "pathspec 'nonexistent-file.rb' did not match any file(s) known to git",
              error: StandardError.new("detailed error")
            }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:restore).and_return(error_with_debug)
        allow(error_with_debug[:errors][0][:error]).to receive(:backtrace).and_return(["line1", "line2"])
      end

      it "shows detailed error information when debug is enabled" do
        output = capture_stderr { command.call(pathspecs: ["nonexistent-file.rb"], debug: true) }

        expect(output).to include("Error: StandardError: pathspec 'nonexistent-file.rb' did not match any file(s) known to git")
        expect(output).to include("line1")
        expect(output).to include("line2")
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
                {success: true, stdout: "Restored file1.rb"},
                {success: true, stdout: "Restored file2.rb"}
              ]
            }
          },
          repositories_processed: ["main-repo"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:restore).and_return(concurrent_result)
      end

      it "handles multiple commands from concurrent execution" do
        output = capture_stdout { command.call(pathspecs: pathspecs, concurrent: true) }

        expect(output).to include("[main-repo] Restored file1.rb")
        expect(output).to include("[main-repo] Restored file2.rb")
      end
    end

    context "with empty stdout results" do
      let(:empty_stdout_result) do
        {
          success: true,
          results: {
            "main-repo" => {success: true, stdout: ""},
            "dev-tools" => {success: true, output: ""}
          },
          repositories_processed: ["main-repo", "dev-tools"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:restore).and_return(empty_stdout_result)
      end

      it "displays default success message when stdout is empty" do
        output = capture_stdout { command.call(pathspecs: pathspecs) }

        expect(output).to include("[main-repo] Restore completed successfully")
        expect(output).to include("[dev-tools] Restore completed successfully")
      end
    end

    context "when exception occurs" do
      before do
        allow(mock_orchestrator).to receive(:restore).and_raise(StandardError.new("Unexpected error"))
      end

      it "handles exceptions and returns 1" do
        output = capture_stderr { command.call(pathspecs: pathspecs) }

        expect(output).to include("Error: Unexpected error")
        expect(output).to include("Use --debug flag for more information")
      end

      it "shows detailed error with debug flag" do
        allow_any_instance_of(StandardError).to receive(:backtrace).and_return(["line1", "line2"])
        
        output = capture_stderr { command.call(pathspecs: pathspecs, debug: true) }

        expect(output).to include("Error: StandardError: Unexpected error")
        expect(output).to include("Backtrace:")
        expect(output).to include("line1")
        expect(output).to include("line2")
      end
    end
  end

  describe "#build_restore_options" do
    let(:pathspecs) { ["file.rb"] }
    let(:options) do
      {
        repository: "dev-tools",
        main_only: true,
        source: "HEAD~1",
        staged: true,
        worktree: true
      }
    end

    it "builds correct options hash" do
      result = command.send(:build_restore_options, pathspecs, options)

      expect(result).to include(
        capture_output: true,
        repository: "dev-tools",
        main_only: true,
        source: "HEAD~1",
        staged: true,
        worktree: true
      )
    end

    it "only includes truthy options" do
      minimal_options = {staged: false, main_only: true}
      result = command.send(:build_restore_options, pathspecs, minimal_options)

      expect(result).to include(main_only: true)
      expect(result).not_to include(:staged)
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

  def capture_output
    old_stdout = $stdout
    old_stderr = $stderr
    
    stdout_capture = StringIO.new
    stderr_capture = StringIO.new
    
    $stdout = stdout_capture
    $stderr = stderr_capture
    
    yield
    
    stdout_capture.string + stderr_capture.string
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end