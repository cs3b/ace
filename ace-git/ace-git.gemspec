# frozen_string_literal: true

require_relative 'lib/ace/git/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-git'
  spec.version = Ace::Git::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = 'Git workflows and context commands for developers and AI agents'
  spec.description = 'ace-git gives developers and coding agents focused git context commands and guided ' \
                     'workflows for rebases, pull requests, and commit reorganization, with smart diff ' \
                     'output and Git 2.23+ guardrails.'
  spec.homepage = 'https://github.com/cs3b/ace/tree/main/ace-git'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/cs3b/ace'
  spec.metadata['changelog_uri'] = 'https://github.com/cs3b/ace/blob/main/ace-git/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # Include lib, exe, handbook (workflows and templates), and config examples
  spec.files = Dir.glob(%w[
                          lib/**/*
                          exe/*
                          handbook/**/*
                          docs/**/*
                          .ace-defaults/**/*
                          *.md
                          LICENSE
                          Rakefile
                        ]).select { |f| File.file?(f) }

  spec.bindir = 'exe'
  spec.executables = ['ace-git']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-support-config', '~> 0.9'
  spec.add_dependency 'ace-support-core', '~> 0.29'
  spec.add_dependency 'ace-support-cli', '~> 0.6'

  # Development dependencies
  spec.add_development_dependency 'ace-support-test-helpers', '~> 0.13'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
end
