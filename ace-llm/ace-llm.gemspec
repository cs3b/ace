# frozen_string_literal: true

require_relative "lib/ace/llm/version"

Gem::Specification.new do |spec|
  spec.name = "ace-llm"
  spec.version = Ace::LLM::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "LLM provider integration for AI-assisted development"
  spec.description = "Query any LLM provider through a unified CLI interface with cost tracking and output formatting"
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-llm/CHANGELOG.md"

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
  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "ace-support-config", "~> 0.8"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "addressable", "~> 2.8"
  spec.add_dependency "kramdown", "~> 2.0"
  spec.add_dependency "kramdown-parser-gfm", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "simplecov", "~> 0.22"
end