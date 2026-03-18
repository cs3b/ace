# frozen_string_literal: true

require_relative "lib/ace/integration/claude/version"

Gem::Specification.new do |spec|
  spec.name = "ace-integration-claude"
  spec.version = Ace::Integration::Claude::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Claude Code integration workflows for ACE"
  spec.description = "Integration package containing Claude Code command templates, workflows, and tools for maintaining AI-assisted development integration"
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-integration-claude/CHANGELOG.md"

  # Include workflow and integration files
  spec.files = Dir.glob(%w[
    lib/**/*
    handbook/**/*
    integrations/**/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # No runtime dependencies for pure integration package
  # spec.add_dependency "ace-support-core", "~> 0.10"

  # Development dependencies from root Gemfile
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end