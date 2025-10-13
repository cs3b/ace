# frozen_string_literal: true

require_relative "lib/ace/lint/version"

Gem::Specification.new do |spec|
  spec.name = "ace-lint"
  spec.version = Ace::Lint::VERSION
  spec.authors = ["ace-meta"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Ruby-only linting gem for markdown, YAML, and frontmatter validation"
  spec.description = "ace-lint provides comprehensive validation for markdown (kramdown), YAML (Psych), and frontmatter using only Ruby dependencies. No Node.js or Python required."
  spec.homepage = "https://github.com/your-org/ace-lint"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/your-org/ace-lint"
  spec.metadata["changelog_uri"] = "https://github.com/your-org/ace-lint/blob/main/CHANGELOG.md"

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

  # Runtime dependencies - Ruby-only stack
  spec.add_dependency "ace-core", "~> 0.9"
  spec.add_dependency "kramdown", "~> 2.4"
  spec.add_dependency "kramdown-parser-gfm", "~> 1.1"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "colorize", "~> 1.1"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
