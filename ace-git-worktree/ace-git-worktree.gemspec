# frozen_string_literal: true

require_relative 'lib/ace/git/worktree/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-git-worktree'
  spec.version = Ace::Git::Worktree::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = 'Task-aware git worktree management for ACE ecosystem'
  spec.description = <<~DESC
    Seamless, task-focused development workflows by providing deterministic CLI tools
    for managing git worktrees integrated with ACE's task management system.

    Features:
    - Task-aware worktree creation with automatic metadata lookup
    - Integration with ace-task for task metadata
    - Configuration-driven naming conventions
    - Automated environment setup (mise trust)
    - Support for traditional worktree operations
  DESC
  spec.homepage = 'https://github.com/cs3b/ace'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = "#{spec.homepage}/tree/main/ace-git-worktree"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/ace-git-worktree/CHANGELOG.md"

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

  spec.bindir = 'exe'
  spec.executables = ['ace-git-worktree']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-support-cli', '~> 0.3'
  spec.add_dependency 'ace-support-core', '~> 0.24'
  spec.add_dependency 'ace-support-config', '~> 0.7'
  spec.add_dependency 'ace-git', '~> 0.11'
  spec.add_dependency 'ace-task', '~> 0.11'

  # Development dependencies are managed in the root Gemfile
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'ace-support-test-helpers', '~> 0.12'
end

