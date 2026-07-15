#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

ROOT = Pathname.new(__dir__).parent.realpath
SUITE_PATH = ROOT.join(".ace", "test", "suite.yml")

def fail_inventory(message)
  warn "CI package inventory error: #{message}"
  exit 1
end

fail_inventory("missing #{SUITE_PATH}") unless SUITE_PATH.file?

suite = YAML.safe_load_file(SUITE_PATH, aliases: true) || {}
entries = suite.dig("test_suite", "packages")
fail_inventory("test_suite.packages must be a non-empty array") unless entries.is_a?(Array) && !entries.empty?

names = entries.map do |entry|
  fail_inventory("each package entry must be a mapping") unless entry.is_a?(Hash)

  name = entry["name"].to_s
  path = entry["path"].to_s
  fail_inventory("package entries require name and path") if name.empty? || path.empty?
  fail_inventory("package #{name.inspect} has a missing path #{path.inspect}") unless ROOT.join(path).directory?
  fail_inventory("package #{name.inspect} must use its directory as path") unless name == path

  name
end

duplicates = names.tally.select { |_name, count| count > 1 }.keys.sort
fail_inventory("duplicate package entries: #{duplicates.join(", ")}") unless duplicates.empty?

test_projects = Dir.children(ROOT).select do |entry|
  entry.start_with?("ace-") && ROOT.join(entry).directory? && ROOT.join(entry, "test").directory?
end.sort

gem_projects = Dir.children(ROOT).select do |entry|
  entry.start_with?("ace-") && ROOT.join(entry, "#{entry}.gemspec").file?
end.sort

missing_from_suite = (test_projects - names).sort
unknown_in_suite = (names - test_projects).sort
gems_without_tests = (gem_projects - test_projects).sort

fail_inventory("missing test projects: #{missing_from_suite.join(", ")}") unless missing_from_suite.empty?
fail_inventory("unknown test projects: #{unknown_in_suite.join(", ")}") unless unknown_in_suite.empty?
fail_inventory("gems without test directories: #{gems_without_tests.join(", ")}") unless gems_without_tests.empty?

puts JSON.generate(names)
