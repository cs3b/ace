# frozen_string_literal: true

require_relative "lib/ace/support/models/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-models"
  spec.version = Ace::Support::Models::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Model metadata, validation, and cost tracking for ACE"
  spec.description = "Integrates with models.dev API to provide model validation, " \
                     "cost tracking, and change monitoring for 40+ LLM providers. " \
                     "Validate model names, calculate query costs, and track pricing changes."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-support-models/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-support-models/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    exe/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }

  spec.bindir = "exe"
  spec.executables = ["ace-models"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-support-core", "~> 0.29" 
  spec.add_dependency "ace-support-cli", "~> 0.6" 
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"

  # Development dependencies managed in root Gemfile
end
