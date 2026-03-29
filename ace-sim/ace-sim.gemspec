# frozen_string_literal: true

require_relative "lib/ace/sim/version"

Gem::Specification.new do |spec|
  spec.name = "ace-sim"
  spec.version = Ace::Sim::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Multi-provider LLM simulation chains for validating ideas and reviewing tasks before implementation"
  spec.description = "ace-sim executes preset-driven simulation chains across multiple providers so teams can validate ideas, review tasks, and compare synthesis outcomes before taking action."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-sim/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-sim/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    handbook/**/*
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

  spec.add_dependency "ace-support-config", "~> 0.9"
  spec.add_dependency "ace-support-core", "~> 0.29"
  spec.add_dependency "ace-b36ts", "~> 0.13"
  spec.add_dependency "ace-support-cli", "~> 0.6"

  spec.add_development_dependency "ace-support-test-helpers", "~> 0.13"
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
end
