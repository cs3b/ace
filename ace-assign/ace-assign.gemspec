# frozen_string_literal: true

require_relative "lib/ace/assign/version"

Gem::Specification.new do |spec|
  spec.name = "ace-assign"
  spec.version = Ace::Assign::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Assignment-based work queue management for AI-assisted workflows"
  spec.description = "ACE Assign manages workflow assignments using a file-based work queue model where phases have states (done, in_progress, pending, failed) and history is preserved"
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-assign/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*
    exe/*
    handbook/**/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-config", "~> 0.8"
  spec.add_dependency "ace-support-nav", "~> 0.7"
  spec.add_dependency "ace-b36ts", "~> 0.7"
  spec.add_dependency "ace-support-markdown", "~> 0.2"
  spec.add_dependency "ace-llm", "~> 0.26"

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.12"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
