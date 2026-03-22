# frozen_string_literal: true

require_relative "lib/ace/docs/version"

Gem::Specification.new do |spec|
  spec.name = "ace-docs"
  spec.version = Ace::Docs::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Keep documentation current with freshness tracking, drift detection, and LLM suggestions"
  spec.description = "Documentation management for teams and agents: track freshness from frontmatter, detect drift from git history, run LLM-powered analysis, and validate consistency across docs."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-docs/CHANGELOG.md"

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
  spec.add_dependency "ace-support-config", "~> 0.8"
  spec.add_dependency "ace-support-core", "~> 0.25" # Requires PromptCacheManager
  spec.add_dependency "ace-git", "~> 0.10"
  spec.add_dependency "ace-b36ts", "~> 0.7"
  spec.add_dependency "ace-llm", "~> 0.26"
  spec.add_dependency "ace-support-markdown", "~> 0.2"
  spec.add_dependency "ace-support-cli", "~> 0.3"
  spec.add_dependency "yaml", "~> 0.3"
  spec.add_dependency "colorize", "~> 1.1"
  spec.add_dependency "terminal-table", "~> 3.0"
  spec.add_dependency "fileutils", "~> 1.7"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
