#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "coding_agent_tools"

# Example: Using APICredentials as a generic credential manager
# Now APICredentials doesn't know about any specific service (like Gemini)

puts "=== Generic API Credentials Example ==="
puts

# Example 1: Using APICredentials for different services
puts "1. Creating credentials for different services:"

# For Gemini API
gemini_credentials = CodingAgentTools::Molecules::APICredentials.new(
  env_key_name: "GEMINI_API_KEY"
)

# For OpenAI API
openai_credentials = CodingAgentTools::Molecules::APICredentials.new(
  env_key_name: "OPENAI_API_KEY"
)

# For a custom service
custom_credentials = CodingAgentTools::Molecules::APICredentials.new(
  env_key_name: "MY_SERVICE_API_KEY"
)

puts "✓ Created credential managers for multiple services"
puts

# Example 2: Checking if keys are present
puts "2. Checking API key availability:"
puts "   Gemini API key present: #{gemini_credentials.api_key_present?}"
puts "   OpenAI API key present: #{openai_credentials.api_key_present?}"
puts "   Custom API key present: #{custom_credentials.api_key_present?}"
puts

# Example 3: Using with GeminiClient (now specifies its own key name)
puts "3. GeminiClient now specifies its own API key environment variable:"
begin
  # GeminiClient internally creates APICredentials with "GEMINI_API_KEY"
  client = CodingAgentTools::Organisms::GeminiClient.new
  puts "✓ GeminiClient initialized successfully"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Example 4: Custom API key environment variable for GeminiClient
puts "4. Using custom environment variable with GeminiClient:"
begin
  # You can override the default GEMINI_API_KEY with a custom one
  custom_client = CodingAgentTools::Organisms::GeminiClient.new(
    api_key_env: "MY_CUSTOM_GEMINI_KEY"
  )
  puts "✓ GeminiClient initialized with custom env variable"
rescue => e
  puts "✗ Error: #{e.message}"
end
puts

# Example 5: Configuration precedence
puts "5. Demonstrating configuration precedence:"

# Configure a key programmatically
CodingAgentTools::Molecules::APICredentials.configure do |config|
  config["DEMO_API_KEY"] = "configured-key-123"
end

demo_credentials = CodingAgentTools::Molecules::APICredentials.new(
  env_key_name: "DEMO_API_KEY"
)

puts "   Configured key: #{demo_credentials.api_key}"
puts "   With prefix: #{demo_credentials.api_key_with_prefix('Bearer ')}"

# Clean up
CodingAgentTools::Molecules::APICredentials.reset!
puts

# Example 6: Error handling for missing env_key_name
puts "6. Error handling when env_key_name not provided:"
begin
  no_key_credentials = CodingAgentTools::Molecules::APICredentials.new
  no_key_credentials.api_key
rescue KeyError => e
  puts "✓ Expected error: #{e.message}"
end
puts

puts "=== Summary ==="
puts "APICredentials is now a generic credential manager that:"
puts "- Doesn't assume any specific service (no more GEMINI_API_KEY default)"
puts "- Requires env_key_name to be specified for API key operations"
puts "- Can be used by any service-specific client (like GeminiClient)"
puts "- Service clients (organisms) now own their configuration details"
