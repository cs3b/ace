# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/search/ripgrep_executor"
require "coding_agent_tools/atoms/taskflow_management/shell_command_executor"

RSpec.describe CodingAgentTools::Atoms::Search::RipgrepExecutor do
  let(:executor) { described_class.new }
  let(:mock_shell_executor) { CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor }

  describe "#available?" do
    it "returns true when ripgrep is installed" do
      allow(mock_shell_executor).to receive(:execute)
        .with("which rg", timeout: 5)
        .and_return({success: true})

      expect(executor.available?).to be true
    end

    it "returns false when ripgrep is not installed" do
      allow(mock_shell_executor).to receive(:execute)
        .with("which rg", timeout: 5)
        .and_return({success: false})

      expect(executor.available?).to be false
    end
  end

  describe "#search" do
    context "when ripgrep is available" do
      before do
        allow(mock_shell_executor).to receive(:execute)
          .with("which rg", timeout: 5)
          .and_return({success: true})
      end

      it "executes basic search" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^rg.*test_pattern/, timeout: 120)
          .and_return({
            success: true,
            stdout: "file.rb:1:test_pattern found\n",
            stderr: "",
            exit_code: 0,
            duration: 0.1
          })

        result = executor.search("test_pattern")

        expect(result[:success]).to be true
        expect(result[:results]).to include(
          hash_including(
            file: "file.rb",
            line: 1,
            text: "test_pattern found"
          )
        )
      end

      it "handles case-insensitive search" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^rg.*--ignore-case.*pattern/, timeout: 120)
          .and_return({
            success: true,
            stdout: "",
            stderr: "",
            exit_code: 0,
            duration: 0.1
          })

        result = executor.search("pattern", ignore_case: true)
        expect(result[:success]).to be true
      end

      it "handles file type filtering" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^rg.*--type=ruby.*pattern/, timeout: 120)
          .and_return({
            success: true,
            stdout: "",
            stderr: "",
            exit_code: 0,
            duration: 0.1
          })

        result = executor.search("pattern", file_type: "ruby")
        expect(result[:success]).to be true
      end
    end

    context "when ripgrep is not available" do
      before do
        allow(mock_shell_executor).to receive(:execute)
          .with("which rg", timeout: 5)
          .and_return({success: false})
      end

      it "returns error response" do
        result = executor.search("pattern")

        expect(result[:success]).to be false
        expect(result[:error]).to include("ripgrep not available")
      end
    end
  end

  describe "#build_command" do
    it "builds basic command" do
      command = executor.send(:build_ripgrep_command, "pattern", {})

      expect(command).to include("rg")
      expect(command).to include("pattern")
    end

    it "adds case-insensitive flag" do
      command = executor.send(:build_ripgrep_command, "pattern", ignore_case: true)

      expect(command).to include("--ignore-case")
    end

    it "adds context lines" do
      command = executor.send(:build_ripgrep_command, "pattern",
        after_context: 2, before_context: 1)

      expect(command).to include("--after-context=2")
      expect(command).to include("--before-context=1")
    end
  end
end
