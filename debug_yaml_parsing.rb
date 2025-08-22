#!/usr/bin/env ruby
# Debug YAML parsing

require 'yaml'
require_relative "dev-tools/lib/coding_agent_tools"

puts "=== Testing YAML parsing directly ==="

input = 'presets: [project, dev-tools]'
puts "Input: #{input.inspect}"

# Test with YAML.safe_load directly
puts "\nDirect YAML.safe_load:"
begin
  result = YAML.safe_load(input)
  puts "Result: #{result.inspect}"
  puts "Class: #{result.class}"
rescue => e
  puts "Error: #{e}"
end

# Test the ReviewPresetManager method
puts "\nReviewPresetManager.parse_context_yaml:"
manager = CodingAgentTools::Molecules::Code::ReviewPresetManager.new
result = manager.send(:parse_context_yaml, input)
puts "Result: #{result.inspect}"
puts "Class: #{result.class}"

# Test resolve_context_config
puts "\nReviewPresetManager.resolve_context_config:"
result = manager.send(:resolve_context_config, nil, input)
puts "Result: #{result.inspect}"
puts "Class: #{result.class}"