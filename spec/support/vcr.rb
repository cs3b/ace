# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  # Set the directory where cassettes will be stored
  config.cassette_library_dir = "spec/cassettes"

  # Use WebMock as the HTTP stubbing library
  config.hook_into :webmock

  # Register custom request matcher for dynamic content
  config.register_request_matcher :body_without_dynamic_paths do |request_1, request_2|
    if request_1.body && request_2.body
      # Normalize dynamic file paths before comparing
      normalized_body_1 = request_1.body.gsub(/\/tmp\/does_not_exist_\d+\.txt/, '/tmp/does_not_exist_XXXX.txt')
      normalized_body_2 = request_2.body.gsub(/\/tmp\/does_not_exist_\d+\.txt/, '/tmp/does_not_exist_XXXX.txt')
      normalized_body_1 == normalized_body_2
    else
      request_1.body == request_2.body
    end
  end

  # Configure how requests are matched
  config.default_cassette_options = {
    match_requests_on: [:method, :uri, :headers, :body_without_dynamic_paths],
    serialize_with: :json,
    decode_compressed_response: true
  }

  # Sensitive data filtering - remove API keys from recorded cassettes
  config.filter_sensitive_data("<GEMINI_API_KEY>") do |interaction|
    interaction.request.headers["X-Goog-Api-Key"]&.first
  end

  # Also filter API keys from query parameters
  config.filter_sensitive_data("<GEMINI_API_KEY>") do |interaction|
    if interaction.request.uri.include?("key=")
      URI.parse(interaction.request.uri).query&.split("&")&.find { |param| param.start_with?("key=") }&.split("=")&.last
    end
  end

  # Filter Anthropic API keys
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") do |interaction|
    interaction.request.headers["X-Api-Key"]&.first
  end

  # Filter Authorization headers if present
  config.filter_sensitive_data("<AUTHORIZATION>") do |interaction|
    interaction.request.headers["Authorization"]&.first
  end

  # CI-aware recording mode
  # In CI: never record (use existing cassettes only)
  # In development: record missing cassettes automatically
  # Override with VCR_RECORD environment variable if needed
  recording_mode = if ENV["CI"]
    :none
  else
    case ENV["VCR_RECORD"]
    when "true", "1", "all"
      :all
    when "new_episodes", "new"
      :new_episodes
    when "none", "false", "0"
      :none
    else
      :once
    end
  end

  config.default_cassette_options[:record] = recording_mode

  # Allow connections to localhost (for test servers if needed)
  config.ignore_localhost = true

  # Configure what to do when no cassette is inserted
  # Allow connections when recording, disallow in CI or when explicitly disabled
  config.allow_http_connections_when_no_cassette = !ENV["CI"] && ENV["VCR_RECORD"] != "none"

  # Debug output for troubleshooting (enabled in debug mode)
  if ENV["TEST_DEBUG"] == "true"
    config.debug_logger = File.open("vcr_debug.log", "w")
  end

  # Configure before_record hook to clean up responses
  config.before_record do |interaction|
    # Remove any timestamps or dynamic data that might cause issues
    if interaction.response.body
      # Clean up any dynamic timestamps in the response
      interaction.response.body.gsub!(/"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?"/, '"2024-01-01T00:00:00Z"')

      # Clean up any request IDs or similar dynamic data
      interaction.response.body.gsub!(/"id":\s*"[^"]*"/, '"id": "test-id"')
    end

    # Clean up request timestamps and dynamic file paths
    if interaction.request.body
      interaction.request.body.gsub!(/"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?"/, '"2024-01-01T00:00:00Z"')
      # Normalize random file paths like /tmp/does_not_exist_1234.txt
      interaction.request.body.gsub!(/\/tmp\/does_not_exist_\d+\.txt/, '/tmp/does_not_exist_XXXX.txt')
    end
  end

  # Configure error handling
  config.preserve_exact_body_bytes do |http_message|
    # Preserve binary data for specific content types
    http_message.headers["Content-Type"]&.any? { |ct| ct.include?("application/octet-stream") }
  end
end

# RSpec configuration for VCR
RSpec.configure do |config|
  # Automatically insert cassettes based on example metadata
  config.around(:each, :vcr) do |example|
    # Use the test name as the cassette name, sanitized for filesystem
    cassette_name = if example.metadata[:vcr].is_a?(String)
      example.metadata[:vcr]
    else
      # Create a more readable cassette name
      test_path = example.example_group.description
      test_name = example.description
      "#{test_path}/#{test_name}".gsub(/[^\w\-_\/]/, "_").squeeze("_")
    end

    # Allow custom VCR options from test metadata
    cassette_options = {}
    if example.metadata[:vcr_options].is_a?(Hash)
      cassette_options.merge!(example.metadata[:vcr_options])
    end

    VCR.use_cassette(cassette_name, cassette_options) do
      example.run
    end
  end

  # Configure WebMock to allow VCR to handle HTTP requests
  config.before(:suite) do
    WebMock.enable!

    # Print recording mode info in debug mode
    if ENV["TEST_DEBUG"] == "true"
      mode_description = if ENV["CI"]
        "CI (cassettes only)"
      elsif ENV["VCR_RECORD"] == "true"
        "RECORDING all"
      elsif ENV["VCR_RECORD"] == "new_episodes"
        "RECORDING new episodes"
      else
        "PLAYBACK with auto-record"
      end
      puts "\n=== VCR Mode: #{mode_description} ==="
    end
  end

  config.after(:suite) do
    WebMock.disable!

    # Clean up debug log
    File.delete("vcr_debug.log") if File.exist?("vcr_debug.log") && ENV["TEST_DEBUG"] != "true"
  end
end

# Helper methods for tests
module VCRHelpers
  # Insert a cassette with custom options
  def with_vcr_cassette(name, options = {}, &block)
    VCR.use_cassette(name, options, &block)
  end

  # Record a new cassette (useful for updating API responses)
  def record_new_cassette(name, &block)
    VCR.use_cassette(name, record: :all, &block)
  end

  # Skip VCR for a specific test (allow real HTTP)
  def without_vcr(&block)
    VCR.turned_off(&block)
  end

  # Check if we're currently recording
  def recording_cassettes?
    !ENV["CI"] && ENV["VCR_RECORD"] == "true"
  end

  # Get the current API key (real or test)
  def current_api_key
    EnvHelper.gemini_api_key
  end

  # Skip test if recording but no real API key available
  def skip_if_no_api_key_for_recording
    if !ENV["CI"] && ENV["VCR_RECORD"] == "true" && !real_api_key_available?
      skip "Recording requires real GEMINI_API_KEY. Set it in spec/.env"
    end
  end

  private

  def real_api_key_available?
    key = ENV["GEMINI_API_KEY"]
    !key.nil? && !key.empty? && key != "your_actual_gemini_api_key_here" && key != "test-api-key-for-vcr-playback"
  end
end

# Include helpers in RSpec
RSpec.configure do |config|
  config.include VCRHelpers
end
