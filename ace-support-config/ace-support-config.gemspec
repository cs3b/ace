# frozen_string_literal: true

require_relative "lib/ace/support/config/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-config"
  spec.version = Ace::Support::Config::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Generic configuration cascade management"
  spec.description = "Reusable configuration cascade with customizable folder names. " \
                     "Supports project-level, user-level, and gem-level configuration " \
                     "with deep merging and priority-based resolution."
  spec.homepage = "https://github.com/cs3b/ace/tree/main/ace-support-config"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # RubyGems defaults unset gemspec dates to 1980-01-02, so set an explicit release date.
  # rubocop:disable Gemspec/DeprecatedAttributeAssignment
  spec.date = Time.now.utc.strftime("%Y-%m-%d")
  # rubocop:enable Gemspec/DeprecatedAttributeAssignment

  # Runtime dependencies
  spec.add_dependency "ace-support-fs", "~> 0.3"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.files = Dir.glob(%w[
    lib/**/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/"
  spec.metadata["changelog_uri"] = "https://github.com/cs3b/ace/blob/main/ace-support-config/CHANGELOG.md"
end
