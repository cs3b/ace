# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe CodingAgentTools::Atoms::SecurityLogger do
  let(:log_output) { StringIO.new }
  let(:test_logger) { Logger.new(log_output) }
  let(:security_logger) { described_class.new(logger: test_logger) }

  describe "#initialize" do
    it "uses provided logger" do
      expect(security_logger.logger).to eq(test_logger)
    end

    it "creates default logger when none provided" do
      default_logger = described_class.new
      expect(default_logger.logger).to be_a(Logger)
      expect(default_logger.logger.progname).to eq("CodingAgentTools::Security")
    end
  end

  describe "#log_event" do
    it "logs path traversal attempts as warnings" do
      security_logger.log_event(:path_traversal_attempt, path: "../../../etc/passwd")

      log_output.rewind
      output = log_output.read
      expect(output).to include("[PATH_TRAVERSAL]")
      expect(output).to include("WARN")
      expect(output).to include("[hidden]/etc/passwd")
    end

    it "logs denied access as warnings" do
      security_logger.log_event(:denied_access, path: "/etc/shadow", reason: "Outside allowlist")

      log_output.rewind
      output = log_output.read
      expect(output).to include("[DENIED_ACCESS]")
      expect(output).to include("WARN")
      expect(output).to include("reason=Outside allowlist")
    end

    it "logs invalid paths as info" do
      security_logger.log_event(:invalid_path, path: "some/path", reason: "Contains null byte")

      log_output.rewind
      output = log_output.read
      expect(output).to include("[INVALID_PATH]")
      expect(output).to include("INFO")
      expect(output).to include("path=some/path") # relative path shown as-is
    end

    it "logs file operations as debug" do
      security_logger.log_event(:file_operation, path: "output.txt", metadata: {action: "write"})

      log_output.rewind
      output = log_output.read
      expect(output).to include("[FILE_OPERATION]")
      expect(output).to include("DEBUG")
      expect(output).to include("metadata={action: write}")
    end

    it "handles unknown event types" do
      security_logger.log_event(:unknown_event, details: "test")

      log_output.rewind
      output = log_output.read
      expect(output).to include("[UNKNOWN_EVENT]")
    end
  end

  describe "#log_error" do
    it "logs errors with sanitized messages" do
      error = StandardError.new("Failed to access /home/user/secret_key_abc123xyz.pem")
      security_logger.log_error(error, path: "/home/user/file.txt")

      log_output.rewind
      output = log_output.read
      expect(output).to include("[SECURITY_ERROR]")
      expect(output).to include("StandardError")
      expect(output).to include("[REDACTED]") # sanitized key
      expect(output).to include("path=[hidden]/user/file.txt") # sanitized path outside current dir
    end

    it "logs errors without context" do
      error = RuntimeError.new("Something went wrong")
      security_logger.log_error(error)

      log_output.rewind
      output = log_output.read
      expect(output).to include("[SECURITY_ERROR]")
      expect(output).to include("RuntimeError")
      expect(output).not_to include("Context:")
    end
  end

  describe "path sanitization" do
    it "sanitizes home directory paths" do
      home = ENV["HOME"]
      security_logger.log_event(:file_operation, path: "#{home}/documents/file.txt")

      log_output.rewind
      output = log_output.read
      expect(output).to include("path=~/documents/file.txt")
      expect(output).not_to include(home)
    end

    it "hides absolute paths outside current directory" do
      security_logger.log_event(:denied_access, path: "/usr/local/bin/secret")

      log_output.rewind
      output = log_output.read
      expect(output).to include("path=[hidden]/bin/secret")
      expect(output).not_to include("/usr/local")
    end

    it "shows relative paths as-is" do
      security_logger.log_event(:file_operation, path: "./output/result.json")

      log_output.rewind
      output = log_output.read
      expect(output).to include("path=./output/result.json")
    end

    it "shows paths within current directory" do
      current_file = File.join(Dir.pwd, "test.txt")
      security_logger.log_event(:file_operation, path: current_file)

      log_output.rewind
      output = log_output.read
      # Within current directory, absolute paths are sanitized to show home-relative
      expect(output).to include("path=~/Projects/coding-agent-tools/test.txt")
    end

    it "handles empty paths" do
      security_logger.log_event(:invalid_path, path: "")

      log_output.rewind
      output = log_output.read
      expect(output).to include("path=(empty)")
    end

    it "sanitizes multiple paths" do
      paths = ["/etc/passwd", "#{ENV["HOME"]}/file", "./local"]
      security_logger.log_event(:denied_access, paths: paths)

      log_output.rewind
      output = log_output.read
      expect(output).to include("paths=[[hidden]/etc/passwd, ~/file, ./local]")
    end
  end

  describe "message sanitization" do
    it "redacts potential API keys" do
      security_logger.log_event(:denied_access,
        reason: "Invalid API key: sk_test_abcdef123456789012345678901234567890")

      log_output.rewind
      output = log_output.read
      expect(output).to include("reason=Invalid API key: [REDACTED]")
      expect(output).not_to include("sk_test_abcdef123456789012345678901234567890")
    end

    it "hides email addresses" do
      security_logger.log_event(:invalid_path,
        reason: "User test@example.com attempted access")

      log_output.rewind
      output = log_output.read
      expect(output).to include("reason=User [EMAIL] attempted access")
      expect(output).not_to include("test@example.com")
    end

    it "hides IP addresses" do
      security_logger.log_event(:denied_access,
        reason: "Request from 192.168.1.100 denied")

      log_output.rewind
      output = log_output.read
      expect(output).to include("reason=Request from [IP] denied")
      expect(output).not_to include("192.168.1.100")
    end
  end

  describe "event types" do
    described_class::EVENTS.each do |event_symbol, event_name|
      it "supports #{event_symbol} event" do
        security_logger.log_event(event_symbol, path: "test.txt")

        log_output.rewind
        output = log_output.read
        expect(output).to include("[#{event_name}]")
      end
    end
  end

  describe "log formatting" do
    it "formats nested metadata correctly" do
      metadata = {
        action: "write",
        details: {
          size: 1024,
          format: "json"
        }
      }
      security_logger.log_event(:file_operation, metadata: metadata)

      log_output.rewind
      output = log_output.read
      # The format might include quotes around strings in nested hashes
      expect(output).to include("metadata={action: write, details: {size: 1024, format:")
      expect(output).to include("json")
    end

    it "includes timestamp in default logger format" do
      # Test with a custom logger that has a visible output
      default_logger_io = StringIO.new
      default_logger = described_class.new(logger: Logger.new(default_logger_io))

      default_logger.log_event(:file_operation, path: "test.txt")

      default_logger_io.rewind
      output = default_logger_io.read
      expect(output).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(output).to include("[FILE_OPERATION]")
    end
  end
end
