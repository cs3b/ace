# frozen_string_literal: true

require_relative "lib/ace/handbook/version"

Gem::Specification.new do |spec|
  spec.name = "ace-handbook"
  spec.version = Ace::Handbook::VERSION
  spec.authors = ["ACE Team"]
  spec.email = ["team@ace.dev"]

  spec.summary = "Handbook management workflows for ACE"
  spec.description = "Pure workflow package containing handbook management workflows, templates, guides, and agents accessible via wfi:// protocol"
  spec.homepage = "https://github.com/cs3b/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # No runtime dependencies for pure workflow package
  # spec.add_dependency "ace-support-core", "~> 0.10"

  # Development dependencies from root Gemfile
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end