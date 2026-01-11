# frozen_string_literal: true

require_relative 'lib/ace/prompt/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-prompt'
  spec.version = Ace::Prompt::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = 'Prompt workspace with automatic archiving'
  spec.description = 'Provides a single active prompt file with automatic history archiving. ' \
                     'Write prompts in your editor, run ace-prompt, get automatic archiving ' \
                     'with optional context loading and LLM enhancement.'
  spec.homepage = 'https://github.com/cs3b/ace-meta'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/ace-prompt/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
                          lib/**/*
                          handbook/**/*
                          config/**/*
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
  spec.add_dependency 'ace-support-config', '~> 0.6'
  spec.add_dependency 'ace-context', '~> 0.8'
  spec.add_dependency 'ace-git', '~> 0.3' # Unified git operations (task 140.04)
  spec.add_dependency 'ace-llm', '~> 0.8'
  spec.add_dependency 'ace-nav', '~> 0.8'
  spec.add_dependency 'ace-support-core', '~> 0.9' # dry-cli infrastructure (task 179.01)
  spec.add_dependency 'ace-taskflow', '~> 0.9'
  spec.add_dependency 'ace-timestamp', '~> 0.1' # Base36 compact IDs (task 149)
  spec.add_dependency 'dry-cli', '~> 1.0'

  # Development dependencies managed in root Gemfile
end
