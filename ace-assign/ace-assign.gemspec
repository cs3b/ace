# frozen_string_literal: true

require_relative "lib/ace/assign/version"

Gem::Specification.new do |spec|
  spec.name = "ace-assign"
  spec.version = Ace::Assign::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["mc@cs3b.com"]

  spec.summary = "Multi-step assignment execution with nesting, fork delegation, and inspectable traces"
  spec.description = "Turns work into multi-step assignments with nested substeps, fork delegation to long-running agent subprocesses, and inspectable session traces. Steps are defined from a catalog, assembled via presets, and driven through a restartable queue."
  spec.homepage = "https://github.com/cs3b/ace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/ace-assign/"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/ace-assign/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*
    exe/*
    docs/**/*
    handbook/**/*
    .ace-defaults/**/*
    *.md
    LICENSE
    Rakefile
  ]).select { |f| File.file?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "ace-support-cli", "~> 0.6" 
  spec.add_dependency "ace-support-core", "~> 0.29" 
  spec.add_dependency "ace-support-config", "~> 0.9" 
  spec.add_dependency "ace-support-nav", "~> 0.25" 
  spec.add_dependency "ace-b36ts", "~> 0.13" 
  spec.add_dependency "ace-support-markdown", "~> 0.3" 
  spec.add_dependency "ace-llm", "~> 0.30" 
  spec.add_dependency "ace-task", "~> 0.31" 

  # Development dependencies
  spec.add_development_dependency "ace-support-test-helpers", "~> 0.13" 
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
