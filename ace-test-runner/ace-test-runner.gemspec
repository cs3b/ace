# frozen_string_literal: true

require_relative "lib/ace/test_runner/version"

Gem::Specification.new do |spec|
  spec.name = "ace-test-runner"
  spec.version = Ace::TestRunner::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "AI-friendly test runner with smart grouping, failure analysis, and persistent reports"
  spec.description = "Wraps Minitest with smart grouping, cross-package resolution, and persistent reports so developers and coding agents can run focused checks, diagnose failures with context, and retain searchable execution history."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-test-runner/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-test-runner/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
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
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-support-cli", "~> 0.3"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-config", "~> 0.8"
  spec.add_dependency "ace-support-test-helpers", "~> 0.12"
  spec.add_dependency "ace-b36ts", "~> 0.7"
  spec.add_dependency "minitest", "~> 5.0"
  spec.add_dependency "minitest-reporters", "~> 1.6"
  spec.add_dependency "ostruct"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
