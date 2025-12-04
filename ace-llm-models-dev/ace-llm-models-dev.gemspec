# frozen_string_literal: true

require_relative "lib/ace/llm/models_dev/version"

Gem::Specification.new do |spec|
  spec.name = "ace-llm-models-dev"
  spec.version = Ace::LLM::ModelsDev::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Model validation and cost tracking via models.dev"
  spec.description = "Integrates with models.dev API to provide model validation, " \
                     "cost tracking, and change monitoring for 40+ LLM providers. " \
                     "Validate model names, calculate query costs, and track pricing changes."
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-llm-models-dev/CHANGELOG.md"

  spec.files = Dir.glob(%w[
                          lib/**/*
                          exe/*
                          *.md
                          LICENSE.txt
                          Rakefile
                        ]).select { |f| File.file?(f) }

  spec.bindir = "exe"
  spec.executables = ["ace-llm-models"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "thor", "~> 1.3"

  # Development dependencies managed in root Gemfile
end
