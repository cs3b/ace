# frozen_string_literal: true

require_relative 'lib/ace/test_support/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-test-support'
  spec.version = Ace::TestSupport::VERSION
  spec.authors = ['Michal Czyz']
  spec.email = ['mc@cs3b.com']

  spec.summary = 'Shared test utilities for ace-* gems'
  spec.description = 'Development-only gem providing shared test utilities, base test cases, ' \
                     'and helpers for all ace-* gems. Includes configuration helpers, ' \
                     'test environment management, and common test patterns.'
  spec.homepage = 'https://github.com/cs3b/ace-meta'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
                          lib/**/*
                          *.md
                          LICENSE.txt
                          Rakefile
                        ]).select { |f| File.file?(f) }

  spec.bindir = 'exe'
  spec.executables = []
  spec.require_paths = ['lib']

  # Runtime dependencies for test support
  spec.add_dependency 'minitest', '~> 5.20'
  spec.add_dependency 'minitest-reporters', '~> 1.6'

  # Development dependencies are managed in the root Gemfile
end