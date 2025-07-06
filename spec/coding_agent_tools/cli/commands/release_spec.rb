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
    end
  end

  describe CodingAgentTools::Cli::Commands::Release::Next do
    subject(:command) { described_class.new }

    context "when backlog has versioned releases" do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/v.0.4.0-future")
      end

      it "returns next release information in text format" do
        expect { expect(command.call).to eq(0) }.to output(/Next Release Available/).to_stdout
      end

      it "returns next release information in JSON format" do
        expect { expect(command.call(format: "json")).to eq(0) }.to output(/"success": true/).to_stdout
      end
    end

    context "when no versioned releases in backlog" do
      it "returns success with message" do
        expect { expect(command.call).to eq(0) }.to output(/No versioned releases found/).to_stdout
      end
    end
  end

  describe CodingAgentTools::Cli::Commands::Release::GenerateId do
    subject(:command) { described_class.new }

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
