# frozen_string_literal: true

require_relative 'lib/ace/core/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-core'
  spec.version = Ace::Core::VERSION
  spec.authors = ['Michal Czyz']
  spec.email = ['mc@cs3b.com']

  spec.summary = 'Core configuration cascade and shared functionality for ace-* gems'
  spec.description = 'Foundational gem providing configuration cascade resolution, ' \
                     'environment variable handling, and shared utilities for all ace-* gems. ' \
                     'Implements .ace config search with deep merging and no external dependencies.'
  spec.homepage = 'https://github.com/cs3b/ace-meta'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
                          lib/**/*
                          config/**/*
                          *.md
                          LICENSE.txt
                          Rakefile
                        ]).select { |f| File.file?(f) }

  spec.bindir = 'exe'
  spec.executables = []
  spec.require_paths = ['lib']

  # No runtime dependencies - using only Ruby stdlib
  # Development dependencies are managed in the root Gemfile
end
