# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Lab
    module CLI
      module Commands
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Show lab configuration and local file state (read-only)

            Distinguishes a valid empty set, missing configuration, and a
            source error. Reads files only: no services are started and no
            installer is required. The enriched worktree view stays
            ace-git-worktree list.
          DESC

          example ["--format json    # Full report as JSON"]

          option :format, type: :string, default: "table", desc: "Output format: table or json"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(status_service: nil)
            @status_service = status_service
          end

          def call(**options)
            format = options[:format] || "table"
            cli_error("Invalid format: #{format} (use table or json)") unless %w[table json].include?(format)

            report = status_service.report
            unless options[:quiet]
              puts(format == "json" ? JSON.generate(report.to_h) : render_table(report))
            end
            # Full report first; source failures then fail the command
            unless report.ok?
              raise Ace::Support::Cli::Error, "lab status reported source errors: #{first_error(report)}"
            end
          end

          private

          def status_service
            @status_service ||= Organisms::StatusService.from_config
          end

          def first_error(report)
            report.config[:error] ||
              report.runtime_config[:error] ||
              report.state.find { |location| location[:state] == :error }&.dig(:note) ||
              "unreadable state location"
          end

          def render_table(report)
            [config_line(report), runtime_line(report), "Local state (root: #{report.root}):"]
              .concat(report.state.map { |location| location_line(location) })
              .join("\n")
          end

          def config_line(report)
            config = report.config
            case config[:state]
            when :configured
              "Lab configuration: configured — #{config[:source_path]} " \
                "(topology: #{config[:topology][:projects]} project(s), " \
                "#{config[:topology][:agents]} agent(s), #{config[:topology][:services]} service(s))"
            when :defaults_only
              "Lab configuration: missing (defaults only; no .ace/lab/config.yml or ~/.ace/lab/config.yml)"
            else
              "Lab configuration: invalid — #{config[:error]}"
            end
          end

          def runtime_line(report)
            runtime = report.runtime_config
            case runtime[:state]
            when :valid
              origin = runtime[:path] || runtime[:source]
              "Runtime configuration: #{runtime[:runtime] || '(value unset)'} (#{origin})"
            when :invalid
              "Runtime configuration: invalid — #{runtime[:error]}"
            else
              "Runtime configuration: none (no config file, ACE_RUNTIME unset)"
            end
          end

          def location_line(location)
            state =
              case location[:state]
              when :present then format("present (%s)", location[:entries])
              when :prepared then "prepared"
              when :error then "ERROR"
              else "not present"
              end
            note = location[:note] ? " (#{location[:note]})" : ""
            format("  %-12s %-16s %s%s", location[:key], state, location[:path], note)
          end
        end
      end
    end
  end
end
