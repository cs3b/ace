#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'json'
require 'webmock'

# Helper to migrate VCR cassettes to WebMock stubs
# Usage: ruby spec/support/vcr_migration_helper.rb spec/cassettes/sample.yml
class VCRMigrationHelper
  attr_reader :cassette_path, :output_path

  def initialize(cassette_path, output_path = nil)
    @cassette_path = cassette_path
    @output_path = output_path || cassette_path.sub('.yml', '_webmock.rb')
  end

  def migrate!
    cassette_data = load_cassette
    webmock_stubs = convert_to_webmock(cassette_data)
    write_webmock_file(webmock_stubs)
    
    puts "Successfully migrated #{cassette_path} to #{output_path}"
    puts "Generated #{webmock_stubs.size} WebMock stubs"
  end

  private

  def load_cassette
    if cassette_path.end_with?('.yml')
      YAML.load_file(cassette_path)
    elsif cassette_path.end_with?('.json')
      JSON.parse(File.read(cassette_path))
    else
      raise ArgumentError, "Unsupported cassette format: #{cassette_path}"
    end
  rescue StandardError => e
    raise "Failed to load cassette: #{e.message}"
  end

  def convert_to_webmock(cassette_data)
    http_interactions = cassette_data['http_interactions'] || []
    
    http_interactions.map do |interaction|
      request = interaction['request']
      response = interaction['response']
      
      stub_data = {
        method: request['method'].downcase.to_sym,
        uri: build_uri_matcher(request),
        request_body: request['body']['string'] if request['body'],
        request_headers: normalize_headers(request['headers']),
        response_status: response['status']['code'],
        response_body: response['body']['string'],
        response_headers: normalize_headers(response['headers'])
      }
      
      generate_webmock_stub(stub_data)
    end
  end

  def build_uri_matcher(request)
    uri = request['uri']
    
    # Handle query parameters if present
    if uri.include?('?')
      base_uri, query_string = uri.split('?', 2)
      query_params = URI.decode_www_form(query_string).to_h
      
      # Return hash format for WebMock with query parameters
      { uri: base_uri, query: query_params }
    else
      uri
    end
  end

  def normalize_headers(headers)
    return {} unless headers
    
    # Convert array format to hash format
    normalized = {}
    headers.each do |key, values|
      normalized[key] = Array(values).join(', ')
    end
    normalized
  end

  def generate_webmock_stub(stub_data)
    stub_code = []
    
    # Start stub definition
    stub_code << "stub_request(:#{stub_data[:method]}, "
    
    # Add URI
    if stub_data[:uri].is_a?(Hash)
      stub_code << "  \"#{stub_data[:uri][:uri]}\")"
      stub_code << "  .with("
      stub_code << "    query: #{stub_data[:uri][:query].inspect},"
    else
      stub_code << "  \"#{stub_data[:uri]}\")"
      stub_code << "  .with("
    end
    
    # Add request details
    if stub_data[:request_body]
      stub_code << "    body: #{stub_data[:request_body].inspect},"
    end
    
    if stub_data[:request_headers] && !stub_data[:request_headers].empty?
      stub_code << "    headers: {"
      stub_data[:request_headers].each do |key, value|
        stub_code << "      '#{key}' => '#{value}',"
      end
      stub_code[-1] = stub_code[-1].chomp(',')
      stub_code << "    }"
    end
    
    # Remove trailing comma and close with()
    stub_code[-1] = stub_code[-1].chomp(',')
    stub_code << "  )"
    
    # Add response
    stub_code << "  .to_return("
    stub_code << "    status: #{stub_data[:response_status]},"
    stub_code << "    body: #{stub_data[:response_body].inspect},"
    
    if stub_data[:response_headers] && !stub_data[:response_headers].empty?
      stub_code << "    headers: {"
      stub_data[:response_headers].each do |key, value|
        stub_code << "      '#{key}' => '#{value}',"
      end
      stub_code[-1] = stub_code[-1].chomp(',')
      stub_code << "    }"
    end
    
    stub_code << "  )"
    
    stub_code.join("\n")
  end

  def write_webmock_file(stubs)
    File.open(output_path, 'w') do |file|
      file.puts "# frozen_string_literal: true"
      file.puts
      file.puts "# WebMock stubs migrated from VCR cassette: #{File.basename(cassette_path)}"
      file.puts "# Generated on: #{Time.now}"
      file.puts
      file.puts "require 'webmock/rspec'"
      file.puts
      file.puts "# Define WebMock stubs"
      file.puts "def setup_webmock_stubs"
      
      stubs.each_with_index do |stub, index|
        file.puts "  # Stub #{index + 1}"
        file.puts "  #{stub.gsub("\n", "\n  ")}"
        file.puts
      end
      
      file.puts "end"
    end
  end
end

# Command-line interface
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: #{$0} <cassette_file> [output_file]"
    puts "Example: #{$0} spec/cassettes/google_api.yml"
    exit 1
  end
  
  cassette_file = ARGV[0]
  output_file = ARGV[1]
  
  unless File.exist?(cassette_file)
    puts "Error: Cassette file not found: #{cassette_file}"
    exit 1
  end
  
  begin
    helper = VCRMigrationHelper.new(cassette_file, output_file)
    helper.migrate!
  rescue StandardError => e
    puts "Error: #{e.message}"
    exit 1
  end
end