# frozen_string_literal: true

require_relative "lib/ace/lint/version"

Gem::Specification.new do |spec|
  spec.name = "ace-lint"
  spec.version = Ace::Lint::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Ruby-only linting for markdown, YAML, and Ruby with no Node.js or Python"
  spec.description = "ace-lint provides Ruby-native linting for markdown (kramdown), YAML (Psych), Ruby files (StandardRB/RuboCop), and frontmatter without Node.js or Python dependencies."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-lint/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-lint/CHANGELOG.md"

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

  # Runtime dependencies - Ruby-only stack
  spec.add_dependency "ace-support-config", "~> 0.8"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-b36ts", "~> 0.7"
  spec.add_dependency "ace-support-cli", "~> 0.3"
  spec.add_dependency "kramdown", "~> 2.4"
  spec.add_dependency "kramdown-parser-gfm", "~> 1.1"
  spec.add_dependency "colorize", "~> 1.1"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
