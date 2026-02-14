# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ace/taskflow/version"

Gem::Specification.new do |spec|
  spec.name = "ace-taskflow"
  spec.version = Ace::Taskflow::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Task and idea management for ACE"
  spec.description = "Unified task management including idea capture, task tracking, and release management"
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-taskflow/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released
  spec.files = Dir.glob(%w[
    lib/**/*
    exe/*
    handbook/**/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "ace-support-config", "~> 0.6"
  spec.add_dependency "ace-support-core", "~> 0.11"
  spec.add_dependency "ace-git", "~> 0.3"
  spec.add_dependency "clipboard", "~> 1.3"
  spec.add_dependency "ace-support-mac-clipboard", "~> 0.2.0"
  spec.add_dependency "ace-support-markdown", "~> 0.1"
  spec.add_dependency "ace-b36ts", "~> 0.2"

  # No development dependencies - managed in root Gemfile
end