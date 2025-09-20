# frozen_string_literal: true

require_relative "lib/ace/test_runner/version"

Gem::Specification.new do |spec|
  spec.name = "ace-test-runner"
  spec.version = Ace::TestRunner::VERSION
  spec.authors = ["Ace Meta Team"]
  spec.email = ["ace@example.com"]

  spec.summary = "Test execution and reporting tool for ace-* gems"
  spec.description = "Provides comprehensive test execution with AI-friendly output formats and detailed reporting"
  spec.homepage = "https://github.com/ace-meta/ace-test-runner"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-core", "~> 0.1"
  spec.add_dependency "ace-test-support", "~> 0.1"
  spec.add_dependency "minitest", "~> 5.0"
  spec.add_dependency "minitest-reporters", "~> 1.6"
  spec.add_dependency "ostruct"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end