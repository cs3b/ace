# frozen_string_literal: true

require_relative "lib/ace/git/secrets/version"

Gem::Specification.new do |spec|
  spec.name = "ace-git-secrets"
  spec.version = Ace::Git::Secrets::VERSION
  spec.authors = ["ace-meta"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Detect, remove, and revoke authentication tokens from Git history"
  spec.description = <<~DESC
    ace-git-secrets provides CLI tools for detecting authentication tokens (GitHub PATs,
    LLM API keys, AWS credentials) in Git history, removing them via git-filter-repo,
    and revoking them via provider APIs. Requires gitleaks for detection.
  DESC
  spec.homepage = "https://github.com/ace-meta/ace-git-secrets"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-config", "~> 0.2"
  spec.add_dependency "faraday", "~> 2.7", ">= 2.7.4"
  spec.add_dependency "faraday-retry", "~> 2.2"
  spec.add_dependency "thor", "~> 1.3"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.19"
end
