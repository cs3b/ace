# frozen_string_literal: true

# Standardized SimpleCov configuration for ACE gems
#
# This module provides consistent coverage configuration across all ace-* gems,
# following the ATOM architecture pattern for grouping.
#
# Usage in gem test_helper.rb:
#   require 'ace/test_support/coverage'
#   Ace::TestSupport::Coverage.start('ace-mygem')
#
# Configuration via environment variables:
#   COVERAGE=1           - Enable coverage reporting
#   COVERAGE_MIN=90      - Set minimum coverage threshold (default: 90)
#   COVERAGE_HTML=1      - Generate HTML report (default: true)
#   COVERAGE_JSON=1      - Generate JSON report for CI
module Ace
  module TestSupport
    module Coverage
      # Start SimpleCov with standardized configuration
      #
      # @param gem_name [String] Name of the gem (used for filtering and paths)
      # @param options [Hash] Additional configuration options
      # @option options [Integer] :minimum_coverage Minimum coverage percentage (default: 90)
      # @option options [Boolean] :html_report Generate HTML report (default: true)
      # @option options [Boolean] :json_report Generate JSON report for CI (default: from ENV)
      # @option options [Array<String>] :groups Additional coverage groups
      #
      # @example Basic usage
      #   Ace::TestSupport::Coverage.start('ace-review')
      #
      # @example Custom minimum coverage
      #   Ace::TestSupport::Coverage.start('ace-search', minimum_coverage: 85)
      #
      # @example Additional groups
      #   Ace::TestSupport::Coverage.start('ace-taskflow', groups: {
      #     'CLI' => 'lib/ace/taskflow/cli'
      #   })
      def self.start(gem_name, options = {})
        return unless enabled?

        require "simplecov"

        # Default options
        minimum_coverage = options[:minimum_coverage] || ENV.fetch("COVERAGE_MIN", 90).to_i
        html_report = options.fetch(:html_report, true)
        json_report = options.fetch(:json_report, ENV["COVERAGE_JSON"] == "1")

        SimpleCov.start do
          # Set coverage directory
          coverage_dir "coverage"

          # Enable branch coverage (Ruby 2.5+)
          enable_coverage :branch if respond_to?(:enable_coverage)

          # Add standard filters
          add_filter "/test/"
          add_filter "/spec/"
          add_filter "/.bundle/"
          add_filter "/vendor/"

          # ATOM architecture groups
          add_group "Atoms", "lib/#{gem_path(gem_name)}/atoms"
          add_group "Molecules", "lib/#{gem_path(gem_name)}/molecules"
          add_group "Organisms", "lib/#{gem_path(gem_name)}/organisms"
          add_group "Models", "lib/#{gem_path(gem_name)}/models"
          add_group "Commands", "lib/#{gem_path(gem_name)}/commands"
          add_group "CLI", "lib/#{gem_path(gem_name)}/cli"

          # Additional custom groups
          if options[:groups]
            options[:groups].each do |name, pattern|
              add_group name, pattern
            end
          end

          # Set minimum coverage
          if minimum_coverage > 0
            minimum_coverage minimum_coverage
            minimum_coverage_by_file 80 # Allow some flexibility per file
          end

          # Configure formatters
          formatters = []
          formatters << SimpleCov::Formatter::HTMLFormatter if html_report

          if json_report
            require "simplecov-json"
            formatters << SimpleCov::Formatter::JSONFormatter
          end

          SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(formatters) unless formatters.empty?

          # Track files even with 0% coverage
          track_files "lib/#{gem_path(gem_name)}/**/*.rb"

          # Project name for reports
          project_name gem_name
        end
      end

      # Check if coverage is enabled
      #
      # @return [Boolean] True if COVERAGE environment variable is set
      def self.enabled?
        ENV["COVERAGE"] == "1" || ENV["COVERAGE"] == "true"
      end

      # Get SimpleCov result
      #
      # @return [SimpleCov::Result, nil] Coverage result if available
      def self.result
        return nil unless defined?(SimpleCov)

        SimpleCov.result
      end

      # Print coverage summary to stdout
      #
      # @param result [SimpleCov::Result] Coverage result (optional, uses last result if not provided)
      def self.print_summary(result = nil)
        result ||= self.result
        return unless result

        puts "\n" + "=" * 80
        puts "Coverage Summary for #{result.command_name}"
        puts "=" * 80

        puts "\nOverall: #{format("%.2f", result.covered_percent)}% covered"

        if result.respond_to?(:groups)
          puts "\nBy Group:"
          result.groups.each do |name, files|
            coverage = (files.covered_lines.to_f / files.lines_of_code * 100)
            puts "  #{name.ljust(20)} #{format("%6.2f", coverage)}%  (#{files.covered_lines}/#{files.lines_of_code} lines)"
          end
        end

        puts "=" * 80 + "\n"
      end

      # Generate gem path from gem name
      # Converts gem names like 'ace-git-worktree' to 'ace/git/worktree'
      #
      # @param gem_name [String] Gem name (e.g., 'ace-review')
      # @return [String] Path segment (e.g., 'ace/review')
      #
      # @api private
      def self.gem_path(gem_name)
        gem_name.tr("-", "/")
      end

      private_class_method :gem_path
    end
  end
end
