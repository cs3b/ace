# frozen_string_literal: true

require_relative "lib/ace/config/version"

Gem::Specification.new do |spec|
  spec.name = "ace-config"
  spec.version = Ace::Config::VERSION
  spec.authors = ["ACE Team"]
  spec.email = ["ace@example.com"]

  spec.summary = "Generic configuration cascade management"
  spec.description = "Reusable configuration cascade with customizable folder names. " \
                     "Supports project-level, user-level, and gem-level configuration " \
                     "with deep merging and priority-based resolution."
  spec.homepage = "https://github.com/cs3b/ace-meta/tree/main/ace-config"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  # Runtime dependencies
  spec.add_dependency "ace-support-fs", "~> 0.1"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.files = Dir.glob(%w[
    lib/**/*
    handbook/**/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cs3b/ace-meta"
  spec.metadata["changelog_uri"] = "https://github.com/cs3b/ace-meta/blob/main/ace-config/CHANGELOG.md"
end
