# frozen_string_literal: true

require_relative 'lib/ace/review/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-review'
  spec.version = Ace::Review::VERSION
  spec.authors = ['ACE Meta']
  spec.email = ['ace-meta@example.com']

  spec.summary = 'Automated code review tool for the ACE framework'
  spec.description = 'ace-review enables automated code review and quality analysis using LLM-powered ' \
                     'insights, supporting preset-based workflows and release integration with ace-taskflow'
  spec.homepage = 'https://github.com/ace-meta/ace-review'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob('{lib,exe}/**/*') + %w[
    ace-review.gemspec
    README.md
    CHANGELOG.md
    LICENSE.txt
    Rakefile
  ]
  spec.bindir = 'exe'
  spec.executables = ['ace-review']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-core', '~> 0.9'
  spec.add_dependency 'ace-context', '~> 0.9'
  spec.add_dependency 'ace-nav', '~> 0.9'

  # Development dependencies
  spec.add_development_dependency 'ace-test-support', '~> 0.1'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
end

