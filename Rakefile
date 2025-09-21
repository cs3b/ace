# frozen_string_literal: true

require "bundler/setup"

desc "Run tests for all packages"
task :test do
  packages = %w[
    ace-core
    ace-test-support
    ace-test-runner
    ace-context
  ]

  failed = []

  packages.each do |package|
    puts "\n" + "=" * 60
    puts "Testing #{package}"
    puts "=" * 60

    Dir.chdir(package) do
      unless system("bundle exec rake test")
        failed << package
      end
    end
  end

  if failed.empty?
    puts "\n✅ All tests passed!"
  else
    puts "\n❌ Tests failed in: #{failed.join(', ')}"
    exit 1
  end
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

  desc "Run tests for a specific package"
  task :package, [:name] do |_t, args|
    package = args[:name]
    unless package
      puts "Usage: rake test:package[package-name]"
      puts "Example: rake test:package[ace-core]"
      exit 1
    end

    unless Dir.exist?(package)
      puts "Package directory not found: #{package}"
      exit 1
    end

    Dir.chdir(package) do
      system("bundle exec rake test") || exit(1)
    end
  end

  desc "Run tests in CI mode (simple output)"
  task :ci do
    ENV["CI"] = "true"
    Rake::Task["test"].invoke
  end
end

desc "Install dependencies for all packages"
task :bundle do
  system("bundle install")

  %w[ace-core ace-test-support ace-test-runner ace-context].each do |package|
    puts "Installing dependencies for #{package}..."
    Dir.chdir(package) do
      system("bundle install")
    end
  end
end

task default: :test