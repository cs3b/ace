# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/install"
require_relative "verify"

module Ace
  module Lab
    module CLI
      module Commands
        class Install < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          # Step names inside a per-project report (ProjectAdd shape).
          PROJECT_STEPS = %w[repository overseer registry owner].freeze

          desc "Perform the full new-lab installation from the trusted install manifest " \
            "(prepare, per-project project add, trusted-tier grants)"

          example [
            "--dry-run            # Predict every phase without mutating",
            "--format json        # Machine-readable report"
          ]

          option :dry_run, type: :boolean, desc: "Predict changes without applying them"
          option :format, type: :string, desc: "Output format (table, json; default: table)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(install: nil)
            super()
            @install = install
          end

          def call(**options)
            format = options[:format] || "table"
            unless %w[table json].include?(format)
              raise Ace::Support::Cli::Error,
                "--format \"#{format}\" is not supported; table or json"
            end

            organism = @install || Organisms::Install.new
            report = organism.call(dry_run: options[:dry_run] || false)
            render(report, format: format, quiet: options[:quiet])

            # Same contract as prepare/project add: a wet run with
            # failed steps never exits 0 — the report renders first,
            # then the failure list names each step explicitly. Dry-run
            # conflicts are predicted failures, not execution failures
            # — exit 0 so callers can script a preview.
            unless report["ok"] || report["dry_run"]
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
            lines = ["Machine: #{report['machine']}  manifest: #{report['manifest']}" \
              "#{"  (dry run)" if report['dry_run']}"]

            lines << "Prepare: #{report['prepare']['ok'] ? 'ok' : 'FAILED'}"
            prepare_failures(report['prepare']).each do |line|
              lines << "  #{line}"
            end

            lines << "Projects:"
            if report["projects"].empty?
              lines << "  (none declared)"
            else
              report["projects"].each do |project|
                steps = PROJECT_STEPS.map { |step| "#{step}: #{project[step]['status']}" }.join(", ")
                lines << "  #{project['project'].to_s.ljust(34)} " \
                  "#{project['ok'] ? 'ok' : 'FAILED'} (#{steps})"
                PROJECT_STEPS.each do |step|
                  lines << "    #{step}: #{project[step]['message']}" if project[step]["message"]
                end
              end
            end

            grants = report["grants"]
            lines << "Grants (#{grants['path']}): #{grants['status']}"
            grants["principals"].each do |principal, status|
              lines << "  #{principal.to_s.ljust(34)} #{status}"
            end
            lines << "  #{grants['message']}" if grants["message"]

            lines.concat(render_verify(report["verify"]))

            lines << "Result: #{report['ok'] ? 'ok' : 'FAILED'}"
            lines.join("\n")
          end

          # Final install verification stage: the readiness verdict with
          # every failed check named (adapters and tools included).
          def render_verify(verify_report)
            return ["Verify: skipped (#{verify_report['message']})"] if verify_report["status"] == "skipped"

            counts = verify_report["counts"] || {}
            verdict = verify_report["ready"] ? "ready" : "NOT READY"
            lines = ["Verify: #{verdict} (#{counts.fetch('pass', 0)} pass, " \
              "#{counts.fetch('fail', 0)} failed, #{counts.fetch('unknown', 0)} unknown)"]
            Ace::Lab::CLI::Commands::Verify::SECTION_LABELS.each do |section, label_key|
              Array(verify_report.dig("checks", section)).each do |check|
                next unless check["status"] == "fail"

                name = check[label_key] || check["path"] || section
                lines << "  #{section}/#{name}: #{check['reason']}"
              end
            end
            lines
          end

          def prepare_failures(prepare_report)
            Ace::Lab::CLI::Commands::Prepare::SECTION_NAMERS.flat_map do |section, namer|
              prepare_report[section]
                .select { |item| item["status"] == "failed" }
                .map { |item| "#{section}/#{namer.call(item)}: #{item['message']}" }
            end
          end

          def failure_summary(report)
            failures = prepare_failures(report["prepare"])
            report["projects"].each do |project|
              PROJECT_STEPS.each do |step|
                item = project[step]
                failures << "projects/#{project['project']}/#{step}: #{item['message']}" \
                  if item["status"] == "failed"
              end
            end
            if report["grants"]["status"] == "failed"
              failures << "grants: #{report['grants']['message']}"
            end
            verify_report = report["verify"]
            if verify_report.is_a?(Hash) && verify_report["ready"] == false
              Ace::Lab::CLI::Commands::Verify::SECTION_LABELS.each do |section, label_key|
                Array(verify_report.dig("checks", section)).each do |check|
                  next unless check["status"] == "fail"

                  name = check[label_key] || check["path"] || section
                  failures << "verify/#{section}/#{name}: #{check['reason']}"
                end
              end
              failures << "verify: #{verify_report['message']}" if verify_report["message"]
            end
            "install failed (#{failures.size} step(s)): #{failures.join('; ')}"
          end
        end
      end
    end
  end
end
