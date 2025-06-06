# frozen_string_literal: true

require_relative "lib/coding_agent_tools/version"

Gem::Specification.new do |spec|
  spec.name = "coding_agent_tools"
  spec.version = CodingAgentTools::VERSION
  spec.authors = ["Michal Czyz"]
  spec.email = ["opensource@cs3b.com"]

  spec.summary = "A Ruby gem providing CLI tools for AI agents and developers to streamline development workflows."
  spec.description = "The Coding Agent Tools (CAT) gem offers CLI tools for AI agents and developers to automate and standardize development tasks, including LLM interaction, Git operations, and task management."
  spec.homepage = "https://github.com/your-org/coding-agent-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/your-org/coding-agent-tools"
  spec.metadata["changelog_uri"] = "https://github.com/your-org/coding-agent-tools/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "dotenv", "~> 2.0"
  spec.add_dependency "dry-cli"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
