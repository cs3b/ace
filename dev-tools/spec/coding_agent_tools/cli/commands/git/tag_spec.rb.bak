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
    context "with successful tag creation" do
      let(:success_result) do
        {
          success: true,
          formatted_output: "[main] Tag creation completed successfully\n[dev-tools] Tag creation completed successfully",
          results: {
            "main" => {success: true, stdout: ""},
            "dev-tools" => {success: true, stdout: ""}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:tag).and_return(success_result)
      end

      it "executes tag creation and displays formatted output" do
        output = capture_stdout { command.call(tagname: "v1.0.0") }

        expect(output).to include("[main] Tag creation completed successfully")
        expect(output).to include("[dev-tools] Tag creation completed successfully")
        expect(mock_orchestrator).to have_received(:tag)
      end

      it "returns 0 for successful execution" do
        result = command.call(tagname: "v1.0.0")
        expect(result).to eq(0)
        expect(mock_orchestrator).to have_received(:tag)
      end

      it "passes tagname to orchestrator" do
        capture_stdout { command.call(tagname: "v1.0.0") }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(tagname: "v1.0.0")
        )
      end
    end

    context "with tag listing" do
      let(:list_result) do
        {
          success: true,
          results: {
            "main" => {success: true, stdout: "v1.0.0\nv1.1.0\nv2.0.0\n"},
            "dev-tools" => {success: true, stdout: "v1.0.0\nv1.1.0\n"}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:tag).and_return(list_result)
      end

      it "displays tag list output" do
        output = capture_stdout { command.call(list: true) }

        expect(output).to include("[main] Tags:")
        expect(output).to include("v1.0.0")
        expect(output).to include("v1.1.0")
        expect(output).to include("v2.0.0")
        expect(output).to include("[dev-tools] Tags:")
      end

      it "passes list option to orchestrator" do
        capture_stdout { command.call(list: true) }

        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(list: true)
        )
      end
    end

    context "with annotated tag options" do
      before do
        allow(mock_orchestrator).to receive(:tag).and_return({
          success: true,
          formatted_output: "Tag creation completed",
          results: {}
        })
      end

      it "passes annotated tag options" do
        capture_stdout do
          command.call(
            tagname: "v1.0.0",
            annotate: true,
            message: "Release version 1.0.0",
            sign: true,
            local_user: "user@example.com"
          )
        end

        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(
            tagname: "v1.0.0",
            annotate: true,
            message: "Release version 1.0.0",
            sign: true,
            local_user: "user@example.com"
          )
        )
      end

      it "passes force and delete options" do
        capture_stdout do
          command.call(
            tagname: "v1.0.0",
            force: true,
            delete: true
          )
        end

        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(
            tagname: "v1.0.0",
            force: true,
            delete: true
          )
        )
      end
    end

    context "with repository filtering options" do
      before do
        allow(mock_orchestrator).to receive(:tag).and_return({
          success: true,
          formatted_output: "Tag operation completed",
          results: {}
        })
      end

      it "passes repository option" do
        capture_stdout { command.call(tagname: "v1.0.0", repository: "dev-tools") }

        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(repository: "dev-tools")
        )
      end

      it "passes main_only option" do
        capture_stdout { command.call(tagname: "v1.0.0", main_only: true) }

        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(main_only: true)
        )
      end

      it "passes submodules_only option" do
        capture_stdout { command.call(tagname: "v1.0.0", submodules_only: true) }

        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(submodules_only: true)
        )
      end
    end

    context "with commit reference" do
      before do
        allow(mock_orchestrator).to receive(:tag).and_return({
          success: true,
          formatted_output: "Tag creation completed",
          results: {}
        })
      end

      it "passes commit reference to orchestrator" do
        capture_stdout { command.call(tagname: "v1.0.0", commit: "abc123") }

        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(
            tagname: "v1.0.0",
            commit: "abc123"
          )
        )
      end
    end

    context "with verification option" do
      let(:verify_result) do
        {
          success: true,
          results: {
            "main" => {success: true, stdout: "object abc123\ntype commit\ntag v1.0.0"},
            "dev-tools" => {success: true, stdout: "object def456\ntype commit\ntag v1.0.0"}
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:tag).and_return(verify_result)
      end

      it "displays verification output" do
        output = capture_stdout { command.call(tagname: "v1.0.0", verify: true) }

        expect(output).to include("[main] Tags:")
        expect(output).to include("object abc123")
        expect(output).to include("[dev-tools] Tags:")
        expect(output).to include("object def456")
      end

      it "passes verify option to orchestrator" do
        capture_stdout { command.call(tagname: "v1.0.0", verify: true) }

        expect(mock_orchestrator).to have_received(:tag).with(
          hash_including(verify: true)
        )
      end
    end

    context "with errors" do
      let(:error_result) do
        {
          success: false,
          errors: [
            {repository: "main", message: "tag 'v1.0.0' already exists"},
            {repository: "dev-tools", message: "not a git repository", error: StandardError.new("Git error")}
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:tag).and_return(error_result)
      end

      it "displays error messages" do
        stderr_output = capture_stderr { command.call(tagname: "v1.0.0") }

        expect(stderr_output).to include("[main] Error: tag 'v1.0.0' already exists")
        expect(stderr_output).to include("[dev-tools] Error: not a git repository")
      end

      it "shows debug information when debug enabled" do
        stderr_output = capture_stderr { command.call(tagname: "v1.0.0", debug: true) }

        expect(stderr_output).to include("StandardError: not a git repository")
      end

      it "suggests debug flag when not enabled" do
        stderr_output = capture_stderr { command.call(tagname: "v1.0.0") }

        expect(stderr_output).to include("Use --debug flag for more information")
      end

      it "returns 1 for failed execution" do
        result = capture_stderr { command.call(tagname: "v1.0.0") }
        expect(command.call(tagname: "v1.0.0")).to eq(1)
      end
    end

    context "with exceptions" do
      it "handles unexpected errors gracefully" do
        allow(mock_orchestrator).to receive(:tag).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call(tagname: "v1.0.0") }

        expect(stderr_output).to include("Error: Unexpected error")
        expect(stderr_output).to include("Use --debug flag for more information")
      end

      it "shows backtrace in debug mode" do
        allow(mock_orchestrator).to receive(:tag).and_raise(StandardError, "Unexpected error")

        stderr_output = capture_stderr { command.call(tagname: "v1.0.0", debug: true) }

        expect(stderr_output).to include("StandardError: Unexpected error")
        expect(stderr_output).to include("Backtrace:")
      end
    end
  end

  describe "option building" do
    before do
      allow(mock_orchestrator).to receive(:tag).and_return({success: true, results: {}})
    end

    it "builds minimal options for simple tag creation" do
      capture_stdout { command.call(tagname: "v1.0.0") }

      expect(mock_orchestrator).to have_received(:tag).with(
        hash_including(tagname: "v1.0.0")
      )
    end

    it "filters out false boolean options" do
      capture_stdout { command.call(tagname: "v1.0.0", annotate: false, force: false) }

      expect(mock_orchestrator).to have_received(:tag).with(
        hash_including(tagname: "v1.0.0")
      )
    end

    it "includes true boolean options" do
      capture_stdout { command.call(tagname: "v1.0.0", annotate: true, force: true) }

      expect(mock_orchestrator).to have_received(:tag).with(
        hash_including(tagname: "v1.0.0", annotate: true, force: true)
      )
    end

    it "includes string options when provided" do
      capture_stdout do
        command.call(
          tagname: "v1.0.0",
          message: "Release message",
          file: "/path/to/message.txt",
          local_user: "user@example.com"
        )
      end

      expect(mock_orchestrator).to have_received(:tag).with(
        hash_including(
          tagname: "v1.0.0",
          message: "Release message",
          file: "/path/to/message.txt",
          local_user: "user@example.com"
        )
      )
    end
  end

  describe "output determination" do
    it "identifies tag creation operation" do
      allow(mock_orchestrator).to receive(:tag).and_return({
        success: true,
        results: {"main" => {success: true}}
      })

      output = capture_stdout { command.call(tagname: "v1.0.0") }
      expect(output).to include("Tag creation completed successfully")
    end

    it "identifies tag deletion operation" do
      allow(mock_orchestrator).to receive(:tag).and_return({
        success: true,
        results: {"main" => {success: true}}
      })

      output = capture_stdout { command.call(tagname: "v1.0.0", delete: true) }
      expect(output).to include("Tag deletion completed successfully")
    end

    it "identifies tag verification operation" do
      allow(mock_orchestrator).to receive(:tag).and_return({
        success: true,
        results: {"main" => {success: true, stdout: ""}}
      })

      output = capture_stdout { command.call(tagname: "v1.0.0", verify: true) }
      expect(output).to include("[main] No tags found")
    end

    it "identifies tag listing operation" do
      allow(mock_orchestrator).to receive(:tag).and_return({
        success: true,
        results: {"main" => {success: true, stdout: ""}}
      })

      output = capture_stdout { command.call(list: true) }
      expect(output).to include("[main] No tags found")
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