# frozen_string_literal: true

require_relative "lib/ace/wake/version"

Gem::Specification.new do |spec|
  spec.name = "ace-wake"
  spec.version = Ace::Wake::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]
  spec.summary = "Pi agent wake extension assets for ACE (loop timers and watch subscriptions)"
  spec.description = "Publishable asset package for the ace-wake Pi harness extension: /loop timers and " \
    "/watch file subscriptions that wake idle agents. Ships the extension through the standard " \
    "handbook projection (ace-handbook sync --provider pi) and the ace-lab installer."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-wake/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-wake/CHANGELOG.md"
  spec.files = Dir.glob(%w[handbook/**/* lib/**/* *.md]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = []
  spec.require_paths = ["lib"]
end
