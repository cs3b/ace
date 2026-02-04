# frozen_string_literal: true

require_relative "lib/ace/scheduler/version"

Gem::Specification.new do |spec|
  spec.name = "ace-scheduler"
  spec.version = Ace::Scheduler::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Local task scheduler for ace-* workflows"
  spec.description = "Provides scheduled task execution and event triggers for local ACE workflows."
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-scheduler/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    exe/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ace-support-core", ">= 0.1"
  spec.add_dependency "ace-support-config", ">= 0.1"
  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "fugit", "~> 1.8"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
