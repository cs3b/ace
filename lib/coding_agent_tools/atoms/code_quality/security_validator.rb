# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for running security validation using Gitleaks
      # Extracted from dev-tools/bin/lint-security
      class SecurityValidator
        attr_reader :options

        def initialize(options = {})
          @options = {
            full_scan: false,
            git_history: false,
            verbose: false
          }.merge(options)
        end

        def validate
          ensure_gitleaks_available!

          command = build_command
          output, status = execute_command(command)

          parse_results(output, status)
        end

        private

        def ensure_gitleaks_available!
          return if system("which gitleaks > /dev/null 2>&1")

          raise "Gitleaks is not installed. Please install it first.\n" \
            "  Install with: brew install gitleaks (macOS) or see https://github.com/gitleaks/gitleaks#installing"
        end

        def build_command
          cmd = ["gitleaks", "detect"]

          cmd << "--verbose" if options[:verbose]
          cmd << "--no-git" unless options[:git_history]

          # Add config file if exists
          cmd << "--config" << ".gitleaks.toml" if File.exist?(".gitleaks.toml")

          cmd.join(" ")
        end

        def execute_command(command)
          require "open3"

          stdout, stderr, status = Open3.capture3(command)
          output = stdout + stderr

          [output, status.exitstatus]
        end

        def parse_results(output, exit_code)
          {
            success: exit_code == 0,
            findings: extract_findings(output),
            exit_code: exit_code,
            output: output
          }
        end

        def extract_findings(output)
          findings = []

          # Parse Gitleaks output format
          output.each_line do |line|
            findings << ::Regexp.last_match(1).strip if line =~ /Finding:\s+(.+)/
          end

          findings
        end
      end
    end
  end
end
