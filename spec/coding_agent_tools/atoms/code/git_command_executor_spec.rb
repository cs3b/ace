# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::Code::GitCommandExecutor do
  let(:executor) { described_class.new }

  describe "#execute" do
    context "with successful git command" do
      it "executes git status successfully" do
        result_double = double(
          stdout: "On branch main\nnothing to commit, working tree clean\n",
          success?: true,
          stderr: ""
        )
        
        allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("git status --porcelain").and_return(result_double)
        
        result = executor.execute("status", ["--porcelain"])
        
        expect(result[:success]).to be true
        expect(result[:output]).to include("nothing to commit")
        expect(result[:error]).to eq("")
      end

      it "executes git log successfully" do
        result_double = double(
          stdout: "abc123 Add new feature\ndef456 Fix bug in parser\n",
          success?: true,
          stderr: ""
        )
        
        allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("git log --oneline -10").and_return(result_double)
        
        result = executor.execute("log", ["--oneline", "-10"])
        
        expect(result[:success]).to be true
        expect(result[:output]).to include("Add new feature")
        expect(result[:error]).to eq("")
      end
    end

    context "with failed git command" do
      it "handles command execution failure" do
        result_double = double(
          stdout: "",
          success?: false,
          stderr: "git: 'invalid-command' is not a git command."
        )
        
        allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("git invalid-command").and_return(result_double)
        
        result = executor.execute("invalid-command")
        
        expect(result[:success]).to be false
        expect(result[:error]).to include("not a git command")
      end

      it "handles git repository errors" do
        result_double = double(
          stdout: "",
          success?: false,
          stderr: "fatal: not a git repository"
        )
        
        allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("git status").and_return(result_double)
        
        result = executor.execute("status")
        
        expect(result[:success]).to be false
        expect(result[:error]).to include("not a git repository")
      end
    end
  end

  describe "#diff" do
    it "executes git diff for staged changes" do
      result_double = double(
        stdout: "diff --git a/file.rb b/file.rb\n",
        success?: true,
        stderr: ""
      )
      
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("git diff --staged --no-color").and_return(result_double)
      
      result = executor.diff("staged")
      
      expect(result[:success]).to be true
      expect(result[:output]).to include("diff --git")
    end

    it "executes git diff for unstaged changes" do
      result_double = double(
        stdout: "diff --git a/file.rb b/file.rb\n",
        success?: true,
        stderr: ""
      )
      
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("git diff --no-color").and_return(result_double)
      
      result = executor.diff("unstaged")
      
      expect(result[:success]).to be true
      expect(result[:output]).to include("diff --git")
    end
  end

  describe "#available?" do
    it "returns true when git is available" do
      result_double = double(
        success?: true,
        stdout: "/usr/bin/git\n"
      )
      
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("which git").and_return(result_double)
      
      expect(executor.available?).to be true
    end

    it "returns false when git is not available" do
      result_double = double(
        success?: false,
        stdout: ""
      )
      
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("which git").and_return(result_double)
      
      expect(executor.available?).to be false
    end
  end

  describe "#version" do
    it "returns git version when available" do
      result_double = double(
        stdout: "git version 2.39.0\n",
        success?: true,
        stderr: ""
      )
      
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("git --version").and_return(result_double)
      
      expect(executor.version).to eq("git version 2.39.0")
    end

    it "returns nil when git version fails" do
      result_double = double(
        stdout: "",
        success?: false,
        stderr: "command not found"
      )
      
      allow(CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor).to receive(:execute).with("git --version").and_return(result_double)
      
      expect(executor.version).to be_nil
    end
  end
end