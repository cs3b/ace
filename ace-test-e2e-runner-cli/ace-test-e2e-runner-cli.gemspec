# frozen_string_literal: true

require_relative "lib/ace/e2e_runner/version"

Gem::Specification.new do |spec|
  spec.name = "ace-test-e2e-runner-cli"
  spec.version = Ace::E2eRunner::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "CLI for LLM-driven end-to-end test execution"
  spec.description = "Provides the ace-e2e-test and ace-e2e-test-suite commands for running E2E test scenarios via LLMs."
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-test-e2e-runner-cli/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    exe/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ace-support-core", ">= 0.1"
  spec.add_dependency "ace-support-config", ">= 0.1"
  spec.add_dependency "ace-llm", ">= 0.1"
  spec.add_dependency "ace-support-timestamp", ">= 0.2"
  spec.add_dependency "dry-cli", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
