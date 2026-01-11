# frozen_string_literal: true

require_relative "lib/ace/nav/version"

Gem::Specification.new do |spec|
  spec.name = "ace-nav"
  spec.version = Ace::Nav::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Unified navigation and resource discovery for ACE ecosystem"
  spec.description = "ace-nav provides unified navigation and path resolution across the ACE ecosystem. " \
                     "It automatically discovers handbooks bundled within ace-* gems, resolves resource URIs " \
                     "to actual file paths, and supports a multi-level override cascade."
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-nav/CHANGELOG.md"

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

  # Runtime dependencies
  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "ace-support-core", "~> 0.10"
  spec.add_dependency "ace-support-config", "~> 0.6"
  spec.add_dependency "ace-support-fs", "~> 0.1"

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.1"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "simplecov", "~> 0.22"
end