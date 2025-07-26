# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::Git::GitCommandExecutor do
  let(:executor) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    # Setup common mocks for unit testing
    allow(Open3).to receive(:capture3).and_return(["stdout", "stderr", double(success?: true, exitstatus: 0)])
    allow(Kernel).to receive(:system).and_return(true)
    allow(Timeout).to receive(:timeout).and_yield
    allow($?).to receive(:exitstatus).and_return(0)
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe ".execute" do
    it "creates new instance and executes command with default options" do
      expect(described_class).to receive(:new).with(repository_path: nil).and_call_original
      result = described_class.execute("status")
      expect(result).to be_a(Hash)
      expect(result[:success]).to be true
    end

    it "passes repository_path to new instance" do
      expect(described_class).to receive(:new).with(repository_path: temp_dir).and_call_original
      described_class.execute("status", repository_path: temp_dir)
    end

    it "passes capture_output option to execute method" do
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      expect(instance).to receive(:execute).with("status", capture_output: false)
      described_class.execute("status", capture_output: false)
    end
  end

  describe "#initialize" do
    it "stores repository_path when provided" do
      executor = described_class.new(repository_path: temp_dir)
      expect(executor.send(:repository_path)).to eq(temp_dir)
    end

    it "stores nil repository_path when not provided" do
      executor = described_class.new
      expect(executor.send(:repository_path)).to be_nil
    end
  end

  describe "#execute" do
    context "with capture_output: true (default)" do
      it "calls execute_with_capture" do
        expect(executor).to receive(:execute_with_capture).with("git status")
        executor.execute("status")
      end

      it "builds command and captures output" do
        result = executor.execute("status")
        expect(result).to have_key(:success)
        expect(result).to have_key(:stdout)
        expect(result).to have_key(:stderr)
        expect(result).to have_key(:exit_status)
      end
    end

    context "with capture_output: false" do
      it "calls execute_without_capture" do
        expect(executor).to receive(:execute_without_capture).with("git status")
        executor.execute("status", capture_output: false)
      end

      it "builds command and executes without capturing output" do
        result = executor.execute("status", capture_output: false)
        expect(result).to have_key(:success)
        expect(result).to have_key(:exit_status)
        expect(result).not_to have_key(:stdout)
        expect(result).not_to have_key(:stderr)
      end
    end
  end

  describe "private methods" do
    describe "#build_command" do
      context "without repository path" do
        it "builds simple git command" do
          result = executor.send(:build_command, "status")
          expect(result).to eq("git status")
        end

        it "preserves command arguments" do
          result = executor.send(:build_command, "log --oneline")
          expect(result).to eq("git log --oneline")
        end
      end

      context "with repository path" do
        let(:executor_with_path) { described_class.new(repository_path: temp_dir) }

        it "builds command with -C option for absolute path" do
          allow(File).to receive(:absolute_path?).with(temp_dir).and_return(true)
          result = executor_with_path.send(:build_command, "status")
          expect(result).to eq("git -C #{Shellwords.escape(temp_dir)} status")
        end

        it "resolves relative path and builds command" do
          allow(File).to receive(:absolute_path?).with(temp_dir).and_return(false)
          allow(executor_with_path).to receive(:resolve_repository_path).with(temp_dir).and_return(temp_dir)
          result = executor_with_path.send(:build_command, "status")
          expect(result).to eq("git -C #{Shellwords.escape(temp_dir)} status")
        end

        it "handles current directory path" do
          current_executor = described_class.new(repository_path: ".")
          result = current_executor.send(:build_command, "status")
          expect(result).to eq("git status")
        end
      end
    end

    describe "#resolve_repository_path" do
      context "with absolute paths" do
        it "returns absolute path as-is" do
          allow(File).to receive(:absolute_path?).with(temp_dir).and_return(true)
          result = executor.send(:resolve_repository_path, temp_dir)
          expect(result).to eq(temp_dir)
        end

        it "raises error for non-existent absolute path" do
          bad_path = "/non/existent/path"
          allow(File).to receive(:absolute_path?).with(bad_path).and_return(true)
          allow(File).to receive(:exist?).with(bad_path).and_return(false)
          
          expect { executor.send(:resolve_repository_path, bad_path) }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError,
            /Repository path not found/
          )
        end
      end

      context "with relative paths" do
        it "returns existing local relative path" do
          relative_path = "some/path"
          allow(File).to receive(:absolute_path?).with(relative_path).and_return(false)
          allow(File).to receive(:exist?).with(relative_path).and_return(true)
          allow(File).to receive(:directory?).with(relative_path).and_return(true)
          
          result = executor.send(:resolve_repository_path, relative_path)
          expect(result).to eq(relative_path)
        end

        it "resolves to project root when local path doesn't exist" do
          relative_path = "some/path"
          project_root = "/project/root"
          resolved_path = File.join(project_root, relative_path)
          
          allow(File).to receive(:absolute_path?).with(relative_path).and_return(false)
          allow(File).to receive(:exist?).with(relative_path).and_return(false)
          allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
          allow(File).to receive(:exist?).with(resolved_path).and_return(true)
          allow(File).to receive(:directory?).with(resolved_path).and_return(true)
          
          result = executor.send(:resolve_repository_path, relative_path)
          expect(result).to eq(resolved_path)
        end

        it "raises error when path not found anywhere" do
          relative_path = "missing/path"
          project_root = "/project/root"
          resolved_path = File.join(project_root, relative_path)
          
          allow(File).to receive(:absolute_path?).with(relative_path).and_return(false)
          allow(File).to receive(:exist?).with(relative_path).and_return(false)
          allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
          allow(File).to receive(:exist?).with(resolved_path).and_return(false)
          
          expect { executor.send(:resolve_repository_path, relative_path) }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError,
            /Repository path not found/
          )
        end
      end
    end

    describe "#execute_with_capture" do
      it "executes command and returns result hash" do
        stdout = "git output"
        stderr = "git errors"
        status = double(success?: true, exitstatus: 0)
        
        allow(Open3).to receive(:capture3).with("git status").and_return([stdout, stderr, status])
        
        result = executor.send(:execute_with_capture, "git status")
        expect(result).to eq({
          success: true,
          stdout: stdout,
          stderr: stderr,
          exit_status: 0
        })
      end

      it "handles timeout scenarios" do
        allow(Timeout).to receive(:timeout).with(30).and_raise(Timeout::Error)
        
        expect { executor.send(:execute_with_capture, "git status") }.to raise_error(
          CodingAgentTools::Atoms::Git::GitCommandError,
          /Git command timed out/
        ) do |error|
          expect(error.exit_status).to eq(124)
          expect(error.stderr_output).to eq("Command timed out")
          expect(error.command).to eq("git status")
        end
      end

      it "handles failed commands" do
        status = double(success?: false, exitstatus: 1)
        allow(Open3).to receive(:capture3).and_return(["", "error message", status])
        
        expect { executor.send(:execute_with_capture, "git status") }.to raise_error(
          CodingAgentTools::Atoms::Git::GitCommandError,
          /Git command failed/
        ) do |error|
          expect(error.exit_status).to eq(1)
          expect(error.stderr_output).to eq("error message")
          expect(error.command).to eq("git status")
        end
      end
    end

    describe "#execute_without_capture" do
      it "executes command and returns success result" do
        allow(Kernel).to receive(:system).with("git status").and_return(true)
        
        result = executor.send(:execute_without_capture, "git status")
        expect(result).to eq({
          success: true,
          exit_status: 0
        })
      end

      it "handles failed system calls" do
        allow(Kernel).to receive(:system).with("git status").and_return(false)
        allow($?).to receive(:exitstatus).and_return(1)
        
        expect { executor.send(:execute_without_capture, "git status") }.to raise_error(
          CodingAgentTools::Atoms::Git::GitCommandError,
          /Git command failed/
        ) do |error|
          expect(error.exit_status).to eq(1)
          expect(error.command).to eq("git status")
        end
      end
    end

    describe "#format_command_for_display" do
      it "unescapes shell-escaped characters" do
        escaped_command = "git -C /path/with\\ spaces status"
        result = executor.send(:format_command_for_display, escaped_command)
        expect(result).to eq("git -C /path/with spaces status")
      end

      it "normalizes whitespace" do
        command = "git    status   --porcelain"
        result = executor.send(:format_command_for_display, command)
        expect(result).to eq("git status --porcelain")
      end

      it "strips leading and trailing whitespace" do
        command = "  git status  "
        result = executor.send(:format_command_for_display, command)
        expect(result).to eq("git status")
      end

      it "handles complex escaped sequences" do
        command = "git\\ -C\\ /path/with\\~special\\$chars\\ status"
        result = executor.send(:format_command_for_display, command)
        expect(result).to eq("git -C /path/with~special$chars status")
      end

      it "handles multiple types of escapes" do
        command = "git commit -m fix\\:\\ update\\ \\(version\\)\\ and\\ \\\"quotes\\\""
        result = executor.send(:format_command_for_display, command)
        expect(result).to eq('git commit -m fix: update (version) and "quotes"')
      end
    end
  end

  describe "GitCommandError" do
    it "initializes with message and optional attributes" do
      error = CodingAgentTools::Atoms::Git::GitCommandError.new(
        "Test error",
        command: "git test",
        exit_status: 1,
        stderr_output: "error output"
      )

      expect(error.message).to eq("Test error")
      expect(error.command).to eq("git test")
      expect(error.exit_status).to eq(1)
      expect(error.stderr_output).to eq("error output")
    end

    it "works with minimal initialization" do
      error = CodingAgentTools::Atoms::Git::GitCommandError.new("Simple error")
      expect(error.message).to eq("Simple error")
      expect(error.command).to be_nil
      expect(error.exit_status).to be_nil
      expect(error.stderr_output).to be_nil
    end
  end

  describe "edge cases and error scenarios" do
    context "with special characters in paths" do
      it "escapes repository paths with spaces" do
        spaced_path = "/path with spaces"
        executor_with_spaces = described_class.new(repository_path: spaced_path)
        
        allow(File).to receive(:absolute_path?).with(spaced_path).and_return(true)
        command = executor_with_spaces.send(:build_command, "status")
        
        expect(command).to include(Shellwords.escape(spaced_path))
      end

      it "handles paths with special shell characters" do
        special_path = "/path$with&special*chars"
        executor_with_special = described_class.new(repository_path: special_path)
        
        allow(File).to receive(:absolute_path?).with(special_path).and_return(true)
        command = executor_with_special.send(:build_command, "status")
        
        expect(command).to include(Shellwords.escape(special_path))
      end
    end

    context "with various command formats" do
      it "handles commands with multiple arguments" do
        result = executor.send(:build_command, "log --oneline --graph --decorate")
        expect(result).to eq("git log --oneline --graph --decorate")
      end

      it "handles commands with quoted arguments" do
        result = executor.send(:build_command, 'commit -m "test message"')
        expect(result).to eq('git commit -m "test message"')
      end
    end

    context "with error message formatting" do
      it "formats display command correctly in error messages" do
        escaped_command = "git -C /escaped\\ path status"
        
        allow(Open3).to receive(:capture3).with(escaped_command).and_return([
          "", "error", double(success?: false, exitstatus: 1)
        ])
        
        expect { executor.send(:execute_with_capture, escaped_command) }.to raise_error(
          CodingAgentTools::Atoms::Git::GitCommandError
        ) do |error|
          expect(error.message).to include("git -C /escaped path status")
          expect(error.message).not_to include("escaped\\")
        end
      end
    end
  end

  describe "comprehensive integration scenarios" do
    it "handles full workflow with repository path" do
      repo_path = "/some/repo"
      executor_with_repo = described_class.new(repository_path: repo_path)
      
      allow(File).to receive(:absolute_path?).with(repo_path).and_return(true)
      allow(Open3).to receive(:capture3).with("git -C #{Shellwords.escape(repo_path)} status").and_return([
        "clean output", "", double(success?: true, exitstatus: 0)
      ])
      
      result = executor_with_repo.execute("status")
      expect(result[:success]).to be true
      expect(result[:stdout]).to eq("clean output")
    end

    it "handles relative path resolution workflow" do
      relative_path = "sub/repo"
      project_root = "/project"
      resolved_path = "/project/sub/repo"
      
      executor_with_relative = described_class.new(repository_path: relative_path)
      
      allow(File).to receive(:absolute_path?).with(relative_path).and_return(false)
      allow(File).to receive(:exist?).with(relative_path).and_return(false)
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
      allow(File).to receive(:exist?).with(resolved_path).and_return(true)
      allow(File).to receive(:directory?).with(resolved_path).and_return(true)
      allow(Open3).to receive(:capture3).with("git -C #{Shellwords.escape(resolved_path)} status").and_return([
        "resolved output", "", double(success?: true, exitstatus: 0)
      ])
      
      result = executor_with_relative.execute("status")
      expect(result[:success]).to be true
      expect(result[:stdout]).to eq("resolved output")
    end
  end
end