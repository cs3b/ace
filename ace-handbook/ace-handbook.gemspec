# frozen_string_literal: true

require_relative "lib/ace/handbook/version"

Gem::Specification.new do |spec|
  spec.name = "ace-handbook"
  spec.version = Ace::Handbook::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Standardized workflows for creating and managing guides, workflow instructions, and agent definitions."
  spec.description = "Standardized workflows for creating, reviewing, and maintaining ACE handbook guides, workflow instructions, and agent definitions."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-handbook/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-handbook/CHANGELOG.md"

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

  spec.add_dependency "ace-support-config", "~> 0.7"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-nav", "~> 0.21"
  spec.add_dependency "ace-support-cli", "~> 0.3"

  # Development dependencies from root Gemfile
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
