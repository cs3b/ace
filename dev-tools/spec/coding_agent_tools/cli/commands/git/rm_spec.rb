# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe CodingAgentTools::Cli::Commands::Git::Rm do
  let(:command) { described_class.new }
  let(:project_root) { "/fake/project/root" }
  let(:mock_orchestrator) { instance_double("CodingAgentTools::Organisms::Git::GitOrchestrator") }
  let(:files) { ["file.rb"] }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe "#call" do
    context "with successful remove operation" do
      let(:success_result) do
        {
          success: true,
          results: {
            "main-repo" => {success: true, stdout: "rm 'file.rb'"},
            "dev-tools" => {success: true, stdout: ""}
          },
          repositories_processed: ["main-repo", "dev-tools"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:rm).and_return(success_result)
      end

      it "executes rm operation and displays formatted output" do
        output = capture_stdout { command.call(files: files) }

        expect(output).to include("[main-repo] rm 'file.rb'")
        expect(output).to include("[dev-tools] Remove completed successfully")
        expect(output).to include("Remove operations completed across repositories: main-repo, dev-tools")
        expect(mock_orchestrator).to have_received(:rm).with(files, hash_including(capture_output: true))
      end

      it "returns 0 for successful execution" do
        capture_stdout { command.call(files: files) }
        expect(mock_orchestrator).to have_received(:rm)
      end

      it "passes files and default options to orchestrator" do
        capture_stdout { command.call(files: files) }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:rm).with(
          files,
          hash_including(capture_output: true)
        )
      end
    end

    context "with multiple files" do
      let(:multiple_files) { ["file1.rb", "file2.rb", "directory/"] }

      before do
        allow(mock_orchestrator).to receive(:rm).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "rm 'file1.rb' 'file2.rb' 'directory/'"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "handles multiple files correctly" do
        output = capture_stdout { command.call(files: multiple_files) }

        expect(output).to include("[main-repo] rm 'file1.rb' 'file2.rb' 'directory/'")
        expect(mock_orchestrator).to have_received(:rm).with(
          multiple_files,
          hash_including(capture_output: true)
        )
      end
    end

    context "with options" do
      before do
        allow(mock_orchestrator).to receive(:rm).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "Remove completed"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "passes repository option" do
        capture_stdout { command.call(files: files, repository: "dev-tools") }

        expect(mock_orchestrator).to have_received(:rm).with(
          files,
          hash_including(repository: "dev-tools")
        )
      end

      it "passes main_only option" do
        capture_stdout { command.call(files: files, main_only: true) }

        expect(mock_orchestrator).to have_received(:rm).with(
          files,
          hash_including(main_only: true)
        )
      end

      it "passes submodules_only option" do
        capture_stdout { command.call(files: files, submodules_only: true) }

        expect(mock_orchestrator).to have_received(:rm).with(
          files,
          hash_including(submodules_only: true)
        )
      end

      it "passes rm-specific options" do
        capture_stdout do
          command.call(
            files: files,
            force: true,
            dry_run: true,
            recursive: true,
            cached: true,
            ignore_unmatch: true,
            quiet: true,
            concurrent: true
          )
        end

        expect(mock_orchestrator).to have_received(:rm).with(
          files,
          hash_including(
            force: true,
            dry_run: true,
            recursive: true,
            cached: true,
            ignore_unmatch: true,
            quiet: true,
            concurrent: true
          )
        )
      end
    end

    context "with quiet option" do
      before do
        allow(mock_orchestrator).to receive(:rm).and_return({
          success: true,
          results: {
            "main-repo" => {success: true, stdout: "rm 'file.rb'"}
          },
          repositories_processed: ["main-repo"]
        })
      end

      it "suppresses output when quiet is true" do
        output = capture_stdout { command.call(files: files, quiet: true) }

        expect(output).not_to include("Remove operations completed across repositories")
        expect(output).to be_empty
      end

      it "shows output when quiet is false" do
        output = capture_stdout { command.call(files: files, quiet: false) }

        expect(output).to include("[main-repo] rm 'file.rb'")
        expect(output).to include("Remove operations completed across repositories")
      end
    end

    context "with remove failure" do
      let(:error_result) do
        {
          success: false,
          error: "Remove failed: fatal: pathspec 'nonexistent-file.rb' did not match any files",
          errors: [
            {repository: "main-repo", message: "fatal: pathspec 'nonexistent-file.rb' did not match any files"},
            {repository: "dev-tools", message: "fatal: pathspec 'nonexistent-file.rb' did not match any files"}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:rm).and_return(error_result)
      end

      it "displays error messages and returns 1" do
        output = capture_stderr { command.call(files: ["nonexistent-file.rb"]) }

        expect(output).to include("Remove failed: fatal: pathspec 'nonexistent-file.rb' did not match any files")
        expect(output).to include("[main-repo] Error: fatal: pathspec 'nonexistent-file.rb' did not match any files")
        expect(output).to include("[dev-tools] Error: fatal: pathspec 'nonexistent-file.rb' did not match any files")
        expect(output).to include("Use --debug flag for more information")
      end
    end

    context "with partial success" do
      let(:partial_result) do
        {
          success: false,
          results: {
            "main-repo" => {success: true, stdout: "rm 'file.rb'"},
            "dev-tools" => {success: false, error: "fatal: pathspec 'file.rb' did not match any files"}
          },
          errors: [
            {repository: "dev-tools", message: "fatal: pathspec 'file.rb' did not match any files"}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:rm).and_return(partial_result)
      end

      it "shows partial successes and errors" do
        output = capture_output { command.call(files: files) }

        expect(output).to include("Partial success: Remove completed in repositories: main-repo")
        expect(output).to include("[dev-tools] Error: fatal: pathspec 'file.rb' did not match any files")
      end
    end

    context "with debug option" do
      let(:error_with_debug) do
        {
          success: false,
          errors: [
            {
              repository: "main-repo",
              message: "fatal: pathspec 'nonexistent-file.rb' did not match any files",
              error: StandardError.new("detailed error")
            }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:rm).and_return(error_with_debug)
        allow(error_with_debug[:errors][0][:error]).to receive(:backtrace).and_return(["line1", "line2"])
      end

      it "shows detailed error information when debug is enabled" do
        output = capture_stderr { command.call(files: ["nonexistent-file.rb"], debug: true) }

        expect(output).to include("Error: StandardError: fatal: pathspec 'nonexistent-file.rb' did not match any files")
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
                {success: true, stdout: "rm 'file1.rb'"},
                {success: true, stdout: "rm 'file2.rb'"}
              ]
            }
          },
          repositories_processed: ["main-repo"]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:rm).and_return(concurrent_result)
      end

      it "handles multiple commands from concurrent execution" do
        output = capture_stdout { command.call(files: files, concurrent: true) }

        expect(output).to include("[main-repo] rm 'file1.rb'")
        expect(output).to include("[main-repo] rm 'file2.rb'")
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
        allow(mock_orchestrator).to receive(:rm).and_return(empty_stdout_result)
      end

      it "displays default success message when stdout is empty" do
        output = capture_stdout { command.call(files: files) }

        expect(output).to include("[main-repo] Remove completed successfully")
        expect(output).to include("[dev-tools] Remove completed successfully")
      end
    end

    context "when exception occurs" do
      before do
        allow(mock_orchestrator).to receive(:rm).and_raise(StandardError.new("Unexpected error"))
      end

      it "handles exceptions and returns 1" do
        output = capture_stderr { command.call(files: files) }

        expect(output).to include("Error: Unexpected error")
        expect(output).to include("Use --debug flag for more information")
      end

      it "shows detailed error with debug flag" do
        allow_any_instance_of(StandardError).to receive(:backtrace).and_return(["line1", "line2"])

        output = capture_stderr { command.call(files: files, debug: true) }

        expect(output).to include("Error: StandardError: Unexpected error")
        expect(output).to include("Backtrace:")
        expect(output).to include("line1")
        expect(output).to include("line2")
      end
    end
  end

  describe "#build_rm_options" do
    let(:files) { ["file.rb"] }
    let(:options) do
      {
        repository: "dev-tools",
        main_only: true,
        force: true,
        cached: true,
        recursive: true
      }
    end

    it "builds correct options hash" do
      result = command.send(:build_rm_options, files, options)

      expect(result).to include(
        capture_output: true,
        repository: "dev-tools",
        main_only: true,
        force: true,
        cached: true,
        recursive: true
      )
    end

    it "only includes truthy options" do
      minimal_options = {force: false, main_only: true}
      result = command.send(:build_rm_options, files, minimal_options)

      expect(result).to include(main_only: true)
      expect(result).not_to include(:force)
    end

    it "includes all available rm options when provided" do
      comprehensive_options = {
        repository: "test-repo",
        main_only: true,
        submodules_only: true,
        force: true,
        dry_run: true,
        recursive: true,
        cached: true,
        ignore_unmatch: true,
        quiet: true,
        concurrent: true
      }

      result = command.send(:build_rm_options, files, comprehensive_options)

      expect(result).to include(
        capture_output: true,
        repository: "test-repo",
        main_only: true,
        submodules_only: true,
        force: true,
        dry_run: true,
        recursive: true,
        cached: true,
        ignore_unmatch: true,
        quiet: true,
        concurrent: true
      )
    end

    it "handles empty options gracefully" do
      result = command.send(:build_rm_options, files, {})

      expect(result).to eq({capture_output: true})
    end

    it "does not include falsy boolean options" do
      options_with_false = {
        force: false,
        dry_run: false,
        recursive: false,
        cached: false,
        ignore_unmatch: false,
        quiet: false,
        concurrent: false,
        main_only: true
      }

      result = command.send(:build_rm_options, files, options_with_false)

      expect(result).to include(capture_output: true, main_only: true)
      expect(result).not_to include(:force, :dry_run, :recursive, :cached, :ignore_unmatch, :quiet, :concurrent)
    end
  end

  describe "return codes" do
    context "successful operations" do
      before do
        allow(mock_orchestrator).to receive(:rm).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "rm 'file.rb'"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "returns 0 on success" do
        result = nil
        capture_stdout { result = command.call(files: files) }
        expect(result).to eq(0)
      end
    end

    context "failed operations" do
      before do
        allow(mock_orchestrator).to receive(:rm).and_return({
          success: false,
          error: "Remove failed",
          errors: [{repository: "main-repo", message: "fatal: pathspec did not match any files"}]
        })
      end

      it "returns 1 on failure" do
        result = nil
        capture_stderr { result = command.call(files: files) }
        expect(result).to eq(1)
      end
    end

    context "when exceptions occur" do
      before do
        allow(mock_orchestrator).to receive(:rm).and_raise(StandardError.new("Unexpected error"))
      end

      it "returns 1 on exception" do
        result = nil
        capture_stderr { result = command.call(files: files) }
        expect(result).to eq(1)
      end
    end
  end

  describe "edge case file handling" do
    context "with special characters in filenames" do
      let(:special_files) { ["file with spaces.rb", "file@special#chars.rb", "unicode文件.rb"] }

      before do
        allow(mock_orchestrator).to receive(:rm).and_return({
          success: true,
          results: {"main-repo" => {success: true, stdout: "rm special files"}},
          repositories_processed: ["main-repo"]
        })
      end

      it "handles files with special characters" do
        output = capture_stdout { command.call(files: special_files) }

        expect(output).to include("[main-repo] rm special files")
        expect(mock_orchestrator).to have_received(:rm).with(special_files, hash_including(capture_output: true))
      end
    end

    context "with empty file arrays" do
      it "still passes empty array to orchestrator" do
        allow(mock_orchestrator).to receive(:rm).and_return({success: true, results: {}, repositories_processed: []})

        capture_stdout { command.call(files: []) }

        expect(mock_orchestrator).to have_received(:rm).with([], hash_including(capture_output: true))
      end
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
