# frozen_string_literal: true

require_relative 'lib/ace/git_commit/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-git-commit'
  spec.version = Ace::GitCommit::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = 'LLM-powered git commit tool for ACE'
  spec.description = 'Streamlined git commit tool that leverages LLM technology to generate meaningful commit messages'
  spec.homepage = 'https://github.com/cs3b/ace-meta'
  spec.license = 'MIT'
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/ace-git-commit/CHANGELOG.md"

  # Specify which files should be added to the gem
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
  spec.add_dependency 'ace-support-core', '~> 0.24'
  spec.add_dependency 'ace-support-config', '~> 0.7'
  spec.add_dependency 'ace-git', '~> 0.11'
  spec.add_dependency 'ace-llm', '~> 0.23'

  # Development dependencies managed in root Gemfile
end

