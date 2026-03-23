# frozen_string_literal: true

require_relative "lib/ace/support/cli/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-cli"
  spec.version = Ace::Support::Cli::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "CLI command framework for ACE gems"
  spec.description = "Provides command DSL, option parsing, registry routing, and runner primitives for ACE CLI tools."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-support-cli/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-support-cli/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    exe/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # No runtime dependencies; this package is intentionally standalone.
end
