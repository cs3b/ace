# frozen_string_literal: true

require_relative "lib/ace/task/version"

Gem::Specification.new do |spec|
  spec.name = "ace-task"
  spec.version = Ace::Task::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Draft, organize, and tackle tasks — for you and your agents"
  spec.description = "Behavioral spec-based task management with compact IDs, subtask trees, " \
                     "AI-powered implementation plans, and automated health checks. " \
                     "Same CLI for developers and coding agents."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-task/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-task/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    exe/*
    handbook/**/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }

  spec.bindir = "exe"
  spec.executables = ["ace-task"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-support-core", "~> 0.29"
  spec.add_dependency "ace-support-fs", "~> 0.3"
  spec.add_dependency "ace-support-items", "~> 0.15"
  spec.add_dependency "ace-support-markdown", "~> 0.3"
  spec.add_dependency "ace-b36ts", "~> 0.13"
  spec.add_dependency "ace-git", "~> 0.19"
  spec.add_dependency "ace-support-cli", "~> 0.6"

  # Development dependencies managed in root Gemfile
end
