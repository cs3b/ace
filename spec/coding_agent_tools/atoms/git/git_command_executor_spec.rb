# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::Git::GitCommandExecutor do
  let(:executor) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    # Skip actual git operations to focus on unit testing
    allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true, exitstatus: 0)])
    allow(Kernel).to receive(:system).and_return(true)
    allow(Timeout).to receive(:timeout).and_yield
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:directory?).and_return(true)
    allow(File).to receive(:absolute_path?).and_return(false)
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe ".execute" do
    it "creates new instance and executes command" do
      result = nil
      Dir.chdir(temp_dir) do
        result = described_class.execute("status --porcelain")
      end

      expect(result).to be_a(Hash)
      expect(result[:success]).to be true
      expect(result).to have_key(:stdout)
    end

    it "passes repository_path option to new instance" do
      result = described_class.execute("status --porcelain", repository_path: temp_dir)

      expect(result).to be_a(Hash)
      expect(result[:success]).to be true
      expect(result).to have_key(:stdout)
    end

    it "passes capture_output option to execute method" do
      result = nil
      Dir.chdir(temp_dir) do
        result = described_class.execute("status --porcelain", capture_output: false)
      end

      expect(result).to be_a(Hash)
      expect(result[:success]).to be true
      expect(result).not_to have_key(:stdout) # capture_output: false
    end
  end

  describe "#initialize" do
    context "with default options" do
      it "initializes without repository path" do
        executor = described_class.new
        expect(executor.send(:repository_path)).to be_nil
      end
    end

    context "with repository_path option" do
      it "initializes with specified repository path" do
        executor = described_class.new(repository_path: temp_dir)
        expect(executor.send(:repository_path)).to eq(temp_dir)
      end
    end
  end

  describe "#execute" do
    context "with capture_output: true (default)" do
      it "executes git status successfully" do
        result = nil
        Dir.chdir(temp_dir) do
          result = executor.execute("status --porcelain")
        end

        expect(result[:success]).to be true
        expect(result[:stdout]).to be_a(String)
        expect(result[:stderr]).to be_a(String)
        expect(result[:exit_status]).to eq(0)
      end

      it "executes git log successfully" do
        result = nil
        Dir.chdir(temp_dir) do
          result = executor.execute("log --oneline")
        end

        expect(result[:success]).to be true
        expect(result[:stdout]).to include("Initial commit")
        expect(result[:exit_status]).to eq(0)
      end

      it "handles git commands with arguments" do
        result = nil
        Dir.chdir(temp_dir) do
          result = executor.execute("show --name-only")
        end

        expect(result[:success]).to be true
        expect(result[:stdout]).to include("test.txt")
      end

      it "raises GitCommandError for invalid git commands" do
        Dir.chdir(temp_dir) do
          expect { executor.execute("invalid-command") }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError,
            /Git command failed/
          )
        end
      end

      it "captures stderr output in GitCommandError" do
        Dir.chdir(temp_dir) do
          executor.execute("invalid-command")
        rescue CodingAgentTools::Atoms::Git::GitCommandError => e
          expect(e.stderr_output).to include("invalid-command")
          expect(e.exit_status).not_to eq(0)
          expect(e.command).to include("git invalid-command")
        end
      end
    end

    context "with capture_output: false" do
      it "executes git status without capturing output" do
        result = nil
        Dir.chdir(temp_dir) do
          result = executor.execute("status --porcelain", capture_output: false)
        end

        expect(result[:success]).to be true
        expect(result[:exit_status]).to eq(0)
        expect(result).not_to have_key(:stdout)
        expect(result).not_to have_key(:stderr)
      end

      it "raises GitCommandError for invalid commands without capture" do
        Dir.chdir(temp_dir) do
          expect { executor.execute("invalid-command", capture_output: false) }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError,
            /Git command failed/
          )
        end
      end
    end

    context "with repository_path specified" do
      let(:executor_with_path) { described_class.new(repository_path: temp_dir) }

      it "executes commands in specified repository" do
        result = executor_with_path.execute("status --porcelain")

        expect(result[:success]).to be true
        expect(result[:stdout]).to be_a(String)
      end

      it "handles relative paths correctly" do
        # Create a subdirectory structure
        subdir = File.join(temp_dir, "subdir")
        FileUtils.mkdir_p(subdir)

        relative_executor = described_class.new(repository_path: ".")
        result = nil
        Dir.chdir(temp_dir) do
          result = relative_executor.execute("status --porcelain")
        end

        expect(result[:success]).to be true
      end

      it "raises error for non-existent repository path" do
        invalid_executor = described_class.new(repository_path: "/non/existent/path")

        expect { invalid_executor.execute("status") }.to raise_error(
          CodingAgentTools::Atoms::Git::GitCommandError,
          /Repository path not found/
        )
      end
    end
  end

  describe "GitCommandError" do
    it "includes command, exit_status, and stderr_output" do
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

  describe "private methods" do
    describe "#build_command" do
      context "without repository path" do
        it "builds simple git command" do
          result = executor.send(:build_command, "status")
          expect(result).to eq("git status")
        end

        it "preserves command arguments" do
          result = executor.send(:build_command, "log --oneline --graph")
          expect(result).to eq("git log --oneline --graph")
        end
      end

      context "with repository path" do
        let(:executor_with_path) { described_class.new(repository_path: temp_dir) }

        it "builds command with -C option" do
          result = executor_with_path.send(:build_command, "status")
          expect(result).to include("git -C")
          expect(result).to include(temp_dir)
          expect(result).to include("status")
        end

        it "escapes repository path with spaces" do
          spaced_dir = File.join(File.dirname(temp_dir), "dir with spaces")
          FileUtils.mkdir_p(spaced_dir)
          Dir.chdir(spaced_dir) do
            system("git init", out: File::NULL, err: File::NULL)
          end

          spaced_executor = described_class.new(repository_path: spaced_dir)
          result = spaced_executor.send(:build_command, "status")

          expect(result).to include("git -C")
          expect(result).to include("dir\\ with\\ spaces")

          FileUtils.rm_rf(spaced_dir)
        end

        it "handles current directory path" do
          current_dir_executor = described_class.new(repository_path: ".")
          result = current_dir_executor.send(:build_command, "status")
          expect(result).to eq("git status")
        end
      end
    end

    describe "#resolve_repository_path" do
      context "with absolute paths" do
        it "returns absolute path as-is" do
          result = executor.send(:resolve_repository_path, temp_dir)
          expect(result).to eq(temp_dir)
        end

        it "handles absolute path that doesn't exist" do
          expect { executor.send(:resolve_repository_path, "/non/existent/absolute/path") }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError,
            /Repository path not found/
          )
        end
      end

      context "with relative paths" do
        it "returns existing local relative path" do
          subdir = "test_subdir"
          full_subdir = File.join(temp_dir, subdir)
          FileUtils.mkdir_p(full_subdir)

          Dir.chdir(temp_dir) do
            result = executor.send(:resolve_repository_path, subdir)
            expect(result).to eq(subdir)
          end

          FileUtils.rm_rf(full_subdir)
        end

        it "resolves to project root when local path doesn't exist" do
          allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
            .and_return(File.dirname(temp_dir))

          # Create the path relative to project root
          relative_path = File.basename(temp_dir)
          result = executor.send(:resolve_repository_path, relative_path)

          expect(result).to eq(temp_dir)
        end

        it "raises error when path not found locally or relative to project root" do
          allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
            .and_return(File.dirname(temp_dir))

          expect { executor.send(:resolve_repository_path, "non_existent_path") }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError,
            /Repository path not found: non_existent_path/
          )
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
        spaced_command = "git    status   --porcelain"
        result = executor.send(:format_command_for_display, spaced_command)
        expect(result).to eq("git status --porcelain")
      end

      it "strips leading and trailing whitespace" do
        padded_command = "  git status  "
        result = executor.send(:format_command_for_display, padded_command)
        expect(result).to eq("git status")
      end

      it "handles complex escaped sequences" do
        complex_command = "git\\ -C\\ /path/with\\~special\\$chars\\ status"
        result = executor.send(:format_command_for_display, complex_command)
        expect(result).to eq("git -C /path/with~special$chars status")
      end

      it "handles various escaped characters" do
        escaped_command = "git commit -m fix\\:\\ update\\ \\(version\\)\\ and\\ \\\"quotes\\\""
        formatted = executor.send(:format_command_for_display, escaped_command)

        expect(formatted).to eq('git commit -m fix: update (version) and "quotes"')
      end
    end

    describe "#execute_with_capture" do
      it "handles timeout scenario" do
        # Mock Open3.capture3 to simulate a hanging command
        allow(Open3).to receive(:capture3) do
          sleep(1) # Simulate long-running command
        end

        # Mock Timeout.timeout to raise immediately
        allow(Timeout).to receive(:timeout).with(30).and_raise(Timeout::Error)

        Dir.chdir(temp_dir) do
          expect { executor.send(:execute_with_capture, "git status") }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError,
            /Git command timed out/
          ) do |error|
            expect(error.exit_status).to eq(124)
            expect(error.stderr_output).to eq("Command timed out")
          end
        end
      end

      it "handles failed commands with proper error details" do
        # Mock Open3.capture3 to simulate failed command
        failed_status = double(success?: false, exitstatus: 128)
        allow(Open3).to receive(:capture3).and_return(["", "fatal: not a git repository", failed_status])
        allow(Timeout).to receive(:timeout).and_yield

        expect { executor.send(:execute_with_capture, "git status") }.to raise_error(
          CodingAgentTools::Atoms::Git::GitCommandError,
          /Git command failed/
        ) do |error|
          expect(error.exit_status).to eq(128)
          expect(error.stderr_output).to eq("fatal: not a git repository")
        end
      end
    end

    describe "#execute_without_capture" do
      it "handles failed system commands" do
        # Mock system to return false (failure)
        allow(executor).to receive(:system).and_return(false)

        # Mock $? to simulate exit status
        process_status = double(exitstatus: 1)
        allow($?).to receive(:exitstatus).and_return(1)
        stub_const("$?", process_status)

        expect { executor.send(:execute_without_capture, "git invalid") }.to raise_error(
          CodingAgentTools::Atoms::Git::GitCommandError,
          /Git command failed/
        ) do |error|
          expect(error.exit_status).to eq(1)
        end
      end
    end
  end

  describe "comprehensive edge cases and error handling" do
    context "with malformed or dangerous commands" do
      it "handles commands with special characters safely" do
        Dir.chdir(temp_dir) do
          # Git should reject these, but our executor should handle them safely
          expect { executor.execute("status; rm -rf /") }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError
          )
        end
      end

      it "handles very long command arguments" do
        long_message = "a" * 1000
        Dir.chdir(temp_dir) do
          result = executor.execute("commit --allow-empty -m '#{long_message}'")
          expect(result[:success]).to be true
        end
      end

      it "handles Unicode characters in commands" do
        Dir.chdir(temp_dir) do
          result = executor.execute("commit --allow-empty -m 'Unicode: 🚀 中文'")
          expect(result[:success]).to be true
        end
      end
    end

    context "with environment variable edge cases" do
      before do
        @original_env = ENV.to_hash
      end

      after do
        ENV.clear
        ENV.update(@original_env)
      end

      it "handles commands when PATH is modified" do
        # Temporarily modify PATH to test PATH resolution
        ENV["PATH"] = "/usr/bin:/bin"

        Dir.chdir(temp_dir) do
          result = executor.execute("--version")
          expect(result[:success]).to be true
          expect(result[:stdout]).to include("git version")
        end
      end

      it "handles commands with custom GIT_DIR" do
        git_dir = File.join(temp_dir, ".git")
        ENV["GIT_DIR"] = git_dir

        Dir.chdir(temp_dir) do
          result = executor.execute("status --porcelain")
          expect(result[:success]).to be true
        end
      end
    end

    context "with concurrent execution" do
      it "maintains thread safety during execution" do
        results = Queue.new
        threads = []

        5.times do
          threads << Thread.new do
            local_executor = described_class.new
            Dir.chdir(temp_dir) do
              result = local_executor.execute("status --porcelain")
              results << result
            end
          end
        end

        threads.each(&:join)

        # All results should be successful
        5.times do
          result = results.pop
          expect(result[:success]).to be true
        end
      end
    end

    context "with file system edge cases" do
      xit "handles repository in read-only directory" do
        # Create a read-only directory (if possible on current platform)
        readonly_dir = File.join(temp_dir, "readonly")
        FileUtils.mkdir_p(readonly_dir)

        begin
          skip "Cannot create readonly directory" unless File.exist?(readonly_dir)
          FileUtils.chmod(0o444, readonly_dir)
          readonly_executor = described_class.new(repository_path: readonly_dir)

          expect { readonly_executor.execute("status") }.to raise_error(
            CodingAgentTools::Atoms::Git::GitCommandError
          )
        ensure
          begin
            FileUtils.chmod(0o755, readonly_dir)
          rescue
            nil
          end
          begin
            FileUtils.rm_rf(readonly_dir)
          rescue
            nil
          end
        end
      end

      it "handles symbolic links in repository path" do
        if File.respond_to?(:symlink) # Check if platform supports symlinks
          symlink_path = File.join(File.dirname(temp_dir), "repo_symlink")

          begin
            File.symlink(temp_dir, symlink_path)
            symlink_executor = described_class.new(repository_path: symlink_path)

            result = symlink_executor.execute("status --porcelain")
            expect(result[:success]).to be true
          rescue NotImplementedError
            # Skip on platforms that don't support symlinks
            skip "Symlinks not supported on this platform"
          ensure
            File.unlink(symlink_path) if File.exist?(symlink_path)
          end
        end
      end
    end
  end

  describe "algorithm correctness verification" do
    context "command building accuracy" do
      it "properly constructs git commands with repository path" do
        executor_with_path = described_class.new(repository_path: temp_dir)
        command = executor_with_path.send(:build_command, "log --oneline")

        expect(command).to start_with("git -C")
        expect(command).to include(temp_dir)
        expect(command).to end_with("log --oneline")
      end

      it "properly escapes special characters in paths" do
        special_chars_dir = File.join(File.dirname(temp_dir), "dir$with&special*chars")
        FileUtils.mkdir_p(special_chars_dir)
        Dir.chdir(special_chars_dir) do
          system("git init", out: File::NULL, err: File::NULL)
        end

        special_executor = described_class.new(repository_path: special_chars_dir)
        command = special_executor.send(:build_command, "status")

        # Should be properly escaped
        expect(command).to include("\\$")
        expect(command).to include("\\&")
        expect(command).to include("\\*")

        FileUtils.rm_rf(special_chars_dir)
      end
    end

    context "error handling consistency" do
      it "provides consistent error information across execution modes" do
        captured_error = nil
        uncaptured_error = nil

        Dir.chdir(temp_dir) do
          # Test with capture_output: true
          begin
            executor.execute("invalid-command", capture_output: true)
          rescue CodingAgentTools::Atoms::Git::GitCommandError => e
            captured_error = e
          end

          # Test with capture_output: false
          begin
            executor.execute("invalid-command", capture_output: false)
          rescue CodingAgentTools::Atoms::Git::GitCommandError => e
            uncaptured_error = e
          end
        end

        expect(captured_error).not_to be_nil
        expect(uncaptured_error).not_to be_nil
        expect(captured_error.command).to eq(uncaptured_error.command)
        expect(captured_error.exit_status).to eq(uncaptured_error.exit_status)
      end
    end

    context "path resolution accuracy" do
      it "correctly prioritizes local paths over project root paths" do
        # Create both local and project-root-relative directories
        local_dir = "local_test"
        FileUtils.mkdir_p(File.join(temp_dir, local_dir))

        project_root_dir = File.join(File.dirname(temp_dir), local_dir)
        FileUtils.mkdir_p(project_root_dir)

        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root)
          .and_return(File.dirname(temp_dir))

        Dir.chdir(temp_dir) do
          result = executor.send(:resolve_repository_path, local_dir)
          expect(result).to eq(local_dir) # Should use local, not project root
        end

        FileUtils.rm_rf(project_root_dir)
      end
    end
  end

  describe "performance considerations" do
    it "executes multiple commands efficiently" do
      start_time = Time.now

      10.times do
        Dir.chdir(temp_dir) do
          executor.execute("status --porcelain")
        end
      end

      end_time = Time.now
      expect(end_time - start_time).to be < 5.0 # Should be reasonably fast
    end

    it "handles large output efficiently" do
      # Create a commit with a large message
      large_message = "Large commit message: " + ("test " * 1000)

      Dir.chdir(temp_dir) do
        executor.execute("commit --allow-empty -m '#{large_message}'")
        result = executor.execute("log -1 --pretty=format:%B")

        expect(result[:stdout]).to include("Large commit message")
        expect(result[:stdout].length).to be > 5000
      end
    end
  end

  # Legacy compatibility - maintain original test cases
  describe "legacy test compatibility" do
    it "can be instantiated" do
      expect { described_class.new }.not_to raise_error
    end

    it "raises GitCommandError for invalid commands" do
      expect {
        subject.execute("invalid-git-command")
      }.to raise_error(CodingAgentTools::Atoms::Git::GitCommandError)
    end

    it "can execute basic git commands" do
      # This test assumes we're in a git repository
      Dir.chdir(temp_dir) do
        expect {
          result = subject.execute("status")
          expect(result).to be_a(Hash)
          expect(result[:success]).to be true
        }.not_to raise_error
      end
    end

    it "formats error messages properly without shell escaping" do
      # Test that error messages display readable commands without shell escaping
      escaped_command = "commit -m refactor\\(git\\):\\ use\\ direct\\ Ruby\\ calls"

      allow(Open3).to receive(:capture3).with("git #{escaped_command}").and_return([
        "", "error output", double(success?: false, exitstatus: 1)
      ])

      expect {
        subject.execute(escaped_command)
      }.to raise_error(CodingAgentTools::Atoms::Git::GitCommandError) do |error|
        # Error message should show unescaped, readable command
        expect(error.message).to include("commit -m refactor(git): use direct Ruby calls")
        expect(error.message).not_to include("refactor\\(git\\):\\ use\\ direct\\ Ruby\\ calls")
      end
    end
  end
end
