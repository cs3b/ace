# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/search/ripgrep_executor"

RSpec.describe CodingAgentTools::Atoms::Search::RipgrepExecutor do
  let(:executor) { described_class.new }
  let(:mock_shell_executor) { instance_double("ShellCommandExecutor") }

  before do
    allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor)
      .to receive(:new).and_return(mock_shell_executor)
  end

  describe "#available?" do
    it "returns true when ripgrep is installed" do
      allow(mock_shell_executor).to receive(:execute)
        .with("which rg")
        .and_return({ success: true })
      
      expect(executor.available?).to be true
    end

    it "returns false when ripgrep is not installed" do
      allow(mock_shell_executor).to receive(:execute)
        .with("which rg")
        .and_return({ success: false })
      
      expect(executor.available?).to be false
    end
  end

  describe "#search" do
    context "when ripgrep is available" do
      before do
        allow(executor).to receive(:available?).and_return(true)
      end

      it "executes basic search" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^rg.*"test_pattern"/, anything)
          .and_return({
            success: true,
            output: "file.rb:1:test_pattern found\n",
            exit_code: 0
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
          .with(/^rg.*-i.*"pattern"/, anything)
          .and_return({
            success: true,
            output: "",
            exit_code: 0
          })
        
        executor.search("pattern", case_insensitive: true)
      end

      it "handles file type filtering" do
        allow(mock_shell_executor).to receive(:execute)
          .with(/^rg.*--type ruby.*"pattern"/, anything)
          .and_return({
            success: true,
            output: "",
            exit_code: 0
          })
        
        executor.search("pattern", file_type: "ruby")
      end
    end

    context "when ripgrep is not available" do
      before do
        allow(executor).to receive(:available?).and_return(false)
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
      command = executor.send(:build_ripgrep_command, "pattern", case_insensitive: true)
      
      expect(command).to include("-i")
    end

    it "adds context lines" do
      command = executor.send(:build_ripgrep_command, "pattern", 
                              after_context: 2, before_context: 1)
      
      expect(command).to include("-A 2")
      expect(command).to include("-B 1")
    end
  end
end