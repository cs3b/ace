# frozen_string_literal: true

require_relative 'lib/ace/git_commit/version'

Gem::Specification.new do |spec|
  spec.name = 'ace-git-commit'
  spec.version = Ace::GitCommit::VERSION
  spec.authors = ['ACE Team']
  spec.email = ['ace@example.com']

  spec.summary = 'LLM-powered git commit tool for ACE'
  spec.description = 'Streamlined git commit tool that leverages LLM technology to generate meaningful commit messages'
  spec.homepage = 'https://github.com/ace-meta/ace-git-commit'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git))})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ace-core', '~> 0.9.0'
  spec.add_dependency 'ace-llm', '~> 0.9.0'

  # Development dependencies managed in root Gemfile
end

