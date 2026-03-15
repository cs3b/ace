# frozen_string_literal: true

require_relative 'lib/ace/core/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-support-core'
  spec.version = Ace::Core::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = 'Core configuration cascade and shared functionality for ace-* gems'
  spec.description = 'Foundational infrastructure gem providing configuration cascade resolution, ' \
                     'environment variable handling, and shared utilities for all ace-* gems. ' \
                     'Library-only gem following ace-support-* pattern for infrastructure components.'
  spec.homepage = 'https://github.com/cs3b/ace-meta'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/ace-support-core/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
                          lib/**/*
                          handbook/**/*
                          config/**/*
                          .ace-defaults/**/*
                          *.md
                          LICENSE
                          Rakefile
                        ]).select { |f| File.file?(f) }

  spec.bindir = 'exe'
  spec.executables = []
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-support-config', '~> 0.7'
  spec.add_dependency 'ace-support-fs', '~> 0.2'
  spec.add_dependency 'ace-support-cli', '~> 0.3'
  # Development dependencies are managed in the root Gemfile
end
