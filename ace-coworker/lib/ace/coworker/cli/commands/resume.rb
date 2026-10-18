# frozen_string_literal: true

require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class Resume < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Assess interrupted work in this worktree and resume it"

          option :config, desc: "Path to coworker config (default: .ace-local/coworker/config.yml)"
          option :assignment, desc: "Assignment ID (default: config assignment)"
          option :"dry-run", type: :boolean, desc: "Derive the resume plan without redelivering reports"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(**options)
            orchestrator = Organisms::ResumeOrchestrator.new
            result = orchestrator.call(
              config_path: options[:config],
              assignment: options[:assignment],
              dry_run: options[:"dry-run"] == true
            )

            # Render the plan first: on a delegated report failure the
            # resume guidance still matters; then keep the non-zero exit.
            unless options[:quiet]
              if options[:format] == "json"
                puts JSON.pretty_generate(to_h(result))
              else
                puts Atoms::ResumeBriefFormatter.format_table(result.plan, result)
              end
            end

            if result.exit_code != 0
              raise Ace::Support::Cli::Error, result.message
            end
          rescue Ace::Coworker::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def to_h(result)
            payload = result.plan.to_h
            payload["message"] = result.message
            payload
          end
        end
      end
    end
  end
end
