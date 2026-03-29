# frozen_string_literal: true

require_relative "lib/ace/handbook/integration/gemini/version"

Gem::Specification.new do |spec|
  spec.name = "ace-handbook-integration-gemini"
  spec.version = Ace::Handbook::Integration::Gemini::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]
  spec.summary = "Gemini provider integration for ACE handbook skills"
  spec.description = "Gemini-specific provider integration package that extends ace-handbook with provider manifests."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-handbook-integration-gemini/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-handbook-integration-gemini/CHANGELOG.md"
  spec.files = Dir.glob(%w[lib/**/* .ace-defaults/**/* *.md LICENSE Rakefile]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = []
  spec.require_paths = ["lib"]
  spec.add_dependency "ace-handbook", "~> 0.21" 
end
