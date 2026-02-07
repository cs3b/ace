# frozen_string_literal: true

require_relative "lib/ace/test/end_to_end_runner/version"

Gem::Specification.new do |spec|
  spec.name = "ace-test-e2e-runner"
  spec.version = Ace::Test::EndToEndRunner::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "End-to-end test runner infrastructure for agent-executed testing"
  spec.description = "Provides workflows, templates, and conventions for end-to-end tests " \
                     "that are executed by AI agents rather than automated test runners. " \
                     "Includes test scenario templates and execution workflows."
  spec.homepage = "https://github.com/cs3b/ace-meta/tree/main/ace-test-e2e-runner"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "ace-support-core", ">= 0.10"
  spec.add_dependency "ace-support-config", ">= 0.6"
  spec.add_dependency "ace-llm", ">= 0.1"
  spec.add_dependency "ace-support-timestamp", ">= 0.3"

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
  spec.executables = ["ace-test-e2e"]
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cs3b/ace-meta"
  spec.metadata["changelog_uri"] = "https://github.com/cs3b/ace-meta/blob/main/ace-test-e2e-runner/CHANGELOG.md"
end
