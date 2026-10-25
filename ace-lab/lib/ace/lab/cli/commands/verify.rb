# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/verify"

module Ace
  module Lab
    module CLI
      module Commands
        class Verify < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          SECTION_LABELS = {
            "accounts" => "account", "directories" => "directory", "keys" => "account",
            "roles" => "id", "repositories" => "project", "grants" => "principal",
            "registry" => "project", "overseer" => "project",
            "adapters" => "adapter", "tools" => "tool", "gems" => "gem"
          }.freeze

          desc "Verify the installed lab's readiness under the target accounts (read-only): " \
            "accounts, directories, key pairs, role instructions, repository origins and " \
            "target-executor access, grant-based project visibility, private _overseer " \
            "folders, configured communication/HITL adapters, required tools, declared gem set"

          example [
            "--format json        # Machine-readable report for the overseer / next tool",
            "                      # exit 0 only when every check passes or is unknown"
          ]

          option :format, type: :string, desc: "Output format (table, json; default: table)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(verifier: nil)
            super()
            @verifier = verifier
          end

          def call(**options)
            format = options[:format] || "table"
            unless %w[table json].include?(format)
              raise Ace::Support::Cli::Error,
                "--format \"#{format}\" is not supported; table or json"
            end

            report = (@verifier || Organisms::Verify.new).call
            render(report, format: format, quiet: options[:quiet])

            # A not-ready lab never exits 0: the report renders first
            # (failure beside healthy data — both visible), then the
            # failure list names every failed check concretely.
            unless report["ready"]
              raise Ace::Support::Cli::Error, failure_summary(report)
            end
          rescue Ace::Lab::InvalidConfigurationError => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def render(report, format:, quiet:)
            return if quiet

            puts format == "json" ? JSON.generate(report) : render_table(report)
          end

          def render_table(report)
            counts = report["counts"]
            lines = ["Machine: #{report['machine']}  manifest: #{report['manifest']}"]
            report["checks"].each do |section, checks|
              lines << "#{section.capitalize}:"
              if checks.empty?
                lines << "  (none declared)"
                next
              end
              checks.each do |check|
                label = check[SECTION_LABELS.fetch(section, "reason")] || check["path"] || section
                detail = detail_of(check)
                lines << "  #{label.to_s.ljust(34)} #{check['status'].upcase}#{detail}"
                lines << "    #{check['reason']}" if check["reason"]
              end
            end
            lines << "Checks: #{counts['pass']} pass, #{counts['fail']} failed, " \
              "#{counts['unknown']} unknown"
            lines << "Result: #{report['ready'] ? 'ready' : 'NOT READY'}"
            lines.join("\n")
          end

          def detail_of(check)
            parts = []
            parts << "uid #{check['uid']}" if check.key?("uid")
            parts << "shell #{check['shell']}" if check["shell"]
            parts << "fingerprint #{check['fingerprint']}" if check["fingerprint"]
            parts << "origin #{check['origin']}" if check["origin"]
            parts << "projects #{check['projects'].join(', ')}" if check["projects"].is_a?(Array)
            parts.empty? ? "" : " (#{parts.join(', ')})"
          end

          def failure_summary(report)
            failures = report["checks"].flat_map do |section, checks|
              checks.select { |check| check["status"] == "fail" }
                .map { |check| "#{section}/#{check_name(check, section)}: #{check['reason']}" }
            end
            "lab is not ready (#{failures.size} failed check(s)): #{failures.join('; ')}"
          end

          def check_name(check, section)
            check[SECTION_LABELS.fetch(section, "reason")] || check["path"] || section
          end
        end
      end
    end
  end
end
