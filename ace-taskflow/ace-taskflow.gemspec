# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ace/taskflow/version"

Gem::Specification.new do |spec|
  spec.name = "ace-taskflow"
  spec.version = Ace::Taskflow::VERSION
  spec.authors = ["Monkey Codes"]
  spec.email = ["mc@monkey.codes"]

  spec.summary = "Task and idea management for ACE"
  spec.description = "Unified task management including idea capture, task tracking, and release management"
  spec.homepage = "https://github.com/ace-meta/ace-taskflow"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ace-core", "~> 0.9.0"
  spec.add_dependency "clipboard", "~> 1.3"
  spec.add_dependency "ace-support-mac-clipboard", "~> 0.1.0"

  # No development dependencies - managed in root Gemfile
end