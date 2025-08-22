#!/usr/bin/env ruby
# Debug script for ContextIntegrator

require_relative "dev-tools/lib/coding_agent_tools"

puts "Testing ContextIntegrator directly..."

# Test what the ReviewPresetManager produces
preset_manager = CodingAgentTools::Molecules::Code::ReviewPresetManager.new
puts "\nTesting ReviewPresetManager.parse_context_yaml:"
yaml_input = 'presets: [project, dev-tools]'
parsed = preset_manager.send(:parse_context_yaml, yaml_input)
puts "Input: #{yaml_input}"
puts "Parsed: #{parsed.inspect}"
puts "Class: #{parsed.class}"

# Test the ContextIntegrator with the parsed result
integrator = CodingAgentTools::Molecules::Code::ContextIntegrator.new
puts "\nTesting ContextIntegrator.generate_context:"
result = integrator.generate_context(parsed)
puts "Result size: #{result.bytesize} bytes"
puts "First 200 chars: #{result[0..200]}..."