# frozen_string_literal: true

require_relative "lib/ace/git_diff/version"

Gem::Specification.new do |spec|
  spec.name = "ace-git-diff"
  spec.version = Ace::GitDiff::VERSION
  spec.authors = ["ACE Team"]
  spec.email = ["team@ace.dev"]

  spec.summary = "Unified git diff functionality for ACE ecosystem"
  spec.description = "Provides consistent, configurable git diff operations across all ACE tools with user-controllable filtering and global configuration support"
  spec.homepage = "https://github.com/your-org/ace-git-diff"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    exe/*
    handbook/**/*.{ag,wf}.md
    .ace.example/**/*
    README.md
    CHANGELOG.md
    LICENSE
  ], File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  spec.bindir = "exe"
  spec.executables = ["ace-git-diff"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-support-core", "~> 0.9"
  spec.add_dependency "thor", "~> 1.3"

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
