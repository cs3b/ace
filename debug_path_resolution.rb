#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/coding_agent_tools/atoms/git/path_resolver"
require_relative "lib/coding_agent_tools/atoms/git/repository_scanner"
require_relative "lib/coding_agent_tools/atoms/project_root_detector"

# Set up test environment
project_root = "/Users/michalczyz/Projects/CodingAgent/tools-meta-f-git"
repositories = CodingAgentTools::Atoms::Git::RepositoryScanner.discover_repositories(project_root)

puts "=== DEBUGGING PATH RESOLUTION ==="
puts "Project root: #{project_root}"
puts "Current working directory: #{Dir.pwd}"
puts

# Test paths that demonstrate the issue
test_paths = [
  "dev-tools/exe/git-log",
  "dev-taskflow/current/v.0.3.0-migration/docs/19-cli-interface-design.md"
]

path_resolver = CodingAgentTools::Atoms::Git::PathResolver.new(repositories, project_root)

test_paths.each do |path|
  puts "\n--- Debugging path: #{path} ---"
  
  # Check if path is relative or absolute
  pathname = Pathname.new(path)
  puts "Is relative? #{pathname.relative?}"
  
  # Show what expand_path does from current directory
  expanded_from_cwd = File.expand_path(path, Dir.pwd)
  puts "Expanded from CWD: #{expanded_from_cwd}"
  
  # Show what expand_path does from project root
  expanded_from_root = File.expand_path(path, project_root)
  puts "Expanded from project root: #{expanded_from_root}"
  
  # Show which one exists
  puts "Exists from CWD: #{File.exist?(expanded_from_cwd)}"
  puts "Exists from project root: #{File.exist?(expanded_from_root)}"
  
  # Test our path resolution
  result = path_resolver.resolve_path(path)
  puts "PathResolver result: #{result[:absolute_path]}"
  puts "PathResolver exists: #{result[:exists]}"
end