# frozen_string_literal: true

require_relative "lib/ace/support/timestamp/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-timestamp"
  spec.version = Ace::Support::Timestamp::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Base36 compact ID generation for timestamps (formerly ace-timestamp)"
  spec.description = "ace-support-timestamp provides 6-character Base36 compact IDs as a replacement for " \
                     "14-character timestamp formats. Encodes timestamps with ~1.85s precision " \
                     "over a 108-year range using hierarchical field encoding."
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-support-timestamp/CHANGELOG.md"

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
  spec.add_dependency "ace-support-config", "~> 0.6"
  spec.add_dependency "ace-support-core", "~> 0.1"
  spec.add_dependency "dry-cli", "~> 1.1"

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
end
