# frozen_string_literal: true

# Shared examples for testing path traversal attack prevention
# Usage: include_examples "path traversal attack prevention", validator_instance

RSpec.shared_examples "path traversal attack prevention" do |validator|
  # Classic directory traversal attack vectors
  let(:attack_vectors) do
    [
      # Basic directory traversal
      "../../../etc/passwd",
      '..\\..\\..\\windows\\system32\\config\\sam',

      # Encoded attacks
      "..%2f..%2f..%2fetc%2fpasswd",
      "..%5c..%5c..%5cwindows%5csystem32%5cconfig%5csam",
      "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd",
      "%2e%2e%5c%2e%2e%5c%2e%2e%5cwindows%5csystem32",

      # Double encoding
      "%252e%252e%252f%252e%252e%252f%252e%252e%252fetc%252fpasswd",

      # Unicode variants
      "\u002e\u002e\u002f\u002e\u002e\u002f\u002e\u002e\u002fetc\u002fpasswd",

      # Mixed with valid path components
      "uploads/../../../etc/passwd",
      "files/../../etc/shadow",
      "documents/../../var/log/auth.log",

      # Absolute paths to sensitive files
      "/etc/passwd",
      "/etc/shadow",
      "/var/log/auth.log",
      "/proc/version",
      "/sys/devices",
      "/dev/null",
      "/root/.ssh/id_rsa",
      "/root/.bash_history",

      # Windows specific
      'c:\\windows\\system32\\config\\sam',
      'c:\\windows\\system32\\drivers\\etc\\hosts',
      'c:\\boot.ini',

      # Home directory attacks
      "~/.ssh/id_rsa",
      "~/.aws/credentials",
      "~/.bash_history",

      # Git repository access
      ".git/config",
      ".git/HEAD",
      "../.git/config",
      "../../.git/hooks/pre-commit",

      # Other sensitive files
      ".env",
      ".aws/credentials",
      ".ssh/config",
      ".gem/credentials",

      # Long traversal sequences
      ("../" * 20) + "etc/passwd",
      ("../" * 50) + "var/log/messages"
    ]
  end

  it "blocks all common path traversal attack vectors" do
    attack_vectors.each do |attack_path|
      result = validator.validate_path(attack_path)

      expect(result.invalid?).to be true,
        "Expected '#{attack_path}' to be blocked but it was allowed"

      # Should be blocked for either path traversal or denied pattern
      expect([:path_traversal, :denied_pattern, :outside_allowed_paths]).to include(result.error_type),
        "Attack path '#{attack_path}' was blocked with unexpected error type: #{result.error_type}"
    end
  end

  it "provides meaningful error messages for blocked attacks" do
    attack_vectors.first(5).each do |attack_path|
      result = validator.validate_path(attack_path)

      expect(result.error_message).not_to be_nil
      expect(result.error_message).not_to be_empty
      expect(result.error_message).to be_a(String)
    end
  end

  it "logs security events for attack attempts" do
    # This example assumes the validator has a security logger
    # Skip if no logger is available
    next unless validator.respond_to?(:security_logger)

    logger = validator.security_logger
    allow(logger).to receive(:log_event)

    # Test first few attack vectors
    attack_vectors.first(3).each do |attack_path|
      validator.validate_path(attack_path)
    end

    # Should have logged at least some security events
    expect(logger).to have_received(:log_event).at_least(:once)
  end
end

# Shared examples for testing safe path acceptance
RSpec.shared_examples "safe path acceptance" do |validator|
  let(:safe_paths) do
    [
      # Relative paths within current directory
      "output.txt",
      "results/data.json",
      "documents/report.md",
      "./file.txt",
      "subdir/nested/file.txt",

      # Files with various extensions
      "data.csv",
      "config.yaml",
      "script.rb",
      "image.png",
      "document.pdf",

      # Paths with special characters (but safe)
      "file-with-dashes.txt",
      "file_with_underscores.txt",
      "file.with.dots.txt",
      "file (with spaces).txt",
      "file123.txt",

      # Current directory reference
      ".",
      "./"
    ]
  end

  it "allows safe relative paths" do
    safe_paths.each do |safe_path|
      result = validator.validate_path(safe_path)

      expect(result.valid?).to be true,
        "Expected '#{safe_path}' to be allowed but it was blocked: #{result.error_message}"
    end
  end

  it "provides sanitized paths for safe inputs" do
    safe_paths.each do |safe_path|
      result = validator.validate_path(safe_path)

      if result.valid?
        expect(result.sanitized_path).not_to be_nil
        expect(result.sanitized_path).not_to be_empty
      end
    end
  end
end

# Shared examples for testing path normalization
RSpec.shared_examples "path normalization" do |validator|
  let(:normalization_cases) do
    [
      # Input path -> Expected normalized result pattern
      ["./file.txt", "file.txt"],
      ["subdir/./file.txt", /subdir\/file\.txt/],
      ["dir//file.txt", /dir\/file\.txt/],
      ["  ./file.txt  ", "file.txt"]  # whitespace trimming
    ]
  end

  it "normalizes paths correctly" do
    normalization_cases.each do |input_path, expected_pattern|
      result = validator.validate_path(input_path)

      next unless result.valid?  # Skip if path is invalid for other reasons

      if expected_pattern.is_a?(String)
        expect(result.sanitized_path).to end_with(expected_pattern)
      else
        expect(result.sanitized_path).to match(expected_pattern)
      end
    end
  end
end
