# frozen_string_literal: true

require_relative "lib/ace/idea/version"

Gem::Specification.new do |spec|
  spec.name = "ace-idea"
  spec.version = Ace::Idea::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Standalone idea management gem for ACE with b36ts-based IDs"
  spec.description = "Manages ideas in .ace-ideas/ using raw 6-char b36ts IDs, " \
                     "flat directory structure, and 5-command pattern (create, show, list, move, update). " \
                     "Supports clipboard capture and LLM enhancement."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-idea/CHANGELOG.md"

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
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-items", "~> 0.3"
  spec.add_dependency "ace-b36ts", "~> 0.7"
  spec.add_dependency "ace-support-cli", "~> 0.3"

  # Development dependencies managed in root Gemfile
end
