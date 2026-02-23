# frozen_string_literal: true

require "bundler/setup"

desc "Run tests for all packages (DEPRECATED: use ace-test-suite instead)"
task :test do
  warn "WARNING: `rake test` is deprecated. Use `ace-test-suite` instead."
  warn "         See CLAUDE.md for testing conventions."
  warn ""
  warn "Delegating to `rake test:suite`..."
  Rake::Task["test:suite"].invoke
end

namespace :test do
  desc "Run all tests using the test suite orchestrator"
  task :suite do
    require_relative "ace-test-runner/lib/ace/test_runner"
    require_relative "ace-test-runner/lib/ace/test_runner/suite/display_manager"
    require_relative "ace-test-runner/lib/ace/test_runner/suite/process_monitor"
    require_relative "ace-test-runner/lib/ace/test_runner/suite/result_aggregator"
    require_relative "ace-test-runner/lib/ace/test_runner/suite/orchestrator"

    orchestrator = Ace::TestRunner::Suite::Orchestrator.new
    exit_code = orchestrator.run
    exit(exit_code)
  end

  desc "Run tests for a specific package (DEPRECATED: use ace-test <path> instead)"
  task :package, [:name] do |_t, args|
    package = args[:name]
    unless package
      warn "Usage: ace-test <package-name>"
      warn "Example: ace-test ace-support-core"
      exit 1
    end

    warn "WARNING: `rake test:package[#{package}]` is deprecated. Use `ace-test` instead:"
    warn "         ace-test   (from within the package directory)"
    warn ""

    unless Dir.exist?(package)
      warn "Package directory not found: #{package}"
      exit 1
    end

    Dir.chdir(package) do
      system("ace-test") || exit(1)
    end
  end

  desc "Run tests in CI mode"
  task :ci do
    ENV["CI"] = "true"
    Rake::Task["test:suite"].invoke
  end
end

task default: :test
