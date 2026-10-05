# frozen_string_literal: true

require_relative "lib/ace/hitl/hermes/version"

Gem::Specification.new do |spec|
  spec.name = "ace-hitl-hermes"
  spec.version = Ace::Hitl::Hermes::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Folder-as-interface HITL transport plugin for the hermes relay"
  spec.description = "ace-hitl-hermes treats the shared lab <-> hermes folder as the HITL " \
                     "transport: a message is a file, the address is <machine>/<folder>/<id>, " \
                     "delivery is push, and ACK is deletion. The plugin owns the channel " \
                     "registry, notification texts, and the versioned message formats " \
                     "(ace.hitl.hermes.message/v1), with atomic same-directory tmp+rename " \
                     "writes, fail-closed validation, quarantine, and bounded retries."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-hitl-hermes/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-hitl-hermes/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    plugin/**/*
    handbook/**/*
    docs/**/*
    exe/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ace-hitl-contract", "~> 0.2"
  spec.add_dependency "ace-hitl", "~> 0.12"
  spec.add_dependency "ace-support-cli", "~> 0.6"
  spec.add_dependency "faraday", "~> 2.14"

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.14"
  spec.add_development_dependency "minitest", "~> 5.19"
  spec.add_development_dependency "rake", "~> 13.0"
end
