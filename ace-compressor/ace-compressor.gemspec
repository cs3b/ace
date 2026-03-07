# frozen_string_literal: true

require_relative "lib/ace/compressor/version"

Gem::Specification.new do |spec|
  spec.name = "ace-compressor"
  spec.version = Ace::Compressor::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Compress markdown context into structured packs for agents"
  spec.description = "ace-compressor provides exact and compact context compression with structured ContextPack output."
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-compressor/CHANGELOG.md"

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

  spec.add_dependency "ace-support-config", "~> 0.8"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "dry-cli", "~> 1.1"

  spec.add_development_dependency "ace-support-test-helpers", "~> 0.12"
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
end
