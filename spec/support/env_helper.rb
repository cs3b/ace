# frozen_string_literal: true

# Environment helper for loading test-specific environment variables
module EnvHelper
  # Load environment variables from .env files
  def self.load_test_env
    # Try to load from spec/.env first (test-specific)
    spec_env_path = File.expand_path("../.env", __dir__)
    root_env_path = File.expand_path("../../.env", __dir__)

    if File.exist?(spec_env_path)
      load_env_file(spec_env_path)
    elsif File.exist?(root_env_path)
      load_env_file(root_env_path)
    end
  end

  # Load environment variables from a specific file
  def self.load_env_file(file_path)
    return unless File.exist?(file_path)

    File.readlines(file_path).each do |line|
      line = line.strip
      # Skip empty lines and comments
      next if line.empty? || line.start_with?("#")

      # Parse KEY=VALUE format
      if line.include?("=")
        key, value = line.split("=", 2)
        key = key.strip
        value = value.strip

        # Remove quotes if present
        value = value.gsub(/^["']|["']$/, "")

        # Only set if not already set (allow override from actual environment)
        ENV[key] ||= value
      end
    end
  end

  # Get API key with fallback logic
  def self.gemini_api_key
    # In CI, always use test key
    return "test-api-key-for-vcr-playback" if ENV["CI"]

    # For explicit recording, require real API key
    if ENV["VCR_RECORD"] == "true"
      key = ENV["GEMINI_API_KEY"]
      if key.nil? || key.empty? || key == "your_actual_gemini_api_key_here"
        raise "Real GEMINI_API_KEY required for recording. Set it in spec/.env or environment."
      end
      return key
    end

    # For normal development, use real key if available, otherwise test key
    key = ENV["GEMINI_API_KEY"]
    if key && !key.empty? && key != "your_actual_gemini_api_key_here"
      key
    else
      "test-api-key-for-vcr-playback"
    end
  end

  # Check if debug mode is enabled
  def self.debug_mode?
    ENV["TEST_DEBUG"] == "true" || ENV["TEST_DEBUG"] == "1"
  end

  # Get test timeout
  def self.test_timeout
    (ENV["TEST_TIMEOUT"] || "30").to_i
  end

  # Setup environment for integration tests
  def self.setup_integration_env
    load_test_env

    # Enable debug output if requested
    if debug_mode?
      puts "Debug mode enabled"
      puts "CI mode: #{ENV['CI'] ? 'true' : 'false'}"
      puts "VCR Record mode: #{ENV['VCR_RECORD'] || 'default'}"
      puts "API Key available: #{ENV['GEMINI_API_KEY'] ? 'yes' : 'no'}"
    end
  end

  # Clean up environment after tests
  def self.cleanup_test_env
    # Reset test-specific environment variables
    test_vars = %w[GEMINI_API_KEY VCR_RECORD TEST_DEBUG TEST_TIMEOUT]

    test_vars.each do |var|
      # Only unset if it wasn't originally set
      if ENV["ORIGINAL_#{var}"]
        ENV[var] = ENV["ORIGINAL_#{var}"]
        ENV.delete("ORIGINAL_#{var}")
      else
        ENV.delete(var)
      end
    end
  end

  # Preserve original environment variables
  def self.preserve_original_env
    test_vars = %w[GEMINI_API_KEY VCR_RECORD TEST_DEBUG TEST_TIMEOUT]

    test_vars.each do |var|
      ENV["ORIGINAL_#{var}"] = ENV[var] if ENV[var]
    end
  end
end

# Auto-load environment when this file is required
EnvHelper.preserve_original_env
EnvHelper.setup_integration_env
