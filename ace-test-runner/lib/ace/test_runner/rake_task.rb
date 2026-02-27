# frozen_string_literal: true

require "rake"
require "rake/tasklib"

module Ace
  module TestRunner
    # Custom Rake task that uses ace-test instead of standard Minitest runner
    # This allows seamless integration with existing Rake workflows
    class RakeTask < Rake::TaskLib
      attr_accessor :name, :description, :libs, :pattern, :verbose, :format,
                    :warning, :loader, :options, :test_files

      def initialize(name = :test)
        @name = name
        @description = "Run tests with ace-test"
        @libs = %w[test lib]
        @pattern = "test/**/*_test.rb"
        @verbose = false
        @format = nil
        @warning = false
        @loader = nil
        @options = nil
        @test_files = nil

        yield self if block_given?
        define
      end

      def define
        desc @description
        task @name do
          run_tests
        end
      end

      private

      def run_tests
        # Build ace-test command
        command = build_command

        # Execute ace-test with sanitized environment
        # Strip assignment context vars to prevent tests from resolving to wrong assignments
        puts command if verbose
        env = ENV.to_h.merge({
          "ACE_ASSIGN_ID" => nil,
          "ACE_ASSIGN_FORK_ROOT" => nil
        })
        success = system(env, command)

        # Exit with proper code for CI/CD
        exit(1) unless success
      end

      def build_command
        cmd = ["ace-test"]

        # Add format if specified
        cmd << "--format" << format if format

        # Add verbose flag
        cmd << "--verbose" if verbose

        # Handle TEST environment variable (specific test file)
        if ENV["TEST"]
          cmd << ENV["TEST"]
        elsif test_files
          # Handle explicit test files
          cmd.concat(Array(test_files))
        elsif pattern
          # Use pattern to find files (ace-test will handle this internally)
          # For now, we'll let ace-test use its default detection
        end

        # Handle TESTOPTS environment variable
        if ENV["TESTOPTS"]
          # Parse TESTOPTS and add to command
          opts = ENV["TESTOPTS"].split(/\s+/)
          cmd.concat(opts)
        end

        # Add any additional options
        cmd.concat(Array(options)) if options

        cmd.join(" ")
      end

    end
  end
end