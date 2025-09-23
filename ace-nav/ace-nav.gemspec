# frozen_string_literal: true

require_relative "lib/ace/nav/version"

Gem::Specification.new do |spec|
  spec.name = "ace-nav"
  spec.version = Ace::Nav::VERSION
  spec.authors = ["ACE Development Team"]
  spec.email = ["ace-dev@example.com"]

  spec.summary = "Unified navigation and resource discovery for ACE ecosystem"
  spec.description = "ace-nav provides unified navigation and path resolution across the ACE ecosystem. " \
                     "It automatically discovers handbooks bundled within ace-* gems, resolves resource URIs " \
                     "to actual file paths, and supports a multi-level override cascade."
  spec.homepage = "https://github.com/ace-framework/ace-nav"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-core", "~> 0.1"

  # Development dependencies
  spec.add_development_dependency "ace-test-support", "~> 0.1"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "simplecov", "~> 0.22"
end