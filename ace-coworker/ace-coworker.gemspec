# frozen_string_literal: true

require_relative "lib/ace/coworker/version"

Gem::Specification.new do |spec|
  spec.name = "ace-coworker"
  spec.version = Ace::Coworker::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Prepared executor that reads .ace-local/coworker/ and drives its ace-assign assignment"
  spec.description = "ace-coworker composes the existing ace-assign lifecycle, ace-task ref resolution, and ace-hitl reporting for a prepared executor role. It owns the .ace-local/coworker/ run configuration and renders the executor brief."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-coworker/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-coworker/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    docs/**/*
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

  # Library dependencies. `start`/`status` require the ace-assign CLI and
  # `report` additionally requires the ace-hitl CLI at runtime (subprocess
  # argv contract, ADR-031), so both are declared as runtime dependencies to
  # guarantee the executables on fresh installs. `prepare` additionally uses
  # the ace-git-worktree library (worktree provisioning owner). Shipped role
  # presets reference `wfi://` instruction sources resolved through the
  # ace-nav CLI, so ace-support-nav is a runtime dependency too; a missing
  # binary still fails with an explicit Coworker::Error. The shipped
  # reviewer role workflow drives `ace-review`/`ace-review-feedback` as its
  # primary function, so ace-review is a runtime dependency as well.
  spec.add_dependency "ace-support-cli", "~> 0.6", ">= 0.6.10"
  spec.add_dependency "ace-support-core", "~> 0.31"
  spec.add_dependency "ace-support-config", "~> 0.18"
  spec.add_dependency "ace-support-fs", "~> 0.3"
  spec.add_dependency "ace-support-nav", "~> 0.28", ">= 0.28.8"
  spec.add_dependency "ace-task", "~> 0.41"
  spec.add_dependency "ace-assign", "~> 0.72", ">= 0.73.1"
  spec.add_dependency "ace-hitl", "~> 0.22"
  spec.add_dependency "ace-git-worktree", "~> 0.27"
  spec.add_dependency "ace-review", "~> 0.62.2"

  spec.add_development_dependency "ace-support-test-helpers", "~> 0.14"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
