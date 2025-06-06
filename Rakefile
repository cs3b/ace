# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

# Define additional development tasks
desc "Run tests with coverage reporting"
task :test do
  sh "bin/test"
end

desc "Run linter (StandardRB)"
task :lint do
  sh "bin/lint"
end

desc "Build the gem"
task :build_gem do
  sh "bin/build"
end

desc "Run all quality checks (test, lint)"
task quality: [:test, :lint]

desc "Clean up generated files"
task :clean do
  sh "rm -rf coverage/"
  sh "rm -f *.gem"
  sh "rm -rf pkg/"
  sh "rm -rf tmp/"
end

desc "Setup development environment"
task :setup do
  sh "bundle install"
  puts "Development environment ready!"
end

desc "Display project status and recent activity"
task :status do
  puts "=== Coding Agent Tools - Project Status ==="
  puts

  # Show current version
  require_relative "lib/coding_agent_tools/version"
  puts "Version: #{CodingAgentTools::VERSION}"

  # Show git status
  puts
  puts "Git Status:"
  begin
    sh "git status --porcelain"
  rescue
    puts "  (git not available)"
  end

  # Show recent commits
  puts
  puts "Recent Commits:"
  begin
    sh "git log --oneline -5"
  rescue
    puts "  (git not available)"
  end

  # Show test status
  puts
  puts "Running quick test check..."
  system("bundle exec rspec --format progress") ? puts("✓ Tests passing") : puts("✗ Tests failing")
end

task default: %i[quality]
