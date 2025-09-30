# frozen_string_literal: true

SimpleCov.start do
  # Set the coverage directory
  coverage_dir "coverage"

  # Configure profiles for mono-repo structure
  add_filter "/test/"
  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/.bundle/"
  add_filter "/coverage/"

  # Track all ace-* gems
  track_files "ace-*/lib/**/*.rb"

  # Group coverage by gem
  add_group "ace-core", "ace-core/lib"
  add_group "ace-test-support", "ace-test-support/lib"
  add_group "ace-test-runner", "ace-test-runner/lib"
  add_group "ace-context", "ace-context/lib"
  add_group "ace-nav", "ace-nav/lib"
  add_group "ace-taskflow", "ace-taskflow/lib"
  add_group "ace-git-commit", "ace-git-commit/lib"
  add_group "ace-llm", "ace-llm/lib"
  add_group "ace-llm-providers-cli", "ace-llm-providers-cli/lib"

  # Set minimum coverage (disabled for now while adding tests incrementally)
  # minimum_coverage 80

  # Enable branch coverage
  enable_coverage :branch

  # Format output
  formatter SimpleCov::Formatter::HTMLFormatter if ENV["CI"].nil?
end

# For merging results across test runs
SimpleCov.collate Dir["coverage/.resultset-*.json"], "ACE Test Suite" do
  formatter SimpleCov::Formatter::HTMLFormatter
end if ENV["COVERAGE_MERGE"]