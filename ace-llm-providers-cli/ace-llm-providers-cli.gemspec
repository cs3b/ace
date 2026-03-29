# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ace/llm/providers/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "ace-llm-providers-cli"
  spec.version       = Ace::LLM::Providers::CLI::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary       = "CLI-based LLM providers for ace-llm"
  spec.description   = "Extends ace-llm with CLI-based LLM providers like Claude Code, Codex, Gemini CLI, OpenCode, and pi-agent"
  spec.homepage      = "https://github.com/cs3b/ace"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-llm-providers-cli/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-llm-providers-cli/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*
    handbook/**/*
    exe/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "ace-llm", "~> 0.30" 

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
