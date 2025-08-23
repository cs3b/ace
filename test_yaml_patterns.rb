#!/usr/bin/env ruby

require_relative 'dev-tools/lib/coding_agent_tools/atoms/taskflow_management/yaml_frontmatter_parser'

# Test the current problematic pattern
pattern = /\binclude\s+[A-Z]/

# Test cases that should be safe but might trigger false positives
safe_examples = [
  "description: This guide will include Steps for setting up",
  "instructions: Please include Claude integration",
  "note: Must include API configuration",
  "content: The workflow should include Database setup",
  "title: How to include Configuration files",
  "usage: include Settings in the project"
]

# Test cases that should trigger security warnings (actual threats)
dangerous_examples = [
  "code: include MyModule",
  "eval: include Kernel", 
  "require: include ActiveRecord::Base"
]

puts "Testing current pattern: #{pattern}"
puts "\n=== Safe examples (should NOT match) ==="
safe_examples.each do |example|
  match = example.match?(pattern)
  status = match ? "❌ MATCHES (false positive)" : "✅ Safe"
  puts "#{status}: #{example}"
end

puts "\n=== Dangerous examples (SHOULD match) ==="
dangerous_examples.each do |example|
  match = example.match?(pattern)
  status = match ? "✅ MATCHES (correctly detected)" : "❌ Not detected"
  puts "#{status}: #{example}"
end

# Test with actual YAML frontmatter
puts "\n=== Testing with actual YAML parsing ==="

# Safe YAML that might cause issues
safe_yaml = <<~YAML
---
title: Claude Integration Setup
description: This guide will include Steps for setting up Claude Code integration
instructions: Please include Configuration files in your project
---

Content here
YAML

begin
  result = CodingAgentTools::Atoms::TaskflowManagement::YamlFrontmatterParser.parse(safe_yaml, safe_mode: true)
  puts "✅ Safe YAML parsed successfully"
rescue CodingAgentTools::Atoms::TaskflowManagement::YamlFrontmatterParser::SecurityError => e
  puts "❌ Safe YAML triggered security error: #{e.message}"
end

# Dangerous YAML that should be blocked
dangerous_yaml = <<~YAML
---
title: Malicious Content
code: include Kernel
---

Content here
YAML

begin
  result = CodingAgentTools::Atoms::TaskflowManagement::YamlFrontmatterParser.parse(dangerous_yaml, safe_mode: true)
  puts "❌ Dangerous YAML was not blocked!"
rescue CodingAgentTools::Atoms::TaskflowManagement::YamlFrontmatterParser::SecurityError => e
  puts "✅ Dangerous YAML correctly blocked: #{e.message}"
end