# frozen_string_literal: true

require_relative "lib/ace/docs/version"

Gem::Specification.new do |spec|
  spec.name = "ace-docs"
  spec.version = Ace::Docs::VERSION
  spec.authors = ["ACE Team"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Documentation management with frontmatter, change analysis, and intelligent updates"
  spec.description = "Comprehensive documentation management system combining deterministic tooling with intelligent workflow orchestration. Discovers documents via frontmatter, analyzes changes, validates against rules, and supports iterative agent/human collaboration."
  spec.homepage = "https://github.com/ace-meta/ace-docs"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-core", "~> 0.1"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "yaml", "~> 0.3"
  spec.add_dependency "colorize", "~> 1.1"
  spec.add_dependency "terminal-table", "~> 3.0"
  spec.add_dependency "fileutils", "~> 1.7"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
