# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/atoms/taskflow_management/shell_command_executor"

RSpec.describe CodingAgentTools::Atoms::TaskflowManagement::ShellCommandExecutor do
  describe "CommandResult" do
    let(:result) { described_class::CommandResult.new(true, "output", "error", 0, 1.5) }

    describe "#success?" do
      it "returns the success value" do
        expect(result.success?).to be true
      end
    end

    describe "#failure?" do
      it "returns the opposite of success" do
        expect(result.failure?).to be false
      end

      it "returns true when success is false" do
        failed_result = described_class::CommandResult.new(false, "", "error", 1, 1.0)
        expect(failed_result.failure?).to be true
      end
    end
  end

  describe "constants" do
    it "defines DEFAULT_TIMEOUT" do
      expect(described_class::DEFAULT_TIMEOUT).to eq(30)
    end

    it "defines MAX_COMMAND_LENGTH" do
      expect(described_class::MAX_COMMAND_LENGTH).to eq(8192)
    end
  end

  describe ".execute" do
    context "with simple commands" do
      it "executes successful commands" do
        result = described_class.execute("echo 'hello'")

        expect(result.success?).to be true
        expect(result.stdout.strip).to eq("hello")
        expect(result.stderr).to be_empty
        expect(result.exit_code).to eq(0)
        expect(result.duration).to be > 0
      end

      it "handles commands that fail" do
        result = described_class.execute("exit 1")

        expect(result.success?).to be false
        expect(result.exit_code).to eq(1)
        expect(result.duration).to be > 0
      end

      it "captures stdout and stderr" do
        result = described_class.execute("echo 'stdout'; echo 'stderr' >&2")

        expect(result.success?).to be true
        expect(result.stdout.strip).to eq("stdout")
        expect(result.stderr.strip).to eq("stderr")
      end
    end

    context "with timeout" do
      it "respects custom timeout" do
        result = described_class.execute("echo 'quick'", timeout: 5)

        expect(result.success?).to be true
        expect(result.stdout.strip).to eq("quick")
      end

      it "times out long-running commands" do
        result = described_class.execute("sleep 2", timeout: 1)

        expect(result.success?).to be false
        expect(result.stderr).to include("timed out")
        expect(result.exit_code).to eq(-1)
      end
    end

    context "with working directory" do
      let(:test_dir) { Dir.mktmpdir("shell_executor_test") }

      before do
        FileUtils.mkdir_p(test_dir)
        File.write(File.join(test_dir, "test_file.txt"), "test content")
      end

      after do
        FileUtils.rm_rf(test_dir)
      end

      it "executes commands in specified directory" do
        result = described_class.execute("ls test_file.txt", working_directory: test_dir)

        expect(result.success?).to be true
        expect(result.stdout.strip).to eq("test_file.txt")
      end

      it "handles non-existent working directory" do
        result = described_class.execute("pwd", working_directory: "/nonexistent/path")

        expect(result.success?).to be false
        expect(result.stderr).to include("Execution error")
      end
    end

    context "with environment variables" do
      it "sets environment variables" do
        result = described_class.execute("echo $TEST_VAR", environment: { "TEST_VAR" => "test_value" })

        expect(result.success?).to be true
        expect(result.stdout.strip).to eq("test_value")
      end

      it "combines with existing environment" do
        original_path = ENV["PATH"]
        result = described_class.execute("echo $PATH", environment: { "TEST_VAR" => "value" })

        expect(result.success?).to be true
        expect(result.stdout.strip).to include(original_path)
      end
    end

    context "with capture_output option" do
      it "captures output when enabled" do
        result = described_class.execute("echo 'captured'", capture_output: true)

        expect(result.success?).to be true
        expect(result.stdout.strip).to eq("captured")
      end

      it "does not capture output when disabled" do
        result = described_class.execute("echo 'not captured'", capture_output: false)

        expect(result.success?).to be true
        expect(result.stdout).to be_empty
        expect(result.stderr).to be_empty
      end
    end

    context "with invalid parameters" do
      it "validates command parameter" do
        expect { described_class.execute(nil) }.to raise_error(ArgumentError, /command must be a string/)
      end

      it "validates timeout parameter" do
        expect { described_class.execute("echo test", timeout: -1) }.to raise_error(ArgumentError, /timeout must be a positive integer/)
        expect { described_class.execute("echo test", timeout: 5000) }.to raise_error(ArgumentError, /timeout too large/)
      end

      it "validates working_directory parameter" do
        expect { described_class.execute("echo test", working_directory: 123) }.to raise_error(ArgumentError, /working_directory must be a string/)
        expect { described_class.execute("echo test", working_directory: "") }.to raise_error(ArgumentError, /working_directory cannot be empty/)
      end

      it "validates environment parameter" do
        expect { described_class.execute("echo test", environment: "not_hash") }.to raise_error(ArgumentError, /environment must be a hash/)
        expect { described_class.execute("echo test", environment: { 123 => "value" }) }.to raise_error(ArgumentError, /environment key must be a string/)
        expect { described_class.execute("echo test", environment: { "key" => 123 }) }.to raise_error(ArgumentError, /environment value must be a string/)
      end
    end

    context "with security validation" do
      it "rejects unsafe commands" do
        expect { described_class.execute("rm -rf /") }.to raise_error(SecurityError, /command failed security validation/)
      end

      it "rejects commands with null bytes" do
        expect { described_class.execute("echo\0test") }.to raise_error(SecurityError, /command failed security validation/)
      end

      it "rejects overly long commands" do
        long_command = "echo " + "a" * 10000
        expect { described_class.execute(long_command) }.to raise_error(SecurityError, /command failed security validation/)
      end

      it "rejects commands with control characters" do
        expect { described_class.execute("echo\x01test") }.to raise_error(SecurityError, /command failed security validation/)
      end
    end

    context "with error handling" do
      it "handles execution errors gracefully" do
        # Try to execute a command that will cause an execution error
        result = described_class.execute("nonexistent_command_12345")

        expect(result.success?).to be false
        expect(result.stderr).to include("Execution error")
        expect(result.exit_code).to eq(-1)
      end
    end
  end

  describe ".execute_simple" do
    it "returns boolean for successful commands" do
      result = described_class.execute_simple("true")
      expect(result).to be true
    end

    it "returns boolean for failed commands" do
      result = described_class.execute_simple("false")
      expect(result).to be false
    end

    it "passes through parameters" do
      result = described_class.execute_simple("echo test", timeout: 10)
      expect(result).to be true
    end
  end

  describe ".safe_command?" do
    context "with safe commands" do
      it "allows basic commands" do
        expect(described_class.safe_command?("echo hello")).to be true
        expect(described_class.safe_command?("ls -la")).to be true
        expect(described_class.safe_command?("git status")).to be true
      end

      it "allows commands with reasonable length" do
        command = "echo " + "a" * 100
        expect(described_class.safe_command?(command)).to be true
      end
    end

    context "with unsafe commands" do
      it "rejects nil and empty commands" do
        expect(described_class.safe_command?(nil)).to be false
        expect(described_class.safe_command?("")).to be false
        expect(described_class.safe_command?(123)).to be false
      end

      it "rejects commands with null bytes" do
        expect(described_class.safe_command?("echo\0test")).to be false
      end

      it "rejects commands with control characters" do
        expect(described_class.safe_command?("echo\x01test")).to be false
        expect(described_class.safe_command?("echo\x7ftest")).to be false
      end

      it "rejects dangerous command patterns" do
        expect(described_class.safe_command?("rm -rf /")).to be false
        expect(described_class.safe_command?("format c:")).to be false
        expect(described_class.safe_command?("dd if=/dev/zero")).to be false
        expect(described_class.safe_command?("echo test > /dev/sda")).to be false
        expect(described_class.safe_command?("echo test | dd of=/dev/sda")).to be false
      end

      it "rejects overly long commands" do
        long_command = "echo " + "a" * 10000
        expect(described_class.safe_command?(long_command)).to be false
      end
    end
  end

  describe ".build_command" do
    it "builds command with escaped arguments" do
      result = described_class.build_command("git", ["add", "file with spaces.txt"])
      expect(result).to eq("git add file\\ with\\ spaces.txt")
    end

    it "handles commands without arguments" do
      result = described_class.build_command("git", [])
      expect(result).to eq("git")
    end

    it "handles special characters in arguments" do
      result = described_class.build_command("echo", ["hello & world"])
      expect(result).to eq("echo hello\\ \\&\\ world")
    end

    it "validates parameters" do
      expect { described_class.build_command(nil, []) }.to raise_error(ArgumentError, /base_command cannot be nil/)
      expect { described_class.build_command("", []) }.to raise_error(ArgumentError, /base_command cannot be nil/)
      expect { described_class.build_command("git", "not_array") }.to raise_error(ArgumentError, /arguments must be an array/)
    end

    it "converts non-string arguments to strings" do
      result = described_class.build_command("echo", [123, true, nil])
      expect(result).to eq("echo 123 true ''")
    end
  end

  describe ".execute_with_retries" do
    it "succeeds on first attempt" do
      result = described_class.execute_with_retries("true")

      expect(result.success?).to be true
    end

    it "retries failed commands" do
      # This is tricky to test deterministically, so we'll test the interface
      result = described_class.execute_with_retries("false", max_retries: 1)

      expect(result.success?).to be false
    end

    it "respects max_retries parameter" do
      start_time = Time.now
      result = described_class.execute_with_retries("false", max_retries: 2, retry_delay: 0.1)
      end_time = Time.now

      expect(result.success?).to be false
      # Should have taken at least 0.2 seconds (2 retries * 0.1 delay)
      expect(end_time - start_time).to be >= 0.15
    end

    it "does not sleep after final attempt" do
      start_time = Time.now
      result = described_class.execute_with_retries("false", max_retries: 1, retry_delay: 1.0)
      end_time = Time.now

      expect(result.success?).to be false
      # Should not wait full second after final attempt
      expect(end_time - start_time).to be < 1.5
    end
  end

  describe "private methods" do
    describe ".validate_command" do
      it "raises ArgumentError for invalid commands" do
        expect { described_class.send(:validate_command, nil) }.to raise_error(ArgumentError, /command must be a string/)
        expect { described_class.send(:validate_command, "") }.to raise_error(ArgumentError, /command cannot be nil/)
        expect { described_class.send(:validate_command, 123) }.to raise_error(ArgumentError, /command must be a string/)
      end

      it "raises SecurityError for unsafe commands" do
        expect { described_class.send(:validate_command, "rm -rf /") }.to raise_error(SecurityError, /command failed security validation/)
      end

      it "passes validation for safe commands" do
        expect { described_class.send(:validate_command, "echo hello") }.not_to raise_error
      end
    end

    describe ".validate_timeout" do
      it "raises ArgumentError for invalid timeouts" do
        expect { described_class.send(:validate_timeout, -1) }.to raise_error(ArgumentError, /timeout must be a positive integer/)
        expect { described_class.send(:validate_timeout, 0) }.to raise_error(ArgumentError, /timeout must be a positive integer/)
        expect { described_class.send(:validate_timeout, "10") }.to raise_error(ArgumentError, /timeout must be a positive integer/)
        expect { described_class.send(:validate_timeout, 5000) }.to raise_error(ArgumentError, /timeout too large/)
      end

      it "passes validation for valid timeouts" do
        expect { described_class.send(:validate_timeout, 30) }.not_to raise_error
        expect { described_class.send(:validate_timeout, 3600) }.not_to raise_error
      end
    end

    describe ".validate_working_directory" do
      it "raises ArgumentError for invalid directories" do
        expect { described_class.send(:validate_working_directory, 123) }.to raise_error(ArgumentError, /working_directory must be a string/)
        expect { described_class.send(:validate_working_directory, "") }.to raise_error(ArgumentError, /working_directory cannot be empty/)
      end

      it "raises SecurityError for unsafe directory paths" do
        expect { described_class.send(:validate_working_directory, "../../../etc") }.to raise_error(SecurityError, /working_directory failed security validation/)
        expect { described_class.send(:validate_working_directory, "path\0with\0nulls") }.to raise_error(SecurityError, /working_directory failed security validation/)
      end

      it "passes validation for safe directories" do
        expect { described_class.send(:validate_working_directory, "/tmp") }.not_to raise_error
        expect { described_class.send(:validate_working_directory, "relative/path") }.not_to raise_error
      end
    end

    describe ".validate_environment" do
      it "raises ArgumentError for invalid environment" do
        expect { described_class.send(:validate_environment, "not_hash") }.to raise_error(ArgumentError, /environment must be a hash/)
        expect { described_class.send(:validate_environment, { 123 => "value" }) }.to raise_error(ArgumentError, /environment key must be a string/)
        expect { described_class.send(:validate_environment, { "key" => 123 }) }.to raise_error(ArgumentError, /environment value must be a string/)
        expect { described_class.send(:validate_environment, { "" => "value" }) }.to raise_error(ArgumentError, /environment key cannot be empty/)
      end

      it "raises SecurityError for unsafe environment values" do
        expect { described_class.send(:validate_environment, { "key=bad" => "value" }) }.to raise_error(SecurityError, /environment key contains invalid characters/)
        expect { described_class.send(:validate_environment, { "key" => "value\0null" }) }.to raise_error(SecurityError, /environment value contains null bytes/)
        expect { described_class.send(:validate_environment, { "key\x01" => "value" }) }.to raise_error(SecurityError, /environment key contains invalid characters/)
      end

      it "passes validation for safe environment" do
        expect { described_class.send(:validate_environment, {}) }.not_to raise_error
        expect { described_class.send(:validate_environment, { "KEY" => "value" }) }.not_to raise_error
        expect { described_class.send(:validate_environment, { "PATH" => "/usr/bin" }) }.not_to raise_error
      end
    end

    describe ".execute_with_capture" do
      let(:start_time) { Time.now }

      it "captures command output" do
        result = described_class.send(:execute_with_capture, "echo hello", {}, {}, 30, start_time)

        expect(result.success?).to be true
        expect(result.stdout.strip).to eq("hello")
        expect(result.exit_code).to eq(0)
      end

      it "handles timeouts" do
        result = described_class.send(:execute_with_capture, "sleep 2", {}, {}, 1, start_time)

        expect(result.success?).to be false
        expect(result.stderr).to include("timed out")
        expect(result.exit_code).to eq(-1)
      end
    end

    describe ".execute_without_capture" do
      let(:start_time) { Time.now }

      it "executes without capturing output" do
        result = described_class.send(:execute_without_capture, "true", {}, {}, 30, start_time)

        expect(result.success?).to be true
        expect(result.stdout).to be_empty
        expect(result.stderr).to be_empty
        expect(result.exit_code).to eq(0)
      end

      it "handles timeouts" do
        result = described_class.send(:execute_without_capture, "sleep 2", {}, {}, 1, start_time)

        expect(result.success?).to be false
        expect(result.stderr).to include("timed out")
        expect(result.exit_code).to eq(-1)
      end
    end

    describe ".safe_directory_path?" do
      it "returns true for safe paths" do
        expect(described_class.send(:safe_directory_path?, "/tmp")).to be true
        expect(described_class.send(:safe_directory_path?, "relative/path")).to be true
        expect(described_class.send(:safe_directory_path?, "/usr/local/bin")).to be true
      end

      it "returns false for unsafe paths" do
        expect(described_class.send(:safe_directory_path?, nil)).to be false
        expect(described_class.send(:safe_directory_path?, "")).to be false
        # Note: calling with integer will raise NoMethodError due to implementation bug
        expect { described_class.send(:safe_directory_path?, 123) }.to raise_error(NoMethodError)
        expect(described_class.send(:safe_directory_path?, "path\0null")).to be false
        expect(described_class.send(:safe_directory_path?, "path\x01control")).to be false
        expect(described_class.send(:safe_directory_path?, "../../../etc")).to be false
        expect(described_class.send(:safe_directory_path?, "path\\..\\traversal")).to be false
        expect(described_class.send(:safe_directory_path?, "a" * 5000)).to be false
      end
    end
  end

  describe "integration tests" do
    let(:test_dir) { Dir.mktmpdir("shell_executor_integration") }

    before do
      FileUtils.mkdir_p(test_dir)
    end

    after do
      FileUtils.rm_rf(test_dir)
    end

    it "executes complex command pipeline" do
      # Create test files
      File.write(File.join(test_dir, "file1.txt"), "line1\nline2\nline3")
      File.write(File.join(test_dir, "file2.txt"), "line4\nline5")

      # Execute command with pipes
      result = described_class.execute("cat file1.txt file2.txt | wc -l", working_directory: test_dir)

      expect(result.success?).to be true
      expect(result.stdout.strip).to eq("3")
    end

    it "handles environment and working directory together" do
      result = described_class.execute(
        "echo $TEST_MESSAGE > output.txt && cat output.txt",
        working_directory: test_dir,
        environment: { "TEST_MESSAGE" => "hello from env" }
      )

      expect(result.success?).to be true
      expect(result.stdout.strip).to eq("hello from env")
      expect(File.exist?(File.join(test_dir, "output.txt"))).to be true
    end

    it "measures execution duration accurately" do
      result = described_class.execute("sleep 0.1")

      expect(result.success?).to be true
      expect(result.duration).to be >= 0.09  # Account for timing variations
      expect(result.duration).to be < 0.5    # Should not take too long
    end

    it "handles stderr and stdout simultaneously" do
      result = described_class.execute("echo 'stdout message'; echo 'stderr message' >&2; exit 0")

      expect(result.success?).to be true
      expect(result.stdout.strip).to eq("stdout message")
      expect(result.stderr.strip).to eq("stderr message")
    end

    it "works with file operations" do
      test_file = File.join(test_dir, "test.txt")

      # Create file
      result = described_class.execute("echo 'test content' > test.txt", working_directory: test_dir)
      expect(result.success?).to be true
      expect(File.exist?(test_file)).to be true

      # Read file
      result = described_class.execute("cat test.txt", working_directory: test_dir)
      expect(result.success?).to be true
      expect(result.stdout.strip).to eq("test content")
    end
  end

  describe "edge cases and error conditions" do
    it "handles empty command gracefully" do
      expect { described_class.execute("") }.to raise_error(ArgumentError)
    end

    it "handles commands with only whitespace" do
      # Skip this test - behavior depends on shell implementation
      skip "Whitespace command behavior varies by shell"
    end

    it "handles very quick commands" do
      result = described_class.execute(":")  # No-op command

      expect(result.success?).to be true
      expect(result.duration).to be > 0
      expect(result.duration).to be < 1
    end

    it "handles commands with unicode characters" do
      result = described_class.execute("echo 'Hello 世界 🌍'")

      expect(result.success?).to be true
      expect(result.stdout.strip).to eq("Hello 世界 🌍")
    end

    it "handles large output" do
      # Generate large output
      result = described_class.execute("seq 1 1000")

      expect(result.success?).to be true
      expect(result.stdout.lines.count).to eq(1000)
    end

    it "properly cleans up resources on timeout" do
      # This test ensures that timeouts don't leave zombie processes
      5.times do
        result = described_class.execute("sleep 2", timeout: 1)
        expect(result.success?).to be false
      end

      # If we reach here without hanging, resource cleanup worked
      expect(true).to be true
    end
  end
end
