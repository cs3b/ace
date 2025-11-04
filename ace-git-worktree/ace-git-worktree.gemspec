# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ace/git/worktree/version"

Gem::Specification.new do |spec|
  spec.name = "ace-git-worktree"
  spec.version = Ace::Git::Worktree::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your-email@example.com"]

  spec.summary = "Git worktree management with ACE task integration"
  spec.description = "CLI tool for managing git worktrees with integrated task awareness. Creates isolated development environments for tasks by automatically fetching task metadata from ace-taskflow and configuring worktrees with consistent naming conventions."
  spec.homepage = "https://github.com/yourusername/ace-git-worktree"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[test/ .git .github/ .ace/ tmp/ coverage/])
    end
  end
  spec.bindir = "exe"
  spec.executables = ["ace-git-worktree"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-support-core", "~> 0.10"
  spec.add_dependency "ace-git-diff", "~> 0.1"

  # Development dependencies are managed in root Gemfile
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end