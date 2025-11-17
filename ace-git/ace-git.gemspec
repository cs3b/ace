# frozen_string_literal: true

require_relative 'lib/ace/git/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-git'
  spec.version = Ace::Git::VERSION
  spec.authors = ['Michal Czyz']
  spec.email = ['mc@cs3b.com']

  spec.summary = 'Git workflow instructions for ACE projects'
  spec.description = 'Workflow-focused gem providing comprehensive git operation workflows: ' \
                     'changelog-preserving rebase, PR creation with templates, and version-based ' \
                     'commit squashing. Workflows accessible via ace-nav protocol (wfi://). ' \
                     'Requires Git >= 2.23.0.'
  spec.homepage = 'https://github.com/cs3b/ace-meta/tree/main/ace-git'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/cs3b/ace-meta'
  spec.metadata['changelog_uri'] = 'https://github.com/cs3b/ace-meta/blob/main/ace-git/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # Include lib, handbook (workflows and templates), and config examples
  spec.files = Dir.glob(%w[
                          lib/**/*
                          handbook/**/*
                          .ace.example/**/*
                          *.md
                          LICENSE
                          Rakefile
                        ]).select { |f| File.file?(f) }

  spec.bindir = 'exe'
  spec.executables = []  # No CLI executables - workflow-only package
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-support-core', '~> 0.10'

  # Development dependencies managed in root Gemfile
end
