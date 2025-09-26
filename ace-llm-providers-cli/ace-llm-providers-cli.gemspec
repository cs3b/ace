# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ace/llm/providers/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "ace-llm-providers-cli"
  spec.version       = Ace::LLM::Providers::CLI::VERSION
  spec.authors       = ["AI Development Team"]
  spec.email         = ["ai-dev@example.com"]

  spec.summary       = "CLI-based LLM providers for ace-llm"
  spec.description   = "Extends ace-llm with CLI-based LLM providers like Claude Code, Codex, and OpenCode"
  spec.homepage      = "https://github.com/yourusername/ace-llm-providers-cli"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|github)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "ace-llm", "~> 0.9.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end