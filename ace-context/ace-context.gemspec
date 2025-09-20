# frozen_string_literal: true

require_relative 'lib/ace/context/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-context'
  spec.version = Ace::Context::VERSION
  spec.authors = ['Michal Czyz']
  spec.email = ['mc@cs3b.com']

  spec.summary = 'Context loading for ACE projects'
  spec.description = 'Context loading gem for ACE projects. Provides preset-based context ' \
                     'loading with configuration cascade support via ace-core. Supports ' \
                     'multiple file formats and dynamic content generation.'
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
                          exe/*
                          *.md
                          LICENSE.txt
                          Rakefile
                        ]).select { |f| File.file?(f) }

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-core', '~> 0.9.0'

  # Development dependencies managed in root Gemfile
end