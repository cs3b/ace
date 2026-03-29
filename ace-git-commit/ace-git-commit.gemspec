# frozen_string_literal: true

require_relative "lib/ace/git_commit/version"

Gem::Specification.new do |spec|
  spec.name = "ace-git-commit"
  spec.version = Ace::GitCommit::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Intention-aware conventional commit generation from diffs"
  spec.description = "Analyzes diffs and developer intent to generate conventional commit messages " \
                     "using LLM. Handles monorepo scoping automatically — split commits across packages " \
                     "with one command."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cs3b/ace/tree/main/ace-git-commit/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-git-commit/CHANGELOG.md"

  # Specify which files should be added to the gem
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
  spec.add_dependency "ace-support-cli", "~> 0.6"
  spec.add_dependency "ace-support-core", "~> 0.29"
  spec.add_dependency "ace-support-config", "~> 0.9"
  spec.add_dependency "ace-git", "~> 0.19"
  spec.add_dependency "ace-llm", "~> 0.30"

  # Development dependencies managed in root Gemfile
end
