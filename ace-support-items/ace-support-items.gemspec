# frozen_string_literal: true

require_relative "lib/ace/support/items/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-items"
  spec.version = Ace::Support::Items::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Shared item management infrastructure for ACE gems"
  spec.description = "Provides shared infrastructure for folder-based item management (tasks, ideas, etc.) " \
                     "across ace-* gems. Includes document loading, frontmatter parsing/serialization, " \
                     "filtering, sorting, directory scanning, and shortcut resolution."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-support-items/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }

  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-b36ts", "~> 0.7"

  # Development dependencies managed in root Gemfile
end
