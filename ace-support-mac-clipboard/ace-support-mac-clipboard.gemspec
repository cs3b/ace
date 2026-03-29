# frozen_string_literal: true

require_relative "lib/ace/support/mac_clipboard/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-mac-clipboard"
  spec.version = Ace::Support::MacClipboard::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "macOS NSPasteboard integration for ACE"
  spec.description = "Provides FFI-based access to macOS NSPasteboard for reading rich clipboard content (images, files, RTF, HTML)"
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-support-mac-clipboard/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-support-mac-clipboard/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.15"
end
