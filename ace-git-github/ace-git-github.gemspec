# frozen_string_literal: true

require_relative "lib/ace/git/github/version"

Gem::Specification.new do |spec|
  spec.name = "ace-git-github"
  spec.version = Ace::Git::Github::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "GitHub provider for the forge-neutral ace-git core"
  spec.description = "Implements the shared ace-git provider contract for GitHub: all `gh` CLI " \
                     "invocation, output parsing, authentication verification, and classified " \
                     "failure handling live behind one normalized evidence boundary."
  spec.homepage = "https://forgejo.tail6c0887.ts.net/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/src/branch/main/ace-git-github"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/src/branch/main/ace-git-github/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-git", "~> 0.24"

  # Development dependencies managed in root Gemfile
end
