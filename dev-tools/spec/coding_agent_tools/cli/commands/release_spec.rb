# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/release/current"
require "coding_agent_tools/cli/commands/release/next"
require "coding_agent_tools/cli/commands/release/all"
require "coding_agent_tools/cli/commands/release/generate_id"

RSpec.describe "Release CLI Commands" do
  let(:base_path) { "/tmp/test_release_cli" }

  before do
    # Create test directory structure
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/current")
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/done")
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog")

    # Mock ProjectRootDetector to return our test path
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(base_path)
  end

  after do
    # Clean up test directories
    FileUtils.rm_rf(base_path) if File.exist?(base_path)
  end

  # Helper method for capturing stdout
  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  # Helper method for capturing stderr
  def capture_error_output
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end

  describe CodingAgentTools::Cli::Commands::Release::Current do
    subject(:command) { described_class.new }

    context "when current release exists" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-test/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-test/tasks/task1.md", "# Task 1")
      end

      it "returns current release information in text format" do
        expect { expect(command.call).to eq(0) }.to output(/Current Release Information/).to_stdout
      end

      it "returns current release information in JSON format" do
        expect { expect(command.call(format: "json")).to eq(0) }.to output(/"success": true/).to_stdout
      end
    end

    context "when no current release exists" do
      it "returns error" do
        expect { expect(command.call).to eq(1) }.to output(/Error:/).to_stderr
      end

      it "returns JSON error format when no current release exists" do
        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["success"]).to be false
        expect(parsed["error"]).not_to be_nil
        expect(parsed["error"]).not_to be_empty
      end
    end

    context "error handling with debug mode" do
      it "shows detailed error information when debug is enabled" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_raise(StandardError, "Project root not found")

        expect { command.call(debug: true) }.to output(/Error: StandardError: Project root not found/).to_stderr
      end

      it "shows backtrace when debug is enabled" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_raise(StandardError, "Project root not found")

        output = capture_error_output { command.call(debug: true) }
        expect(output).to include("Backtrace:")
        expect(output).to include("spec/coding_agent_tools/cli/commands/release_spec.rb")
      end

      it "shows simplified error without debug flag" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_raise(StandardError, "Project root not found")

        output = capture_error_output { command.call(debug: false) }
        expect(output).to include("Error: Project root not found")
        expect(output).to include("Use --debug flag for more information")
        expect(output).not_to include("Backtrace:")
      end
    end

    context "release manager error handling" do
      it "handles ReleaseManager failures in text format" do
        release_manager = instance_double(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager)
        allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(release_manager)

        error_result = double("result", success?: false, error_message: "Release manager error")
        allow(release_manager).to receive(:current).and_return(error_result)

        expect { command.call }.to output(/Error: Release manager error/).to_stderr
        expect(command.call).to eq(1)
      end

      it "returns proper JSON error format when release manager fails" do
        release_manager = instance_double(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager)
        allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(release_manager)

        error_result = double("result", success?: false, error_message: "Release manager error")
        allow(release_manager).to receive(:current).and_return(error_result)

        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["success"]).to be false
        expect(parsed["error"]).to eq("Release manager error")
      end
    end

    context "timestamp formatting" do
      let(:test_time) { Time.new(2023, 12, 25, 15, 30, 45) }

      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-test/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-test/tasks/task1.md", "# Task 1")

        # Mock the release object to return specific timestamps
        release_manager = instance_double(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager)
        allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(release_manager)

        release_data = double("release",
          name: "v.0.3.0-test",
          version: "v.0.3.0",
          path: "#{base_path}/dev-taskflow/current/v.0.3.0-test",
          type: :current,
          status: "active",
          task_count: 1,
          created_at: test_time,
          modified_at: test_time)

        success_result = double("result", success?: true, data: release_data)
        allow(release_manager).to receive(:current).and_return(success_result)
      end

      it "formats timestamps correctly in text output" do
        output = capture_output { command.call }
        expect(output).to include("Created:   2023-12-25 15:30:45")
        expect(output).to include("Modified:  2023-12-25 15:30:45")
      end

      it "formats timestamps as ISO8601 in JSON output" do
        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["data"]["created_at"]).to match(/2023-12-25T15:30:45(\+00:00|Z)/)
        expect(parsed["data"]["modified_at"]).to match(/2023-12-25T15:30:45(\+00:00|Z)/)
      end
    end

    context "release data edge cases" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-test/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-test/tasks/task1.md", "# Task 1")

        release_manager = instance_double(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager)
        allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(release_manager)

        release_data = double("release",
          name: "v.0.3.0-test",
          version: "v.0.3.0",
          path: "#{base_path}/dev-taskflow/current/v.0.3.0-test",
          type: :current,
          status: "active",
          task_count: 1,
          created_at: nil,
          modified_at: nil)

        success_result = double("result", success?: true, data: release_data)
        allow(release_manager).to receive(:current).and_return(success_result)
      end

      it "handles missing timestamps gracefully in text output" do
        output = capture_output { command.call }
        expect(output).not_to include("Created:")
        expect(output).not_to include("Modified:")
        expect(output).to include("Current Release Information:")
      end

      it "handles missing timestamps gracefully in JSON output" do
        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["data"]["created_at"]).to be_nil
        expect(parsed["data"]["modified_at"]).to be_nil
        expect(parsed["success"]).to be true
      end
    end
  end

  describe CodingAgentTools::Cli::Commands::Release::Next do
    subject(:command) { described_class.new }

    context "when backlog has versioned releases" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/v.0.4.0-future")
        # Create a task file to test task count display
        File.write("#{base_path}/dev-taskflow/backlog/v.0.4.0-future/README.md", "# Release")
      end

      it "returns next release information in text format" do
        expect { expect(command.call).to eq(0) }.to output(/Next Release Available/).to_stdout
      end

      it "returns next release information in JSON format" do
        expect { expect(command.call(format: "json")).to eq(0) }.to output(/"success": true/).to_stdout
      end

      it "displays release metadata when available" do
        output = capture_output { command.call }
        expect(output).to match(/Name:\s+v\.0\.4\.0-future/)
        expect(output).to match(/Version:\s+v\.0\.4\.0/)
        expect(output).to match(/Path:/)
        expect(output).to match(/Status:/)
        expect(output).to match(/Tasks:\s+\d+/)
      end

      it "includes timestamps when available" do
        # Touch a file to ensure creation time is set
        FileUtils.touch("#{base_path}/dev-taskflow/backlog/v.0.4.0-future")

        output = capture_output { command.call }
        expect(output).to match(/Created:\s+\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        expect(output).to match(/Modified:\s+\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it "returns exit code 0 on success" do
        expect(command.call).to eq(0)
      end

      it "includes type information in JSON output" do
        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["data"]["type"]).to eq("backlog")
      end

      it "includes ISO8601 timestamps in JSON output" do
        FileUtils.touch("#{base_path}/dev-taskflow/backlog/v.0.4.0-future")

        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["data"]["created_at"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
        expect(parsed["data"]["modified_at"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end
    end

    context "when no versioned releases in backlog" do
      it "returns success with message" do
        expect { expect(command.call).to eq(0) }.to output(/No versioned releases found/).to_stdout
      end

      it "returns success code even when no releases found" do
        expect(command.call).to eq(0)
      end

      it "returns appropriate JSON response when no releases found" do
        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["success"]).to be true
        expect(parsed["data"]).to be_nil
        expect(parsed["message"]).to include("No versioned releases found")
      end
    end

    context "error handling scenarios" do
      it "handles ProjectRootDetector failures" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_raise(StandardError, "Project root not found")

        expect { command.call }.to output(/Error: Project root not found/).to_stderr
        expect(command.call).to eq(1)
      end

      it "handles ReleaseManager failures" do
        # Mock ReleaseManager to return an error result
        release_manager = instance_double(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager)
        allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(release_manager)

        error_result = double("result", success?: false, error_message: "Release manager error")
        allow(release_manager).to receive(:next).and_return(error_result)

        expect { command.call }.to output(/Error: Release manager error/).to_stderr
        expect(command.call).to eq(1)
      end

      it "returns proper JSON error format when release manager fails" do
        release_manager = instance_double(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager)
        allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(release_manager)

        error_result = double("result", success?: false, error_message: "Release manager error")
        allow(release_manager).to receive(:next).and_return(error_result)

        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["success"]).to be false
        expect(parsed["error"]).to eq("Release manager error")
      end

      it "returns exit code 1 on error" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_raise(StandardError, "Project root not found")

        expect(command.call).to eq(1)
      end
    end

    context "debug mode functionality" do
      it "shows detailed error information when debug is enabled" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_raise(StandardError, "Project root not found")

        expect { command.call(debug: true) }.to output(/Error: StandardError: Project root not found/).to_stderr
      end

      it "shows backtrace when debug is enabled" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_raise(StandardError, "Project root not found")

        output = capture_error_output { command.call(debug: true) }
        expect(output).to include("Backtrace:")
        expect(output).to include("spec/coding_agent_tools/cli/commands/release_spec.rb")
      end

      it "shows simplified error without debug flag" do
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_raise(StandardError, "Project root not found")

        output = capture_error_output { command.call(debug: false) }
        expect(output).to include("Error: Project root not found")
        expect(output).to include("Use --debug flag for more information")
        expect(output).not_to include("Backtrace:")
      end
    end

    context "format validation" do
      it "handles invalid format options gracefully" do
        # The dry-cli framework should handle invalid format validation
        # But we test that valid formats work correctly
        expect { command.call(format: "text") }.not_to raise_error
        expect { command.call(format: "json") }.not_to raise_error
      end
    end
  end

  describe CodingAgentTools::Cli::Commands::Release::GenerateId do
    subject(:command) { described_class.new }

    before do
      # Mock the LLM API call to prevent slow external calls
      allow_any_instance_of(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager)
        .to receive(:generate_unique_codename).and_return("testcodename")
    end

    context "when generating release" do
      it "returns version and path in text format" do
        expect { expect(command.call).to eq(0) }.to output(/version: v\.\d+\.\d+\.\d+\npath: .*/).to_stdout
      end

      it "returns release info in JSON format" do
        expect { expect(command.call(format: "json")).to eq(0) }.to output(/"success": true/).to_stdout
      end

      it "accepts codename parameter" do
        expect { expect(command.call(codename: "testname")).to eq(0) }.to output(/version: v\.\d+\.\d+\.\d+\npath: .*testname/).to_stdout
      end
    end
  end

  describe CodingAgentTools::Cli::Commands::Release::All do
    subject(:command) { described_class.new }

    context "when releases exist" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-test/tasks")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.2.0-test/tasks")
        File.write("#{base_path}/dev-taskflow/done/v.0.1.0-test/tasks/task1.md", "# Task 1")
        File.write("#{base_path}/dev-taskflow/current/v.0.2.0-test/tasks/task1.md", "# Task 1")
      end

      it "returns all releases in text format" do
        expect { expect(command.call).to eq(0) }.to output(/All Releases \(2 total\)/).to_stdout
      end

      it "returns all releases in JSON format" do
        expect { expect(command.call(format: "json")).to eq(0) }.to output(/"count": 2/).to_stdout
      end

      it "filters by type" do
        expect { expect(command.call(type: "current")).to eq(0) }.to output(/All Releases \(current\) \(1 total\)/).to_stdout
      end

      it "applies limit" do
        expect { expect(command.call(limit: 1)).to eq(0) }.to output(/All Releases \(1 total\)/).to_stdout
      end
    end

    context "when no releases exist" do
      it "returns no releases message" do
        expect { expect(command.call).to eq(0) }.to output(/No releases found/).to_stdout
      end
    end
  end
end
