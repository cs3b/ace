# frozen_string_literal: true

require_relative "lib/ace/b36ts/version"

Gem::Specification.new do |spec|
  spec.name = "ace-b36ts"
  spec.version = Ace::B36ts::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Compact, sortable Base36 timestamp IDs for scripts, logs, and path-friendly artifacts"
  spec.description = "ace-b36ts encodes UTC timestamps into 2-8 character Base36 IDs that sort " \
                     "chronologically as plain strings. Seven formats from month to millisecond " \
                     "precision, with split output for hierarchical directory paths."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-b36ts/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-b36ts/CHANGELOG.md"

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
  spec.add_dependency "ace-support-config", "~> 0.9" 
  spec.add_dependency "ace-support-core", "~> 0.29" 
  spec.add_dependency "ace-support-cli", "~> 0.6" 

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.13" 
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
end
