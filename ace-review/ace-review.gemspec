# frozen_string_literal: true

require_relative 'lib/ace/review/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-review'
  spec.version = Ace::Review::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = 'Automated code review tool for the ACE framework'
  spec.description = 'ace-review enables automated code review and quality analysis using LLM-powered ' \
                     'insights, supporting preset-based workflows and release integration with ace-taskflow'
  spec.homepage = 'https://github.com/cs3b/ace'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/ace-review/CHANGELOG.md"

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
  spec.bindir = 'exe'
  spec.executables = ['ace-review']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-support-cli', '~> 0.3'
  spec.add_dependency 'ace-support-config', '~> 0.7'
  spec.add_dependency 'ace-b36ts', '~> 0.7'
  spec.add_dependency 'ace-support-core', '~> 0.24' # For ProcessTerminator
  spec.add_dependency 'ace-bundle', '~> 0.31'
  spec.add_dependency 'ace-git', '~> 0.11'
  # Note: ace-git-diff dependency removed in v0.26.0 - functionality migrated to ace-git
  spec.add_dependency 'ace-support-nav', '~> 0.18'
  spec.add_dependency 'ace-llm', '~> 0.23'
  spec.add_dependency 'ace-task', '~> 0.11'

  # Development dependencies
  spec.add_development_dependency 'ace-support-test-helpers', '~> 0.12'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
end

