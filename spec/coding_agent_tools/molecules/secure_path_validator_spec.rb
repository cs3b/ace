# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe CodingAgentTools::Molecules::SecurePathValidator do
  let(:security_logger) { instance_double(CodingAgentTools::Atoms::SecurityLogger) }
  let(:validator) { described_class.new(security_logger: security_logger) }

  before do
    allow(security_logger).to receive(:log_event)
    allow(security_logger).to receive(:log_error)
  end

  describe "#initialize" do
    it "uses default configuration when none provided" do
      validator = described_class.new
      allowed_paths = validator.config[:allowed_base_paths]

      # Check that all expected default paths are included
      expected_defaults = [".", "/tmp", "/var/tmp", "/var/folders", "/private/tmp", "/private/var/tmp"]
      expected_defaults.each do |path|
        expect(allowed_paths).to include(path), "Expected #{path} to be in allowed_base_paths"
      end

      # Check that system temp directories are automatically added
      expect(allowed_paths.length).to be >= expected_defaults.length
      expect(validator.config[:denied_patterns]).to be_an(Array)
      expect(validator.config[:max_path_depth]).to eq(20)
    end

    it "merges custom configuration with defaults" do
      custom_config = {max_path_depth: 10, allowed_base_paths: ["/tmp"]}
      validator = described_class.new(config: custom_config)

      expect(validator.config[:max_path_depth]).to eq(10)

      allowed_paths = validator.config[:allowed_base_paths]
      # Custom paths should be included
      expect(allowed_paths).to include("/tmp")
      # System temp directories should be automatically added
      expect(allowed_paths.length).to be >= 1

      expect(validator.config[:denied_patterns]).to be_an(Array) # Still includes defaults
    end
  end

  describe "#validate_path" do
    context "with valid paths" do
      it "accepts relative paths in current directory" do
        result = validator.validate_path("./test.txt")

        expect(result.valid?).to be true
        expect(result.sanitized_path).to eq("test.txt")
        expect(result.error_type).to be_nil
      end

      it "accepts nested relative paths" do
        result = validator.validate_path("output/result.json")

        expect(result.valid?).to be true
        expect(result.sanitized_path).to eq("output/result.json")
      end

      it "normalizes paths with redundant components that stay within allowed paths" do
        result = validator.validate_path("./output/./test.txt")

        expect(result.valid?).to be true
        expect(result.sanitized_path).to eq("output/test.txt")
      end

      it "handles symlinks within the current directory" do
        # Test that symlinks within the current directory are properly resolved
        # We'll create the symlink in a subdirectory of the current directory
        test_dir = "./test_symlinks"
        FileUtils.mkdir_p(test_dir)

        begin
          original_file = File.join(test_dir, "original.txt")
          File.write(original_file, "test content")

          symlink_file = File.join(test_dir, "symlink.txt")
          File.symlink(original_file, symlink_file)

          result = validator.validate_path(symlink_file)
          expect(result.valid?).to be true
          # Symlinks may or may not be resolved depending on file existence
          # At minimum, the result should be valid and contain a reasonable path
          expect(result.sanitized_path).not_to be_empty
        ensure
          FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
        end
      end
    end

    context "with invalid paths" do
      it "rejects empty paths" do
        result = validator.validate_path("")

        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:empty_path)
        expect(result.error_message).to include("empty")
      end

      it "rejects nil paths" do
        result = validator.validate_path(nil)

        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:empty_path)
      end

      it "rejects paths with null bytes" do
        result = validator.validate_path("test\x00file.txt")

        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:null_byte)
        expect(security_logger).to have_received(:log_event).with(:path_traversal_attempt, anything)
      end

      it "rejects paths that are too long" do
        long_path = "a" * 5000
        result = validator.validate_path(long_path)

        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:path_too_long)
        expect(security_logger).to have_received(:log_event).with(:invalid_path, anything)
      end

      it "rejects paths with control characters" do
        result = validator.validate_path("test\x01file.txt")

        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:invalid_characters)
        expect(security_logger).to have_received(:log_event).with(:invalid_path, anything)
      end

      it "rejects paths that are too deep" do
        deep_path = (["dir"] * 25).join("/")
        result = validator.validate_path(deep_path)

        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:path_too_deep)
        expect(security_logger).to have_received(:log_event).with(:invalid_path, anything)
      end
    end

    context "with path traversal attacks" do
      let(:attack_vectors) do
        [
          "../../../etc/passwd",
          '..\\..\\..\\windows\\system32\\config\\sam',
          "test/../../../etc/shadow",
          "normal/../../etc/hosts",
          "..%2f..%2f..%2fetc%2fpasswd",
          "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd"
        ]
      end

      it "blocks classic directory traversal patterns" do
        attack_vectors.each do |attack_path|
          result = validator.validate_path(attack_path)

          expect(result.invalid?).to be(true), "Failed to block: #{attack_path}"
          expect(result.error_type).to eq(:path_traversal)
        end

        # Verify that path traversal events were logged (at least one for each attack)
        expect(security_logger).to have_received(:log_event).with(:path_traversal_attempt, anything).at_least(:once)
      end

      it "blocks relative paths that escape current directory" do
        result = validator.validate_path("../outside.txt")

        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:path_traversal)
        expect(security_logger).to have_received(:log_event).with(:path_traversal_attempt, anything)
      end
    end

    context "with denied patterns" do
      it "blocks system directories" do
        system_paths = [
          "/etc/passwd",
          "/usr/bin/bash",
          "/var/log/syslog",
          "/proc/version",
          "/sys/devices",
          "/dev/null",
          "/root/.bashrc"
        ]

        system_paths.each do |system_path|
          result = validator.validate_path(system_path)

          expect(result.invalid?).to be(true), "Failed to block: #{system_path}"
          expect(result.error_type).to eq(:denied_pattern)
        end

        # Verify that denied access events were logged (at least one for each system path)
        expect(security_logger).to have_received(:log_event).with(:denied_access, anything).at_least(:once)
      end

      it "blocks .git directories" do
        git_paths = [
          ".git/config",
          "project/.git/hooks/pre-commit",
          "/home/user/repo/.git/objects/abc123"
        ]

        git_paths.each do |git_path|
          result = validator.validate_path(git_path)

          expect(result.invalid?).to be(true), "Failed to block: #{git_path}"
          expect(result.error_type).to eq(:denied_pattern)
        end
      end

      it "blocks sensitive config directories" do
        sensitive_paths = [
          ".ssh/id_rsa",
          ".aws/credentials",
          ".gem/credentials"
        ]

        sensitive_paths.each do |sensitive_path|
          result = validator.validate_path(sensitive_path)

          expect(result.invalid?).to be(true), "Failed to block: #{sensitive_path}"
          expect(result.error_type).to eq(:denied_pattern)
        end
      end
    end

    context "with allowed base paths" do
      it "allows paths within current directory by default" do
        result = validator.validate_path("subdir/file.txt")
        expect(result.valid?).to be true
      end

      it "respects custom allowed base paths" do
        custom_validator = described_class.new(
          config: {allowed_base_paths: ["/tmp"]},
          security_logger: security_logger
        )

        result = custom_validator.validate_path("/tmp/test.txt")
        expect(result.valid?).to be true

        result = custom_validator.validate_path("/home/test.txt")
        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:outside_allowed_paths)
      end

      it "handles multiple allowed base paths" do
        custom_validator = described_class.new(
          config: {allowed_base_paths: ["/tmp", "/var/tmp"]},
          security_logger: security_logger
        )

        result1 = custom_validator.validate_path("/tmp/file1.txt")
        expect(result1.valid?).to be true

        result2 = custom_validator.validate_path("/var/tmp/file2.txt")
        expect(result2.valid?).to be true

        result3 = custom_validator.validate_path("/etc/passwd")
        expect(result3.invalid?).to be true
      end
    end

    context "with operation context" do
      it "logs operation type in metadata" do
        validator.validate_path("test.txt", operation: :write)

        expect(security_logger).to have_received(:log_event).with(:file_operation,
          hash_including(metadata: hash_including(operation: :write)))
      end

      it "handles different operation types" do
        [:read, :write, :execute].each do |operation|
          validator.validate_path("test.txt", operation: operation)

          expect(security_logger).to have_received(:log_event).with(:file_operation,
            hash_including(metadata: hash_including(operation: operation)))
        end
      end
    end

    context "with error handling" do
      it "handles validation errors gracefully" do
        # Force an error by mocking Pathname to raise
        allow(Pathname).to receive(:new).and_raise(StandardError.new("Mocked error"))

        result = validator.validate_path("test.txt")

        expect(result.invalid?).to be true
        expect(result.error_type).to eq(:validation_error)
        expect(security_logger).to have_received(:log_error)
      end
    end
  end

  describe "#safe_path?" do
    it "returns true for valid paths" do
      expect(validator.safe_path?("test.txt")).to be true
    end

    it "returns false for invalid paths" do
      expect(validator.safe_path?("../../../etc/passwd")).to be false
    end

    it "accepts operation parameter" do
      expect(validator.safe_path?("test.txt", :write)).to be true
      expect(validator.safe_path?("../../../etc/passwd", :read)).to be false
    end
  end

  describe "ValidationResult" do
    it "provides convenience methods" do
      valid_result = described_class::ValidationResult.new(true, "path", nil, nil)
      expect(valid_result.valid?).to be true
      expect(valid_result.invalid?).to be false

      invalid_result = described_class::ValidationResult.new(false, nil, :error, "message")
      expect(invalid_result.valid?).to be false
      expect(invalid_result.invalid?).to be true
    end
  end

  describe "default configuration" do
    it "includes expected denied patterns" do
      patterns = described_class::DEFAULT_CONFIG[:denied_patterns]

      # Test that common attack vectors are covered
      expect(patterns.any? { |p| "/etc/passwd".match?(p) }).to be true
      expect(patterns.any? { |p| "/usr/bin/bash".match?(p) }).to be true
      expect(patterns.any? { |p| ".git/config".match?(p) }).to be true
      expect(patterns.any? { |p| ".ssh/id_rsa".match?(p) }).to be true
    end

    it "has reasonable limits" do
      config = described_class::DEFAULT_CONFIG

      expect(config[:max_path_depth]).to be > 0
      expect(config[:max_path_length]).to be > 100
      expect(config[:allowed_base_paths]).not_to be_empty
    end
  end
end
