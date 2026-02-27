# frozen_string_literal: true

require_relative "lib/ace/test/end_to_end_runner/version"

Gem::Specification.new do |spec|
  spec.name = "ace-test-runner-e2e"
  spec.version = Ace::Test::EndToEndRunner::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "End-to-end test runner infrastructure for agent-executed testing"
  spec.description = "Provides workflows, templates, and conventions for end-to-end tests " \
                     "that are executed by AI agents rather than automated test runners. " \
                     "Includes test scenario templates and execution workflows."
  spec.homepage = "https://github.com/cs3b/ace-meta/tree/main/ace-test-runner-e2e"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-config", "~> 0.7"
  spec.add_dependency "ace-llm", "~> 0.24"
  spec.add_dependency "ace-b36ts", "~> 0.7"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.files = Dir.glob(%w[
    lib/**/*
    handbook/**/*
    exe/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = ["ace-test-e2e", "ace-test-e2e-suite", "ace-test-e2e-sh"]
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cs3b/ace-meta"
  spec.metadata["changelog_uri"] = "https://github.com/cs3b/ace-meta/blob/main/ace-test-runner-e2e/CHANGELOG.md"
end
