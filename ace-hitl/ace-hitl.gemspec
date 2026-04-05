# frozen_string_literal: true

require_relative "lib/ace/hitl/version"

Gem::Specification.new do |spec|
  spec.name = "ace-hitl"
  spec.version = Ace::Hitl::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Human-in-the-loop workflow package for ACE"
  spec.description = "Provides the dedicated ace-hitl package surface for human in the loop (HITL) semantics and CLI workflows."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-hitl/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-hitl/CHANGELOG.md"

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

  spec.add_dependency "ace-support-core", "~> 0.29"
  spec.add_dependency "ace-support-config", "~> 0.9"
  spec.add_dependency "ace-support-fs", "~> 0.3"
  spec.add_dependency "ace-support-items", "~> 0.15"
  spec.add_dependency "ace-b36ts", "~> 0.13"
  spec.add_dependency "ace-support-cli", "~> 0.6"
end
