# frozen_string_literal: true

require_relative "lib/ace/demo/version"

Gem::Specification.new do |spec|
  spec.name = "ace-demo"
  spec.version = Ace::Demo::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Record terminal demos and attach to pull requests"
  spec.description = "ace-demo records terminal sessions as reviewable proof-of-work artifacts, with sandbox-isolated YAML tapes and GitHub PR attachment for agent-driven evidence delivery."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-demo/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-demo/CHANGELOG.md"

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

  spec.add_dependency "ace-support-cli", "~> 0.3"
  spec.add_dependency "ace-support-core", "~> 0.25"
  spec.add_dependency "ace-support-config", "~> 0.7"
  spec.add_dependency "ace-b36ts", "~> 0.3"

  spec.add_development_dependency "ace-support-test-helpers", "~> 0.12"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
