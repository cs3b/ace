# frozen_string_literal: true

require_relative "lib/ace/runtime/version"

Gem::Specification.new do |spec|
  spec.name = "ace-runtime"
  spec.version = Ace::Runtime::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Runtime-neutral terminal intent contract for ACE"
  spec.description = "One duck-typed intent API for terminal runtimes: adapter registry with fail-closed " \
                     "resolution, side-effect-free detection, shared name sanitization, typed errors, " \
                     "central send-matrix validation, the ace-runtime send callback CLI, and the shared " \
                     "adapter contract-test suite."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-runtime/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-runtime/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    native/**/*
    docs/**/*
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
  spec.add_dependency "fiddle", ">= 1.1", "< 2"
  spec.add_dependency "json", ">= 2.20", "< 3"
  spec.add_dependency "ace-support-cli", "~> 0.6"
  spec.add_dependency "ace-support-config", "~> 0.18"
  spec.add_dependency "ace-support-core", "~> 0.31"

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.14"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.88"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
