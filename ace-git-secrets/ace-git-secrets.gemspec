# frozen_string_literal: true

require_relative "lib/ace/git/secrets/version"

Gem::Specification.new do |spec|
  spec.name = "ace-git-secrets"
  spec.version = Ace::Git::Secrets::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Detect, remove, and revoke authentication tokens from Git history"
  spec.description = <<~DESC
    ace-git-secrets provides CLI tools for detecting authentication tokens (GitHub PATs,
    LLM API keys, AWS credentials) in Git history, removing them via git-filter-repo,
    and revoking them via provider APIs. Requires gitleaks for detection.
  DESC
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-git-secrets/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

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

  # Runtime dependencies
  spec.add_dependency "ace-support-config", "~> 0.8"
  spec.add_dependency "ace-b36ts", "~> 0.7"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-cli", "~> 0.3"
  spec.add_dependency "faraday", "~> 2.7", ">= 2.7.4"
  spec.add_dependency "faraday-retry", "~> 2.2"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.19"
end
