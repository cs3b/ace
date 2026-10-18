# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        class Start < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Validate prepared run config and render the executor brief"

          option :config, desc: "Path to coworker config (default: .ace-local/coworker/config.yml)"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil)
            super()
            @orchestrator = orchestrator
          end

          def call(config: nil, format: "table", **options)
            orchestrator = @orchestrator || Organisms::StartOrchestrator.new
            brief = orchestrator.call(config_path: config)
            return if options[:quiet]

            if format == "json"
              puts Atoms::BriefFormatter.format_json(brief)
            else
              puts Atoms::BriefFormatter.format_table(brief)
            end
          rescue Ace::Coworker::Error, StandardError => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
