# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::Code::GitCommandExecutor do
  let(:executor) { described_class.new }

  describe "#execute" do
    context "with successful git command" do
      it "executes git status successfully" do
        mock_system_command("git status --porcelain", GitMockData.status_clean)
        
        result = executor.execute("status --porcelain")
        
        expect(result[:success]).to be true
        expect(result[:output]).to include("nothing to commit")
        expect(result[:exit_code]).to eq(0)
      end

      it "executes git log successfully" do
        mock_system_command("git log --oneline -10", GitMockData.log_recent)
        
        result = executor.execute("log --oneline -10")
        
        expect(result[:success]).to be true
        expect(result[:output]).to include("Add new feature")
        expect(result[:exit_code]).to eq(0)
      end
    end

    context "with failed git command" do
      it "handles command execution failure" do
        mock_system_command("git invalid-command", {
          success: false,
          output: "git: 'invalid-command' is not a git command.",
          exit_code: 1
        })
        
        result = executor.execute("invalid-command")
        
        expect(result[:success]).to be false
        expect(result[:output]).to include("not a git command")
        expect(result[:exit_code]).to eq(1)
      end

      it "handles git repository errors" do
        mock_system_command("git status", {
          success: false,
          output: "fatal: not a git repository",
          exit_code: 128
        })
        
        result = executor.execute("status")
        
        expect(result[:success]).to be false
        expect(result[:output]).to include("not a git repository")
        expect(result[:exit_code]).to eq(128)
      end
    end

    context "with command parameter validation" do
      it "validates non-empty command" do
        expect { executor.execute("") }.to raise_error(ArgumentError, "Command cannot be empty")
      end

      it "validates non-nil command" do
        expect { executor.execute(nil) }.to raise_error(ArgumentError, "Command cannot be nil")
      end
    end

    context "with timeout handling" do
      it "handles command timeout" do
        # Mock Open3.capture3 to simulate timeout
        allow(Open3).to receive(:capture3).and_raise(Timeout::Error)
        
        result = executor.execute("log --all")
        
        expect(result[:success]).to be false
        expect(result[:error]).to include("timeout")
      end
    end
  end

  describe "#build_command" do
    it "builds proper git command with arguments" do
      command = executor.send(:build_command, "status --porcelain")
      expect(command).to eq("git status --porcelain")
    end

    it "handles commands with complex arguments" do
      command = executor.send(:build_command, "log --pretty=format:'%h %s' --since='2 weeks ago'")
      expect(command).to eq("git log --pretty=format:'%h %s' --since='2 weeks ago'")
    end
  end
end