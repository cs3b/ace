# frozen_string_literal: true

require_relative "lib/ace/test/version"

Gem::Specification.new do |spec|
  spec.name = "ace-test"
  spec.version = Ace::Test::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Testing knowledge base for ACE -- guides, patterns, and workflows for fast, reliable tests."
  spec.description = "ACE testing knowledge base with guides, testing patterns, and workflow instructions for fast and reliable code validation."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-test/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-test/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*
    handbook/**/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # No runtime dependencies for pure workflow package

  # Development dependencies from root Gemfile
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
