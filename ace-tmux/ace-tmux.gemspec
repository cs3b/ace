# frozen_string_literal: true

require_relative "lib/ace/tmux/version"

Gem::Specification.new do |spec|
  spec.name = "ace-tmux"
  spec.version = Ace::Tmux::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Composable tmux session management via YAML presets"
  spec.description = "Start tmux sessions from presets and add windows on the fly without restarting. " \
                     "Compose pane, window, and session presets with deep-merge overrides across the ACE config cascade."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-tmux/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-tmux/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*
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

  # Runtime dependencies
  spec.add_dependency "ace-support-cli", "~> 0.6" 
  spec.add_dependency "ace-support-core", "~> 0.29" 
  spec.add_dependency "ace-support-config", "~> 0.9" 
  spec.add_dependency "ace-support-fs", "~> 0.3" 

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.13" 
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
