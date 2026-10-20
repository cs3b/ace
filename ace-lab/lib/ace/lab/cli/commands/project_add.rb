# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/project_add"

module Ace
  module Lab
    module CLI
      module Commands
        class ProjectAdd < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          SECTION_NAMERS = {
            "repository" => ->(item) { item["path"] || item["location"] },
            "overseer" => ->(item) { item["dir"] || item["location"] },
            "registry" => ->(item) { item["path"] || item["location"] }
          }.freeze

          desc "Register a project and make it ready for team work " \
            "(repository, private _overseer, lab config registry)"

          example [
            "atlas --path /Users/ace/lab/atlas --remote git@forge:atlas/atlas.git",
            "atlas --path /Users/ace/lab/atlas --dry-run   # Predict without mutating",
            "atlas --path /Users/ace/lab/atlas --format json"
          ]

          argument :id, type: :string, required: true, desc: "Project id (topology id)"

          option :path, type: :string, required: true, desc: "Absolute project path"
          option :remote, type: :string, desc: "Origin remote URL (git clone source)"
          option :label, type: :string, desc: "Display label recorded in the registry"
          option :dry_run, type: :boolean, desc: "Predict changes without applying them"
          option :format, type: :string, desc: "Output format (table, json; default: table)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(project_add: nil)
            super()
            @project_add = project_add
          end

          def call(**options)
            format = options[:format] || "table"
            unless %w[table json].include?(format)
              raise Ace::Support::Cli::Error,
                "--format \"#{format}\" is not supported; table or json"
            end

            path = File.expand_path(options[:path])
            organism = @project_add || Organisms::ProjectAdd.new
            report = organism.call(
              id: options[:id], path: path, remote: options[:remote],
              label: options[:label], dry_run: options[:dry_run] || false
            )
            render(report, format: format, quiet: options[:quiet])

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
            lines = ["Project: #{report['project']}  path: #{report['path']}" \
              "#{"  remote: #{report['remote']}" if report['remote']}" \
              "#{"  (dry run)" if report['dry_run']}"]
            SECTION_NAMERS.each do |section, namer|
              lines << "#{section.capitalize}:"
              item = report[section]
              detail = item["message"] ? "  #{item['message']}" : ""
              lines << "  #{namer.call(item).to_s.ljust(34)} #{item['status']}#{detail}"
            end
            lines << "Result: #{report['ok'] ? 'ok' : 'FAILED'}"
            lines.join("\n")
          end

          def failure_summary(report)
            failures = SECTION_NAMERS.map do |section, namer|
              item = report[section]
              next unless item["status"] == "failed"

              "#{section}/#{namer.call(item)}: #{item['message']}"
            end.compact
            "project add failed (#{failures.size} step(s)): #{failures.join('; ')}"
          end
        end
      end
    end
  end
end
