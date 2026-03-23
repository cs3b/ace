# frozen_string_literal: true

require_relative "lib/ace/b36ts/version"

Gem::Specification.new do |spec|
  spec.name = "ace-b36ts"
  spec.version = Ace::B36ts::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Compact, sortable Base36 timestamp IDs"
  spec.description = "ace-b36ts provides 6-character Base36 compact IDs as a replacement for " \
                     "14-character timestamp formats. Encodes timestamps with ~1.85s precision " \
                     "over a 108-year range using hierarchical field encoding."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-b36ts/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-b36ts/CHANGELOG.md"

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
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-cli", "~> 0.3"

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.12"
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
end
