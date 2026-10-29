# frozen_string_literal: true

require "json"

module Ace
  module Overseer
    module CLI
      module Commands
        # `ace-overseer start [--dry-run] [--format table|json]`
        # (task 8xs.t.pu0.1): starts or reuses the project overseer
        # session from the directory's explicit start configuration.
        # Exit 0 only for started/reused (dry-run reports the plan with
        # exit 0 but creates nothing); a blocked start is a CLI error.
        class Start < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Start or reuse the project overseer session from .ace/overseer/config.yml"

          option :dry_run, type: :boolean, default: false, desc: "Show the start plan without creating a session"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil, config: nil)
            super()
            @orchestrator = orchestrator
            @config = config
          end

          def call(dry_run: false, format: "table", **options)
            report = orchestrator.call(dry_run: dry_run)

            if options[:quiet]
              # quiet still fails loudly on a blocked start
            elsif format == "json"
              puts JSON.pretty_generate(report)
            else
              render_table(report)
            end

            case report["status"]
            when "started", "reused", "dry_run" then nil
            else
              raise Ace::Support::Cli::Error, report["message"] || "start blocked"
            end
          rescue Ace::Support::Cli::Error
            raise
          rescue => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          def orchestrator
            @orchestrator || Organisms::StartOrchestrator.new(config: @config || Ace::Overseer.config)
          end

          def render_table(report)
            puts "ace-overseer start: #{report['status']}"
            puts "  scope:         #{report['scope'] || '-'}"
            puts "  root:          #{report['root'] || '-'}"
            puts "  label:         #{report['label'] || '-'}"
            puts "  profile:       #{report['profile'] || '-'}"
            if report["instructions"]
              puts "  instructions:  #{report['instructions']['source']} -> #{report['instructions']['path']}"
            end
            puts "  workspace:     #{report['workspace'] || '-'}"
            puts "  pane:          #{report['pane'] || '-'}"
            puts "  agent:         #{report['agent']}"
            puts "  replaced pane: #{report['replaced_pane'] || '-'}" if report["replaced_pane"]
            puts "  #{report['message']}" if report["message"]
          end
        end
      end
    end
  end
end
