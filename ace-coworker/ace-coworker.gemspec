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

  # Library dependencies. `start`/`status` require the ace-assign CLI at
  # runtime (subprocess argv contract, ADR-031), so it is declared as a
  # runtime dependency to guarantee the executable on fresh installs.
  # ace-hitl reporting and protocol instructions (ace-nav) arrive in later
  # leaves; missing binaries fail with an explicit Coworker::Error.
  spec.add_dependency "ace-support-cli", "~> 0.6"
  spec.add_dependency "ace-support-core", "~> 0.31"
  spec.add_dependency "ace-support-config", "~> 0.18"
  spec.add_dependency "ace-support-fs", "~> 0.3"
  spec.add_dependency "ace-task", "~> 0.41"
  spec.add_dependency "ace-assign", "~> 0.72"

  spec.add_development_dependency "ace-support-test-helpers", "~> 0.14"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
