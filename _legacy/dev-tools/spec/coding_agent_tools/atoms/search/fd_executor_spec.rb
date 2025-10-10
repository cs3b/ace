# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/search/fd_executor"

RSpec.describe CodingAgentTools::Atoms::Search::FdExecutor do
  let(:executor) { described_class.new }
  let(:mock_shell_executor) { instance_double("ShellCommandExecutor") }

  before do
    allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
      .to receive(:new).and_return(mock_shell_executor)
  end

  describe "#available?" do
    it "returns true when fd is installed" do
      allow(mock_shell_executor).to receive(:execute)
        .with("which fd")
        .and_return({success: true})

      expect(executor.available?).to be true
    end

    it "returns false when fd is not installed" do
      allow(mock_shell_executor).to receive(:execute)
        .with("which fd")
        .and_return({success: false})

      expect(executor.available?).to be false
    end
  end

  describe "#find_files" do
    context "when fd is available" do
      before do
        allow(executor).to receive(:available?).and_return(true)
      end

      it "finds files matching pattern" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^fd.*"\.rb"/, anything)
          .and_return({
            success: true,
            output: "lib/file1.rb\nlib/file2.rb\n",
            exit_code: 0
          })

        result = executor.find_files("*.rb")

        expect(result[:success]).to be true
        expect(result[:files]).to contain_exactly("lib/file1.rb", "lib/file2.rb")
      end

      it "handles case-insensitive search" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^fd.*--ignore-case.*"pattern"/, anything)
          .and_return({
            success: true,
            output: "",
            exit_code: 0
          })

        executor.find_files("pattern", case_insensitive: true)
      end

      it "handles hidden files" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^fd.*--hidden.*"pattern"/, anything)
          .and_return({
            success: true,
            output: "",
            exit_code: 0
          })

        executor.find_files("pattern", hidden: true)
      end

      it "handles max depth" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^fd.*--max-depth 3.*"pattern"/, anything)
          .and_return({
            success: true,
            output: "",
            exit_code: 0
          })

        executor.find_files("pattern", max_depth: 3)
      end
    end

    context "when fd is not available" do
      before do
        allow(executor).to receive(:available?).and_return(false)
      end

      it "returns error response" do
        result = executor.find_files("pattern")

        expect(result[:success]).to be false
        expect(result[:error]).to include("fd not available")
      end
    end
  end

  describe "#build_fd_command" do
    it "builds basic command" do
      command = executor.send(:build_fd_command, "*.rb", {})

      expect(command).to include("fd")
      expect(command).to include("*.rb")
    end

    it "adds file type flag" do
      command = executor.send(:build_fd_command, "pattern", type: "file")

      expect(command).to include("--type file")
    end

    it "adds extension filter" do
      command = executor.send(:build_fd_command, "pattern", extension: "rb")

      expect(command).to include("--extension rb")
    end
  end
end
