# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/prepare"

module Ace
  module Lab
    module CLI
      module Commands
        class Prepare < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          # One shared section-namer map: the table renderer and the
          # failure summary must name items identically.
          SECTION_NAMERS = {
            "accounts" => ->(item) { item["username"] },
            "directories" => ->(item) { item["path"] },
            "keys" => ->(item) { "#{item['account']}:#{item['path']}" },
            "roles" => ->(item) { item["id"] }
          }.freeze

          desc "Prepare accounts, directories, permissions, keys and roles from the trusted install manifest"

          example [
            "--dry-run            # Predict all sections without mutating",
            "--format json        # Machine-readable report"
          ]

          option :dry_run, type: :boolean, desc: "Predict changes without applying them"
          option :format, type: :string, desc: "Output format (table, json; default: table)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(prepare: nil)
            super()
            @prepare = prepare
          end

          def call(**options)
            format = options[:format] || "table"
            unless %w[table json].include?(format)
              raise Ace::Support::Cli::Error,
                "--format \"#{format}\" is not supported; table or json"
            end

            organism = @prepare || Organisms::Prepare.new
            report = organism.call(dry_run: options[:dry_run] || false)
            render(report, format: format, quiet: options[:quiet])

            # A wet run with failed items never exits 0: the report renders
            # first, then the failure list names each item explicitly.
            # Dry-run conflicts are predicted failures, not execution
            # failures — exit 0 so callers can script a preview.
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
            SECTION_NAMERS.each do |section, namer|
              lines << "#{section.capitalize}:"
              items = report[section]
              if items.empty?
                lines << "  (none declared)"
              else
                items.each do |item|
                  lines << "  #{namer.call(item).to_s.ljust(34)} #{item['status']}" \
                    "#{"  #{item['message']}" if item['message']}"
                end
              end
            end
            lines << "Result: #{report['ok'] ? 'ok' : 'FAILED'}"
            lines.join("\n")
          end

          def failure_summary(report)
            failures = SECTION_NAMERS.flat_map do |section, namer|
              report[section]
                .select { |item| item["status"] == "failed" }
                .map { |item| "#{section}/#{namer.call(item)}: #{item['message']}" }
            end
            "prepare failed (#{failures.size} item(s)): #{failures.join('; ')}"
          end
        end
      end
    end
  end
end
