# frozen_string_literal: true

require "dry/cli"
require "open3"

module Ace
  module E2eRunner
    module CLI
      module Commands
        class RunTest < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Run E2E tests for a package or specific test ID"

          argument :package, required: false
          argument :test_id, required: false

          option :provider, type: :string, desc: "LLM provider:model"
          option :timeout, type: :integer, desc: "Timeout in seconds"
          option :temperature, type: :float, desc: "LLM temperature"
          option :max_tokens, type: :integer, desc: "Max tokens"
          option :report_dir, type: :string, desc: "Report directory"
          option :parallel, type: :integer, desc: "Parallel execution (suite only)"
          option :affected, type: :boolean, desc: "Run tests for packages affected by git changes"
          option :dry_run, type: :boolean, desc: "List tests without executing"
          option :config, type: :string, aliases: %w[-c], desc: "Config file path"

          def call(package: nil, test_id: nil, **options)
            orchestrator = Organisms::TestOrchestrator.new

            if options[:affected]
              packages = detect_affected_packages
              if packages.empty?
                puts "No affected packages detected."
                return 0
              end

              puts "Affected: #{packages.join(", ")}" unless options[:quiet]
              outcome = orchestrator.run_affected(packages: packages, options: options)
            else
              unless package
                raise Ace::Core::CLI::Error.new("Package argument required unless --affected is used")
              end

              puts "Running E2E tests: #{package}#{test_id ? " #{test_id}" : ""}" unless options[:quiet]
              outcome = orchestrator.run(package: package, test_id: test_id, options: options)
            end

            handle_outcome(outcome, options)
          rescue Interrupt
            raise Ace::Core::CLI::Error.new("E2E test execution interrupted", exit_code: 130)
          end

          private

          def handle_outcome(outcome, options)
            status = outcome[:status]
            results = outcome[:results]

            if status == :no_tests
              puts "No E2E tests found." unless options[:quiet]
              return 2
            end

            if status == :dry_run
              list = results.map(&:id)
              puts "Discovered #{list.length} E2E tests:" unless options[:quiet]
              list.each { |id| puts "- #{id}" }
              return 0
            end

            report_dir = outcome[:report_dir]
            puts "Report: #{report_dir}" if report_dir && !options[:quiet]

            failed = results.count(&:failure?)
            passed = results.count(&:success?)
            puts "Summary: #{passed}/#{results.length} passed" unless options[:quiet]

            failed.zero? ? 0 : 1
          end

          def detect_affected_packages
            stdout, _stderr, status = Open3.capture3("git", "diff", "--name-only")
            return [] unless status.success?

            packages = stdout.lines.map { |line| line.split("/").first }.uniq
            packages.select { |name| name.start_with?("ace-") && Dir.exist?(name) }
          end
        end
      end
    end
  end
end
