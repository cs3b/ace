# frozen_string_literal: true

require_relative "lib/ace/prompt_prep/version"

Gem::Specification.new do |spec|
  spec.name = "ace-prompt-prep"
  spec.version = Ace::PromptPrep::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Prompt workspace with archiving, LLM enhancement, and context loading"
  spec.description = "Provides a single active prompt file with automatic history archiving. " \
                     "Write prompts in your editor, run ace-prompt-prep, get automatic archiving " \
                     "with optional context loading and LLM enhancement."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cs3b/ace/tree/main/ace-prompt-prep/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-prompt-prep/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*
    handbook/**/*
    config/**/*
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
  spec.add_dependency "ace-support-config", "~> 0.9"
  spec.add_dependency "ace-bundle", "~> 0.41"
  spec.add_dependency "ace-git", "~> 0.19" # Unified git operations (task 140.04)
  spec.add_dependency "ace-llm", "~> 0.30"
  spec.add_dependency "ace-support-nav", "~> 0.25"
  spec.add_dependency "ace-support-core", "~> 0.29" # ace-support-cli infrastructure (task 179.01)
  spec.add_dependency "ace-task", "~> 0.31"
  spec.add_dependency "ace-b36ts", "~> 0.13" # Base36 compact IDs (task 149, renamed 202.03)
  spec.add_dependency "ace-support-cli", "~> 0.6"

  # Development dependencies managed in root Gemfile
end
