# frozen_string_literal: true

require_relative "lib/ace/hitl/contract/version"

Gem::Specification.new do |spec|
  spec.name = "ace-hitl-contract"
  spec.version = Ace::Hitl::Contract::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]
  spec.summary = "Shared HITL provider reference, result and error protocol"
  spec.description = "Pure HITL provider vocabulary shared by request orchestration and delivery adapters, " \
                     "without activating assignment or privileged HITL service dependencies."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-hitl-contract/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-hitl-contract/CHANGELOG.md"
  spec.files = Dir.glob(%w[lib/**/* *.md LICENSE Rakefile]).select { |file| File.file?(file) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "ace-support-test-helpers", "~> 0.14"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
