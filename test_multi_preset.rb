#!/usr/bin/env ruby
# Quick test script for multi-preset context loading

require_relative "dev-tools/lib/coding_agent_tools"

# Test single preset
puts "Testing single preset..."
integrator = CodingAgentTools::Molecules::Code::ContextIntegrator.new
result_single = integrator.generate_context("project")
puts "Single preset result size: #{result_single.bytesize} bytes"

# Test multiple presets
puts "\nTesting multiple presets..."
multi_config = { "presets" => ["project", "dev-tools"] }
result_multi = integrator.generate_context(multi_config)
puts "Multi preset result size: #{result_multi.bytesize} bytes"

# Test presets + files
puts "\nTesting presets + files..."
mixed_config = {
  "presets" => ["dev-handbook"],
  "files" => ["CLAUDE.md"]
}
result_mixed = integrator.generate_context(mixed_config)
puts "Mixed preset + files result size: #{result_mixed.bytesize} bytes"

puts "\nAll tests completed successfully!"