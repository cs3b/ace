# frozen_string_literal: true

require_relative "lib/ace/test_support/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-test-helpers"
  spec.version = Ace::TestSupport::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Shared test utilities for ace-* gems"
  spec.description = "Development-only infrastructure gem providing shared test utilities, base test cases, " \
                     "and helpers for all ace-* gems. Includes configuration helpers, " \
                     "test environment management, and common test patterns. Library-only gem following ace-support-* pattern."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-support-test-helpers/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-support-test-helpers/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }

  spec.bindir = "exe"
  spec.executables = []
  spec.require_paths = ["lib"]

  # Runtime dependencies for test support
  spec.add_dependency "minitest", "~> 5.20"
  spec.add_dependency "minitest-reporters", "~> 1.6"

  # Development dependencies are managed in the root Gemfile
end
