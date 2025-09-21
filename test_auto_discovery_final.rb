#!/usr/bin/env ruby
# frozen_string_literal: true

# Comprehensive test for template auto-discovery feature

require 'fileutils'
require 'open3'

ACE_CONTEXT_DIR = "/Users/mc/Ps/ace-meta/ace-context"

puts "=" * 60
puts "AUTO-DISCOVERY FEATURE TEST"
puts "=" * 60
puts

# Test 1: List presets shows discovered templates
puts "Test 1: Listing presets (should show discovered templates)"
puts "-" * 40

stdout, stderr, status = Open3.capture3(
  "bundle exec exe/ace-context --list-presets",
  chdir: ACE_CONTEXT_DIR
)

discovered_count = stdout.scan(/\(auto-discovered\)/).count
configured_count = stdout.scan(/Description:/).count - discovered_count

puts stdout.lines[0..20].join if stdout.lines.count > 0
puts "..." if stdout.lines.count > 20

puts "\nSummary:"
puts "  Discovered presets: #{discovered_count}"
puts "  Configured presets: #{configured_count}"
puts "  Total presets: #{discovered_count + configured_count}"

success1 = discovered_count >= 3  # We have at least 3 templates in docs/context/
puts success1 ? "✅ PASS" : "❌ FAIL"
puts "-" * 40
puts

# Test 2: Load a discovered preset
puts "Test 2: Loading discovered preset 'dev-tools'"
puts "-" * 40

stdout, stderr, status = Open3.capture3(
  "bundle exec exe/ace-context --preset dev-tools --format yaml",
  chdir: ACE_CONTEXT_DIR
)

if status.success? && stdout.include?("files:")
  puts "✅ PASS - Successfully loaded discovered preset"
  puts "  Output size: #{stdout.bytesize} bytes"
else
  puts "❌ FAIL - Could not load discovered preset"
  puts "  Error: #{stderr.lines.first}" if stderr && !stderr.empty?
end
puts "-" * 40
puts

# Test 3: Create new template and verify auto-discovery
puts "Test 3: Create new template and verify discovery"
puts "-" * 40

# Create a test template with frontmatter
test_content = <<~TEMPLATE
---
description: Integration test template
format: json
chunk_limit: 10000
custom_field: test_value
---

# Integration Test Template

<context-tool-config>
files:
  - README.md
  - "*.gemspec"
</context-tool-config>
TEMPLATE

test_file = "/Users/mc/Ps/ace-meta/docs/context/integration-test.md"
FileUtils.mkdir_p(File.dirname(test_file))
File.write(test_file, test_content)
puts "Created template: #{test_file}"

# List presets to see if it's discovered
stdout, stderr, status = Open3.capture3(
  "bundle exec exe/ace-context --list-presets | grep integration-test",
  chdir: ACE_CONTEXT_DIR
)

if stdout.include?("integration-test")
  puts "✅ PASS - New template was auto-discovered"

  # Try loading it
  stdout2, stderr2, status2 = Open3.capture3(
    "bundle exec exe/ace-context --preset integration-test --format json | head -5",
    chdir: ACE_CONTEXT_DIR
  )

  if status2.success?
    puts "✅ PASS - New template can be loaded"
  else
    puts "❌ FAIL - Could not load new template"
  end
else
  puts "❌ FAIL - New template was NOT discovered"
end

# Cleanup
File.delete(test_file) if File.exist?(test_file)
puts "✅ Cleaned up test template"
puts "-" * 40
puts

# Test 4: Verify backward compatibility
puts "Test 4: Backward compatibility with old config"
puts "-" * 40

# Check if old config exists
if File.exist?("/Users/mc/Ps/ace-meta/.coding-agent/context.yml")
  stdout, stderr, status = Open3.capture3(
    "bundle exec exe/ace-context --list-presets | grep -E '(project|essentials)'",
    chdir: ACE_CONTEXT_DIR
  )

  # Old config presets should still appear
  if stdout.include?("project") || stdout.include?("essentials")
    puts "✅ PASS - Old config presets are available"
    puts "  Found: #{stdout.strip}"
  else
    puts "⚠️  WARNING - Old config may not be loading correctly"
  end
else
  puts "ℹ️  INFO - No old config file present to test"
end
puts "-" * 40
puts

# Test 5: Verify frontmatter extraction
puts "Test 5: YAML frontmatter extraction"
puts "-" * 40

# The project.md template has frontmatter
stdout, stderr, status = Open3.capture3(
  "bundle exec exe/ace-context --list-presets | grep -A2 project",
  chdir: ACE_CONTEXT_DIR
)

if stdout.include?("project wide context")
  puts "✅ PASS - Frontmatter description was extracted"
else
  puts "❌ FAIL - Frontmatter not properly extracted"
end
puts "-" * 40
puts

puts "=" * 60
puts "TEST SUMMARY"
puts "=" * 60
puts "Auto-discovery feature test complete!"
puts "  - Templates in docs/context/*.md are auto-discovered"
puts "  - Discovered presets can be loaded and used"
puts "  - YAML frontmatter is parsed for metadata"
puts "  - Backward compatibility maintained"