#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for template auto-discovery feature

require 'fileutils'
require 'yaml'

# Navigate to ace-context directory
Dir.chdir('/Users/mc/Ps/ace-meta/ace-context')

# Load the ace-context library
$LOAD_PATH.unshift('lib')
require 'ace/context'

puts "=" * 60
puts "TEMPLATE AUTO-DISCOVERY TEST"
puts "=" * 60
puts

# Test 1: List presets including discovered ones
puts "Test 1: Listing all presets (configured + discovered)"
puts "-" * 40
presets = Ace::Context.list_presets
presets.each do |preset|
  source = preset[:discovered] ? "(discovered)" : "(configured)"
  puts "  #{preset[:name]} #{source}"
  puts "    Description: #{preset[:description]}"
  puts "    Template: #{preset[:template]}" if preset[:template]
  puts "    Output: #{preset[:output]}" if preset[:output]
  puts
end

puts "\nTotal presets found: #{presets.count}"
puts "-" * 40
puts

# Test 2: Create a test template with frontmatter
test_template = <<~TEMPLATE
---
description: Test context template with frontmatter
format: yaml
chunk_limit: 50000
tags: [test, demo]
---

# Test Context Template

This is a test template created for auto-discovery testing.

<context-tool-config>
files:
  - README.md
  - lib/**/*.rb
commands:
  - echo "Test command"
</context-tool-config>
TEMPLATE

test_path = 'docs/context/test-autodiscovery.md'
FileUtils.mkdir_p(File.dirname(test_path))
File.write(test_path, test_template)

puts "Test 2: Created test template at #{test_path}"
puts "-" * 40

# Re-initialize to discover new template
require 'ace/context/molecules/preset_manager'
manager = Ace::Context::Molecules::PresetManager.new

# List presets again
presets = manager.list_presets
test_preset = presets.find { |p| p[:name] == 'test-autodiscovery' }

if test_preset
  puts "✅ Test template was auto-discovered!"
  puts "  Name: #{test_preset[:name]}"
  puts "  Description: #{test_preset[:description]}"
  puts "  Format: #{test_preset[:format]}"
  puts "  Chunk limit: #{test_preset[:chunk_limit]}"
  puts "  Tags: #{test_preset[:tags]}" if test_preset[:tags]
else
  puts "❌ Test template was NOT discovered"
end

puts "-" * 40
puts

# Test 3: Load the discovered preset
puts "Test 3: Loading discovered preset"
puts "-" * 40

begin
  context = Ace::Context.load_preset('test-autodiscovery')
  if context.metadata[:error]
    puts "❌ Error loading preset: #{context.metadata[:error]}"
  else
    puts "✅ Successfully loaded discovered preset!"
    puts "  Files loaded: #{context.files.count}"
    puts "  Has frontmatter: #{context.metadata[:frontmatter] ? 'Yes' : 'No'}"
  end
rescue => e
  puts "❌ Exception: #{e.message}"
end

# Cleanup
File.delete(test_path) if File.exist?(test_path)
puts "\n✅ Cleaned up test template"

puts
puts "=" * 60
puts "TEST COMPLETE"
puts "=" * 60