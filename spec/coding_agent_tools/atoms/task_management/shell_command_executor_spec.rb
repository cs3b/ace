# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::TaskManagement::ShellCommandExecutor do
  describe "CommandResult" do
    let(:success_result) { described_class::CommandResult.new(true, "output", "", 0, 0.1) }
    let(:failure_result) { described_class::CommandResult.new(false, "", "error", 1, 0.2) }

    it "reports success correctly" do
      expect(success_result.success?).to be true
      expect(success_result.failure?).to be false
    end

    it "reports failure correctly" do
      expect(failure_result.success?).to be false
      expect(failure_result.failure?).to be true
    end

    it "provides access to all fields" do
      expect(success_result.stdout).to eq("output")
      expect(success_result.stderr).to eq("")
      expect(success_result.exit_code).to eq(0)
      expect(success_result.duration).to eq(0.1)
    end
  end

  describe ".execute" do
    it "executes simple successful command" do
      result = described_class.execute('printf "hello world"')
      expect(result.success?).to be true
      expect(result.stdout.strip).to eq("hello world")
      expect(result.stderr).to eq("")
      expect(result.exit_code).to eq(0)
      expect(result.duration).to be > 0
    end

    it "captures stderr for failing commands" do
      # Use a command that writes to stderr
      result = described_class.execute('printf "error message" >&2; exit 1')
      expect(result.success?).to be false
      expect(result.stdout).to eq("")
      expect(result.stderr.strip).to eq("error message")
      expect(result.exit_code).to eq(1)
    end

    it "respects working directory" do
      Dir.mktmpdir do |temp_dir|
        test_file = File.join(temp_dir, "test.txt")
        File.write(test_file, "content")

        result = described_class.execute("test -f test.txt", working_directory: temp_dir)
        expect(result.success?).to be true
        expect(result.stdout.strip).to eq("")
      end
    end

    it "respects environment variables" do
      result = described_class.execute("printf $TEST_VAR", environment: {"TEST_VAR" => "test_value"})
      expect(result.success?).to be true
      expect(result.stdout.strip).to eq("test_value")
    end

    it "handles timeout" do
      result = described_class.execute("sleep 2", timeout: 1)
      expect(result.success?).to be false
      expect(result.stderr).to include("timed out")
      expect(result.exit_code).to eq(-1)
    end

    it "executes without capturing output when requested" do
      result = described_class.execute("true", capture_output: false)
      expect(result.stdout).to eq("")
      expect(result.stderr).to eq("")
      expect(result.success?).to be true
    end

    it "raises ArgumentError for invalid command" do
      expect { described_class.execute(nil) }.to raise_error(ArgumentError, "command must be a string")
      expect { described_class.execute("") }.to raise_error(ArgumentError, "command cannot be nil or empty")
      expect { described_class.execute(123) }.to raise_error(ArgumentError, "command must be a string")
    end

    it "raises SecurityError for unsafe command" do
      expect { described_class.execute("rm -rf /") }.to raise_error(SecurityError, "command failed security validation")
    end

    it "raises ArgumentError for invalid timeout" do
      expect { described_class.execute("echo test", timeout: 0) }.to raise_error(ArgumentError, "timeout must be a positive integer")
      expect { described_class.execute("echo test", timeout: "invalid") }.to raise_error(ArgumentError, "timeout must be a positive integer")
      expect { described_class.execute("echo test", timeout: 5000) }.to raise_error(ArgumentError, "timeout too large (max 3600 seconds)")
    end

    it "raises ArgumentError for invalid working directory" do
      expect { described_class.execute("echo test", working_directory: 123) }.to raise_error(ArgumentError, "working_directory must be a string")
      expect { described_class.execute("echo test", working_directory: "") }.to raise_error(ArgumentError, "working_directory cannot be empty")
      expect { described_class.execute("echo test", working_directory: "../unsafe") }.to raise_error(SecurityError, "working_directory failed security validation")
    end

    it "raises ArgumentError for invalid environment" do
      expect { described_class.execute("echo test", environment: "invalid") }.to raise_error(ArgumentError, "environment must be a hash")
      expect { described_class.execute("echo test", environment: {123 => "value"}) }.to raise_error(ArgumentError, "environment key must be a string")
      expect { described_class.execute("echo test", environment: {"key" => 123}) }.to raise_error(ArgumentError, "environment value must be a string")
      expect { described_class.execute("echo test", environment: {"" => "value"}) }.to raise_error(ArgumentError, "environment key cannot be empty")
      expect { described_class.execute("echo test", environment: {"key\x00" => "value"}) }.to raise_error(SecurityError, "environment key contains invalid characters")
      expect { described_class.execute("echo test", environment: {"key" => "value\x00"}) }.to raise_error(SecurityError, "environment value contains null bytes")
    end
  end

  describe ".execute_simple" do
    it "returns true for successful command" do
      result = described_class.execute_simple("true")
      expect(result).to be true
    end

    it "returns false for failing command" do
      result = described_class.execute_simple("exit 1")
      expect(result).to be false
    end

    it "accepts same parameters as execute" do
      Dir.mktmpdir do |temp_dir|
        test_file = File.join(temp_dir, "test.txt")
        File.write(test_file, "content")

        result = described_class.execute_simple("test -f test.txt", working_directory: temp_dir)
        expect(result).to be true
      end
    end
  end

  describe ".safe_command?" do
    it "returns true for safe commands" do
      expect(described_class.safe_command?('printf "hello"')).to be true
      expect(described_class.safe_command?("ls -la")).to be true
      expect(described_class.safe_command?("git status")).to be true
      expect(described_class.safe_command?("npm install")).to be true
    end

    it "returns false for unsafe commands" do
      expect(described_class.safe_command?(nil)).to be false
      expect(described_class.safe_command?("")).to be false
      expect(described_class.safe_command?(123)).to be false
      expect(described_class.safe_command?("command\x00")).to be false
      expect(described_class.safe_command?("command\x01")).to be false
      expect(described_class.safe_command?("rm -rf /")).to be false
      expect(described_class.safe_command?("printf test; rm -rf /")).to be false
      expect(described_class.safe_command?("cat /etc/passwd > /dev/sda")).to be false
      expect(described_class.safe_command?("printf test | dd of=/dev/sda")).to be false
      expect(described_class.safe_command?("format c:")).to be false
    end

    it "returns false for excessively long commands" do
      long_command = "printf " + "a" * 10000
      expect(described_class.safe_command?(long_command)).to be false
    end
  end

  describe ".escape_argument" do
    it "escapes arguments safely" do
      expect(described_class.escape_argument("simple")).to eq("'simple'")
      expect(described_class.escape_argument("with spaces")).to eq("'with spaces'")
      expect(described_class.escape_argument("with'quote")).to eq("'with'\"'\"'quote'")
      expect(described_class.escape_argument("")).to eq('""')
      expect(described_class.escape_argument(nil)).to eq('""')
    end

    it "handles special characters" do
      expect(described_class.escape_argument("$VAR")).to eq("'$VAR'")
      expect(described_class.escape_argument("file&name")).to eq("'file&name'")
      expect(described_class.escape_argument("file;name")).to eq("'file;name'")
    end
  end

  describe ".build_command" do
    it "builds command with escaped arguments" do
      result = described_class.build_command("ls", ["-la", "/home/user"])
      expect(result).to eq("ls '-la' '/home/user'")
    end

    it "handles arguments with spaces and special characters" do
      result = described_class.build_command("printf", ["hello world", "with$var"])
      expect(result).to eq("printf 'hello world' 'with$var'")
    end

    it "works with no arguments" do
      result = described_class.build_command("pwd")
      expect(result).to eq("pwd")
    end

    it "converts non-string arguments to strings" do
      result = described_class.build_command("printf", [123, true])
      expect(result).to eq("printf '123' 'true'")
    end

    it "raises ArgumentError for invalid inputs" do
      expect { described_class.build_command(nil) }.to raise_error(ArgumentError, "base_command cannot be nil or empty")
      expect { described_class.build_command("") }.to raise_error(ArgumentError, "base_command cannot be nil or empty")
      expect { described_class.build_command("printf", "not_array") }.to raise_error(ArgumentError, "arguments must be an array")
    end
  end

  describe ".execute_with_retries" do
    before do
      # Mock sleep to prevent delays in retry tests
      allow(described_class).to receive(:sleep)
    end

    it "succeeds on first attempt when command works" do
      result = described_class.execute_with_retries('printf "success"')
      expect(result.success?).to be true
      expect(result.stdout.strip).to eq("success")
    end

    it "retries failing commands" do
      # Use a file that we'll create after the first attempt to simulate eventual success
      Dir.mktmpdir do |temp_dir|
        flag_file = File.join(temp_dir, "flag")

        # This command will fail until flag file exists
        command = "test -f #{described_class.escape_argument(flag_file)}"

        # Start the retry in a separate thread
        result_thread = Thread.new do
          described_class.execute_with_retries(command, max_retries: 3, retry_delay: 0.001)
        end

        # Create the flag file after a short delay to simulate eventual success
        sleep(0.001)
        File.write(flag_file, "")

        result = result_thread.value
        expect(result.success?).to be true
      end
    end

    it "returns final failure result after all retries exhausted" do
      result = described_class.execute_with_retries("exit 1", max_retries: 2, retry_delay: 0.001)
      expect(result.success?).to be false
      expect(result.exit_code).to eq(1)
    end

    it "respects retry parameters" do
      # Mock sleep to capture calls instead of measuring real time
      sleep_calls = []
      allow(described_class).to receive(:sleep) { |duration| sleep_calls << duration }

      result = described_class.execute_with_retries("exit 1", max_retries: 2, retry_delay: 0.1, timeout: 1)

      expect(result.success?).to be false
      # Should have called sleep twice (2 retries)
      expect(sleep_calls.length).to eq(2)
      expect(sleep_calls).to all(eq(0.1))
    end
  end
end
