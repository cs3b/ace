# frozen_string_literal: true

require "json"
require "shellwords"

module Ace
  module Overseer
    module CLI
      module Commands
        # `ace-overseer start [--dry-run] [--format table|json]`
        # (task 8xs.t.pu0.1): starts or reuses the project overseer
        # session from the directory's explicit start configuration.
        # Ready starts and dry runs exit 0; blocked or partial starts
        # are CLI errors. A dry run creates no session.
        class Start < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Start or reuse the project overseer session from .ace/overseer/config.yml"

          option :reconcile, type: :boolean, default: false, desc: "Explicitly reconcile configured project overseers without restarting the lab coordinator"
          option :scope, type: :string, desc: "Coordinator role (lab or project); omitted means lab bootstrap"
          option :dry_run, type: :boolean, default: false, desc: "Show the start plan without creating a session"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil, config: nil, launcher: nil)
            super()
            @orchestrator = orchestrator
            @config = config
            @launcher = launcher
          end

          def call(dry_run: false, format: "table", scope: nil, reconcile: false, **options)
            previous_toolchain = ENV["ACE_TOOLCHAIN"]
            configured = (@config || Ace::Overseer.config)["toolchain"]
            unless configured.nil? || %w[auto installed].include?(configured)
              raise Ace::Support::Cli::Error, "toolchain must be auto or installed"
            end
            ENV["ACE_TOOLCHAIN"] = configured if configured && previous_toolchain != "installed"
            unless scope.nil? || Atoms::StartContract::SCOPES.include?(scope)
              raise Ace::Support::Cli::Error, "scope must be lab or project"
            end
            if reconcile && scope == "project"
              raise Ace::Support::Cli::Error, "--reconcile requires lab scope"
            end
            operation = orchestrator(scope: scope)
            report = if reconcile
              operation.reconcile(dry_run: dry_run)
            elsif scope
              operation.call(dry_run: dry_run)
            else
              operation.bootstrap(dry_run: dry_run)
            end
            return launch_foreground(report) if report["status"] == "foreground"

            if options[:quiet]
              # quiet still fails loudly on a blocked start
            elsif format == "json"
              puts JSON.pretty_generate(report)
            else
              render_table(report)
            end

            if report["prompt_failed"] == true
              raise Ace::Support::Cli::Error, report["message"] || "first turn or readiness is unconfirmed"
            end
            case report["status"]
            when "started", "reused", "ready", "dry_run" then nil
            else
              raise Ace::Support::Cli::Error, report["message"] || "start blocked"
            end
          rescue Interrupt
            raise Ace::Support::Cli::Error.new("start interrupted; inspect existing sessions before retrying", exit_code: 130)
          rescue Ace::Support::Cli::Error
            raise
          rescue => e
            raise Ace::Support::Cli::Error.new(e.message)
          ensure
            ENV["ACE_TOOLCHAIN"] = previous_toolchain
          end

          private

          def launch_foreground(report)
            return @launcher.call(report.fetch("command")) if @launcher

            role = report["scope"] == "lab" ? "lab-overseer" : "project-overseer"
            directory = nil
            Molecules::SessionEnvironment.new.with_environment(root: report.fetch("root"), role: role, eyes_config: report["eyes_config"]) do |path, credentials, _args|
              directory = credentials
              environment = JSON.parse(File.read(path))
              # Foreground Pi occupies this terminal; delegated launches receive
              # their destination context from native Herdr instead.
              environment.merge!(ENV.to_h.slice("HERDR_ENV", "HERDR_PANE_ID", "HERDR_TAB_ID", "HERDR_WORKSPACE_ID"))
              environment["HERDR_PANE"] = environment["HERDR_PANE_ID"] if environment["HERDR_PANE_ID"]
              environment["HERDR_SESSION"] = environment["HERDR_WORKSPACE_ID"] if environment["HERDR_WORKSPACE_ID"]
              system(environment, *report.fetch("command"), unsetenv_others: true)
              status = $?
              unless status&.success?
                raise Ace::Support::Cli::Error.new("coordinator process exited unsuccessfully",
                  exit_code: status&.exitstatus || 1)
              end
            end
          ensure
            Molecules::SessionEnvironment.cleanup(directory) if directory
          end

          def orchestrator(scope: nil)
            @orchestrator || Organisms::StartOrchestrator.new(config: @config || Ace::Overseer.config, scope: scope)
          end

          def render_table(report)
            puts "ace-overseer start: #{report["status"]}"
            puts "  scope:         #{report["scope"] || "-"}"
            puts "  root:          #{report["root"] || "-"}"
            puts "  label:         #{report["label"] || "-"}"
            puts "  profile:       #{report["profile"] || "-"}"
            if report["instructions"]
              puts "  instructions:  #{report["instructions"]["source"]} -> #{report["instructions"]["path"]}"
            end
            puts "  workspace:     #{report["workspace"] || "-"}"
            puts "  pane:          #{report["pane"] || "-"}"
            puts "  agent:         #{report["agent"] || "-"}"
            puts "  command:       #{Shellwords.join(report["command"])}" if report["command"]
            puts "  replaced pane: #{report["replaced_pane"] || "-"}" if report["replaced_pane"]
            puts "  #{report["message"]}" if report["message"]
            Array(report["projects"]).each do |project|
              status = project["status"] || "unknown"
              status += " (first turn unconfirmed)" if project["prompt_failed"]
              puts "  project #{project["id"]}: #{status} (#{project["path"] || "-"}, pane: #{project["pane"] || "-"})"
              puts "    #{project["message"]}" if project["message"]
            end
          end
        end
      end
    end
  end
end
