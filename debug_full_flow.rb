#!/usr/bin/env ruby
# Debug the full code-review flow

require_relative "dev-tools/lib/coding_agent_tools"

puts "=== Debugging full code-review workflow ==="

# Step 1: Parse the YAML input like ReviewPresetManager does
puts "\n1. Testing ReviewPresetManager.parse_context_yaml:"
manager = CodingAgentTools::Molecules::Code::ReviewPresetManager.new
yaml_input = 'presets: [project, dev-tools]'
parsed_context = manager.send(:parse_context_yaml, yaml_input)
puts "Input: #{yaml_input}"
puts "Parsed: #{parsed_context.inspect}"
puts "Class: #{parsed_context.class}"

# Step 2: Test ContextIntegrator with the parsed input
puts "\n2. Testing ContextIntegrator.generate_context:"
integrator = CodingAgentTools::Molecules::Code::ContextIntegrator.new

begin
  context_content = integrator.generate_context(parsed_context)
  puts "Context content size: #{context_content.bytesize} bytes"
  puts "Content starts with: #{context_content[0..100]}..."
  
  if context_content.empty?
    puts "❌ ERROR: Context content is empty!"
  else
    puts "✅ SUCCESS: Context content generated"
  end
rescue => e
  puts "❌ ERROR: #{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

# Step 3: Test with a simple string context for comparison
puts "\n3. Testing with string context for comparison:"
begin
  simple_context = integrator.generate_context("project")
  puts "Simple context size: #{simple_context.bytesize} bytes"
  puts "Simple context starts with: #{simple_context[0..100]}..."
rescue => e
  puts "❌ ERROR with simple context: #{e.class}: #{e.message}"
end