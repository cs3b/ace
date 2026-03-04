# frozen_string_literal: true

require_relative "lib/ace/overseer/version"

Gem::Specification.new do |spec|
  spec.name = "ace-overseer"
  spec.version = Ace::Overseer::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Project control plane orchestrator for task worktrees"
  spec.description = "ace-overseer orchestrates task execution across git worktrees, tmux windows, and assignment workflows."
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-overseer/CHANGELOG.md"

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

  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-config", "~> 0.7"
  spec.add_dependency "ace-assign", "~> 0.16"
  spec.add_dependency "ace-git", "~> 0.10"
  spec.add_dependency "ace-git-worktree", "~> 0.13"
  spec.add_dependency "ace-task", "~> 0.18"
  spec.add_dependency "ace-tmux", "~> 0.6"

  spec.add_development_dependency "ace-support-test-helpers", "~> 0.12"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
