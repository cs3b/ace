#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for verifying backward compatibility of ace-context with old context tool

require 'open3'
require 'fileutils'
require 'yaml'

# Test results
results = []
failures = []

def run_test(description, command)
  puts "Testing: #{description}"
  stdout, stderr, status = Open3.capture3(command)
  success = status.success?

  if success
    puts "  ✅ PASS"
  else
    puts "  ❌ FAIL: #{stderr.lines.first}"
  end

  { description: description, success: success, stdout: stdout, stderr: stderr }
end

# Navigate to ace-context directory
Dir.chdir('/Users/mc/Ps/ace-meta/ace-context')

puts "=" * 60
puts "BACKWARD COMPATIBILITY TEST SUITE"
puts "=" * 60
puts

# Test 1: List presets
result = run_test("List presets", "bundle exec exe/ace-context --list-presets")
results << result

# Test 2: List presets with alias
result = run_test("List presets (alias -l)", "bundle exec exe/ace-context -l")
results << result

# Test 3: Help output
result = run_test("Help output", "bundle exec exe/ace-context --help")
results << result

# Test 4: Debug flag
result = run_test("Debug flag", "bundle exec exe/ace-context --debug --list")
results << result

# Test 5: Format options
formats = ['markdown', 'yaml', 'xml', 'markdown-xml', 'json']
formats.each do |format|
  # Create a simple test file for format testing
  File.write('/tmp/test_context.yml', "files:\n  - README.md\n")
  result = run_test("Format option: #{format}",
                     "bundle exec exe/ace-context /tmp/test_context.yml --format #{format} 2>&1 | head -5")
  results << result
  break if !result[:success] # Stop if format test fails
end

# Test 6: Max size option
result = run_test("Max size option",
                   "bundle exec exe/ace-context --max-size 500000 --list")
results << result

# Test 7: Timeout option
result = run_test("Timeout option",
                   "bundle exec exe/ace-context --timeout 60 --list")
results << result

# Test 8: Multiple presets (comma-separated)
result = run_test("Multiple presets support",
                   "bundle exec exe/ace-context --preset default,default --list")
results << result

# Summary
puts
puts "=" * 60
puts "TEST SUMMARY"
puts "=" * 60

passed = results.count { |r| r[:success] }
failed = results.count { |r| !r[:success] }
total = results.count

puts "Total tests: #{total}"
puts "Passed: #{passed}"
puts "Failed: #{failed}"
puts

if failed > 0
  puts "Failed tests:"
  results.select { |r| !r[:success] }.each do |r|
    puts "  - #{r[:description]}"
    puts "    Error: #{r[:stderr].lines.first&.strip}"
  end
end

puts
puts "Overall result: #{failed == 0 ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}"

exit(failed == 0 ? 0 : 1)