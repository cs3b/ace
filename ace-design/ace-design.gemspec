# frozen_string_literal: true
require_relative "lib/ace/design/version"
Gem::Specification.new do |spec|
  spec.name = "ace-design"
  spec.version = Ace::Design::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]
  spec.summary = "Fast interactive web design directions, production handoff and browser evidence"
  spec.description = "Shared site/app design workflows, local mockup previews, browser inspection and curated inspiration."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-design"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-design/CHANGELOG.md"
  spec.files = Dir.glob(%w[lib/**/* exe/* handbook/**/* browser/* docs/**/* .ace-defaults/**/* *.md LICENSE Rakefile]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = ["ace-design"]
  spec.require_paths = ["lib"]
  spec.add_dependency "ace-support-cli", "~> 0.6"
  spec.add_dependency "ace-support-config", "~> 0.18"
  spec.add_dependency "ace-llm", "~> 0.42"
  spec.add_dependency "ace-llm-providers-cli", "~> 0.36.2"
  spec.add_dependency "ace-bundle", "~> 0.45"
  spec.add_dependency "ace-b36ts", "~> 0.14"
  spec.add_dependency "ace-support-core", "~> 0.32"
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
end
