#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/coding_agent_tools/atoms/git/path_resolver"
require_relative "lib/coding_agent_tools/atoms/git/repository_scanner"
require_relative "lib/coding_agent_tools/atoms/project_root_detector"

# Set up test environment
project_root = "/Users/michalczyz/Projects/CodingAgent/tools-meta-f-git"
repositories = CodingAgentTools::Atoms::Git::RepositoryScanner.discover_repositories(project_root)

puts "=== DISCOVERED REPOSITORIES ==="
repositories.each do |repo|
  puts "#{repo[:name]}: #{repo[:path]} (#{repo[:full_path]})"
end

puts "\n=== TESTING PATH RESOLUTION ==="

# Test paths that demonstrate the issue
test_paths = [
  "dev-tools/exe/git-log",
  "dev-taskflow/current/v.0.3.0-migration/docs/19-cli-interface-design.md"
]

path_resolver = CodingAgentTools::Atoms::Git::PathResolver.new(repositories, project_root)

test_paths.each do |path|
  puts "\n--- Testing path: #{path} ---"
  
  begin
    result = path_resolver.resolve_path(path)
    puts "Original path: #{result[:original_path]}"
    puts "Absolute path: #{result[:absolute_path]}"
    puts "Repository: #{result[:repository]}"
    puts "Repository path: #{result[:repository_path]}"
    puts "Relative path: #{result[:relative_path]}"
    puts "Exists: #{result[:exists]}"
  rescue => e
    puts "Error: #{e.message}"
  end
end

puts "\n=== TESTING GROUP PATHS BY REPOSITORY ==="
grouped_paths = path_resolver.group_paths_by_repository(test_paths)

grouped_paths.each do |repo_name, paths|
  puts "Repository: #{repo_name}"
  puts "  Paths: #{paths.join(', ')}"
end

puts "\n=== PROBLEM DEMONSTRATION ==="
puts "Current behavior would generate:"
grouped_paths.each do |repo_name, paths|
  puts "git -C #{repo_name} add #{paths.join(' ')}"
end

puts "\nCorrect behavior should generate:"
puts "git -C dev-tools add exe/git-log"
puts "git -C dev-taskflow add current/v.0.3.0-migration/docs/19-cli-interface-design.md"