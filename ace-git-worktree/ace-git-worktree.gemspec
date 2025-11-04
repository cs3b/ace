# frozen_string_literal: true

require_relative "lib/ace/git/worktree/version"

Gem::Specification.new do |spec|
  spec.name = "ace-git-worktree"
  spec.version = Ace::Git::Worktree::VERSION
  spec.authors = ["ACE Development Team"]
  spec.email = ["dev@ace.ecosystem"]

  spec.summary = "Task-aware git worktree management for ACE ecosystem"
  spec.description = <<~DESC
    Seamless, task-focused development workflows by providing deterministic CLI tools
    for managing git worktrees integrated with ACE's task management system.

    Features:
    - Task-aware worktree creation with automatic metadata lookup
    - Integration with ace-taskflow for task metadata
    - Configuration-driven naming conventions
    - Automated environment setup (mise trust)
    - Support for traditional worktree operations
  DESC
  spec.homepage = "https://github.com/ace-ecosystem/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-git-worktree"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-git-worktree/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z 2>/dev/null`.split("\x0").grep_v(%r{\A(?:test|spec|features)/})
  end

  spec.bindir = "exe"
  spec.executables = ["ace-git-worktree"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-core", "~> 0.9.0"
  spec.add_dependency "ace-git-diff", "~> 0.1.0"
  spec.add_dependency "ace-taskflow", "~> 0.9.0"

  # Development dependencies are managed in the root Gemfile
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "ace-test-support"
end