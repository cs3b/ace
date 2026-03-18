# frozen_string_literal: true

require_relative 'lib/ace/bundle/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-bundle'
  spec.version = Ace::Bundle::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = 'Bundle loading for ACE projects'
  spec.description = 'Bundle loading gem for ACE projects. Provides preset-based bundle ' \
                     'loading with configuration cascade support via ace-support-core. Supports ' \
                     'multiple file formats and dynamic content generation.'
  spec.homepage = 'https://github.com/cs3b/ace'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/ace-bundle/CHANGELOG.md"

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
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-support-cli', '~> 0.3'
  spec.add_dependency 'ace-support-config', '~> 0.7'
  spec.add_dependency 'ace-support-core', '~> 0.24' # For FileAggregator, OutputFormatter, etc.
  spec.add_dependency 'ace-support-fs', '~> 0.2' # For ProjectRootFinder
  # ace-git: Centralized Git/GitHub operations (diffs, PR metadata, branch info)
  # Replaces internal GitExtractor, PrIdentifierParser, GhPrExecutor (removed in v0.20.0)
  spec.add_dependency 'ace-git', '~> 0.11'
  spec.add_dependency 'ace-support-nav', '~> 0.18' # For in-process protocol resolution (wfi://, guide://, etc.)
  spec.add_dependency 'ace-compressor', '~> 0.21' # For --compress option (section content compression)

  # Development dependencies managed in root Gemfile
end
