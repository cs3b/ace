# frozen_string_literal: true

require_relative "lib/ace/prompt/version"

Gem::Specification.new do |spec|
  spec.name = "ace-prompt"
  spec.version = Ace::Prompt::VERSION
  spec.authors = ["ACE Framework"]
  spec.email = ["noreply@example.com"]

  spec.summary = "Simple queue-based prompt workflow for AI development"
  spec.description = "Manage AI prompts with automatic archiving, context loading, and optional LLM enhancement"
  spec.homepage = "https://github.com/example/ace-prompt"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib,exe,handbook}/**/*") + %w[README.md CHANGELOG.md]
  spec.bindir = "exe"
  spec.executables = ["ace-prompt"]
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "ace-support-core", "~> 0.10"
  spec.add_dependency "ace-context", "~> 0.5"
  spec.add_dependency "ace-llm", "~> 0.5"
  spec.add_dependency "ace-nav", "~> 0.5"

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.9"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
