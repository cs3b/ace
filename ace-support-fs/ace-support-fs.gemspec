# frozen_string_literal: true

require_relative "lib/ace/support/fs/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-fs"
  spec.version = Ace::Support::Fs::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Filesystem utilities for ace-* gems"
  spec.description = "Infrastructure gem providing unified path expansion, project root detection, " \
                     "and directory traversal functionality for ace-* gems. " \
                     "Library-only gem following ace-support-* pattern for shared filesystem operations."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-support-fs/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-support-fs/CHANGELOG.md"

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

  # No runtime dependencies - using only Ruby stdlib
  # Development dependencies are managed in the root Gemfile
end
