# frozen_string_literal: true

require_relative "lib/ace/integration/claude/version"

Gem::Specification.new do |spec|
  spec.name = "ace-integration-claude"
  spec.version = Ace::Integration::Claude::VERSION
  spec.authors = ["ACE Team"]
  spec.email = ["team@ace.dev"]

  spec.summary = "Claude Code integration workflows for ACE"
  spec.description = "Integration package containing Claude Code command templates, workflows, and tools for maintaining AI-assisted development integration"
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Include workflow and integration files
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

  # No runtime dependencies for pure integration package
  # spec.add_dependency "ace-support-core", "~> 0.10"

  # Development dependencies from root Gemfile
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end