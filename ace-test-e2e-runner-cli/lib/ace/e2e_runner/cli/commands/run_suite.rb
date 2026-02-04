# frozen_string_literal: true

require "dry/cli"

module Ace
  module E2eRunner
    module CLI
      module Commands
        class RunSuite < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Run all E2E tests across packages"

          option :provider, type: :string, desc: "LLM provider:model"
          option :timeout, type: :integer, desc: "Timeout in seconds"
          option :temperature, type: :float, desc: "LLM temperature"
          option :max_tokens, type: :integer, desc: "Max tokens"
          option :report_dir, type: :string, desc: "Report directory"
          option :parallel, type: :integer, desc: "Parallel execution"
          option :dry_run, type: :boolean, desc: "List tests without executing"
          option :config, type: :string, aliases: %w[-c], desc: "Config file path"

          def call(**options)
            orchestrator = Organisms::SuiteOrchestrator.new
            outcome = orchestrator.run(options: options)

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
          rescue Interrupt
            raise Ace::Core::CLI::Error.new("E2E test execution interrupted", exit_code: 130)
          end
        end
      end
    end
  end
end
