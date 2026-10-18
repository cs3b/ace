# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"
require_relative "../../organisms/status"

module Ace
  module Lab
    module CLI
      module Commands
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Show lab configuration and file-based state (read-only)"

          example [
            "                  # Table layout",
            "--format json     # Machine-readable snapshot"
          ]

          option :format, type: :string, desc: "Output format (table, json; default: table)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(status: nil)
            super()
            @status = status
          end

          def call(**options)
            format = options[:format] || "table"
            unless %w[table json].include?(format)
              raise Ace::Support::Cli::Error,
                "--format \"#{format}\" is not supported; table or json"
            end

            snapshot = (@status || Organisms::Status.new).snapshot
            return if options[:quiet]

            puts format == "json" ? JSON.generate(snapshot) : render(snapshot)
          end

          private

          def render(snapshot)
            lines = ["Lab configuration: #{render_configuration(snapshot["configuration"])}"]
            lines << "Local state:"
            snapshot["state_files"].each do |entry|
              lines << "  #{entry["path"].ljust(22)} #{render_state_file(entry)}"
            end
            lines << "Worktree view: run `ace-git-worktree list` (task associations, activity, PR state)"
            lines.join("\n")
          end

          def render_configuration(config)
            case config["state"]
            when "configured"
              sources = config["sources"].join(", ")
              topology = config["topology"]
              "configured (#{sources})  projects: #{topology["projects"]}  " \
                "agents: #{topology["agents"]}  services: #{topology["services"]}"
            when "not_configured"
              "not configured (no .ace/lab/config.yml or ~/.ace/lab/config.yml)"
            else
              "error - #{config["error"]}"
            end
          end

          def render_state_file(entry)
            if entry["present"]
              "present (#{entry["entries"]} entries)"
            elsif entry["note"]
              "not present (#{entry["note"]})"
            else
              "not present"
            end
          end
        end
      end
    end
  end
end
