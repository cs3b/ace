# frozen_string_literal: true

# VCR setup for subprocess loading
# This file is loaded via RUBYOPT to enable VCR in subprocess calls

require 'vcr'
require 'webmock'

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("cassettes", __dir__)
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }

  # Configure to handle Gemini API
  config.filter_sensitive_data('<GEMINI_API_KEY>') { ENV['GEMINI_API_KEY'] }

  # Allow localhost connections for tests
  config.ignore_localhost = false

  # Configure for test environment
  if ENV['VCR_RECORD'] == 'true'
    config.default_cassette_options[:record] = :all
  elsif ENV['CI']
    config.default_cassette_options[:record] = :none
  end
end

# Auto-insert cassette based on test context if available
if ENV['VCR_CASSETTE_NAME']
  VCR.insert_cassette(ENV['VCR_CASSETTE_NAME'])

  at_exit do
    VCR.eject_cassette if VCR.current_cassette
  end
end

# Enable WebMock
WebMock.enable!
