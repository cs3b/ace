# frozen_string_literal: true

require_relative "lib/ace/search/version"

Gem::Specification.new do |spec|
  spec.name = "ace-search"
  spec.version = Ace::Search::VERSION
  spec.authors = ["ACE Team"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Unified search tool for codebases with ripgrep/fd backends"
  spec.description = "ACE search provides intelligent file and content search with DWIM heuristics, preset support, and git-aware filtering"
  spec.homepage = "https://github.com/your-org/ace-meta"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/your-org/ace-meta"
  spec.metadata["changelog_uri"] = "https://github.com/your-org/ace-meta/blob/main/ace-search/CHANGELOG.md"

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

  # Dependencies
  spec.add_dependency "ace-core", "~> 0.9"

  # Development dependencies
  spec.add_development_dependency "ace-test-support", "~> 0.9"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
