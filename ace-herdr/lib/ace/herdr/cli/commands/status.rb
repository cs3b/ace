# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"
require_relative "../../organisms/status"

module Ace
  module Herdr
    module CLI
      module Commands
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc "Show the live herdr layout (workspaces > tabs > panes) as a readable tree"

          example [
            "                        # Table layout",
            "--format json           # Machine-readable snapshot"
          ]

          option :format, type: :string, desc: "Output format (table, json; default: table)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(executor: nil)
            super()
            @executor = executor
          end

          def call(**options)
            translate_errors do
              format = options[:format] || "table"
              unless %w[table json].include?(format)
                cli_error("--format \"#{format}\" is not supported; table or json")
              end

              snapshot = Organisms::Status.new(executor: executor).snapshot
              return if options[:quiet]

              puts format == "json" ? JSON.generate(snapshot) : render(snapshot)
            end
          end

          private

          def render(snapshot)
            runtime = snapshot["runtime"]
            lines = ["Herdr runtime: #{runtime["state"]}#{runtime["error"] ? " - #{runtime["error"]}" : ""}"]
            if runtime["state"] == "unavailable"
              lines << "Start or install herdr (#{runtime["binary"]}) to see the live layout."
              return lines.join("\n")
            end
            if runtime["state"] == "error"
              return lines.join("\n")
            end

            counts = snapshot["counts"]
            lines << "Workspaces: #{counts["workspaces"]}  Tabs: #{counts["tabs"]}  Panes: #{counts["panes"]}"
            lines << ""

            if snapshot["workspaces"].empty?
              lines << "No herdr workspaces, tabs, or panes."
            else
              snapshot["workspaces"].each do |entry|
                workspace = entry["workspace"]
                focus = workspace[:focused] ? " *" : ""
                lines << "#{workspace[:id]} #{workspace[:title]}#{focus}  (tabs: #{workspace[:tab_count]}, panes: #{workspace[:pane_count]})"
                entry["tabs"].each do |tab_entry|
                  tab = tab_entry["tab"]
                  tab_focus = tab[:focused] ? " *" : ""
                  lines << "  #{tab[:id]} #{tab[:title]}#{tab_focus}  (panes: #{tab_entry["panes"].size})"
                  tab_entry["panes"].each do |pane|
                    lines << "    #{render_pane(pane)}"
                  end
                end
              end
            end

            unattached = snapshot["unattached"]
            if unattached && (unattached["tabs"].any? || unattached["panes"].any?)
              lines << ""
              lines << "(unattached)"
              unattached["tabs"].each { |tab| lines << "  #{tab[:id]} #{tab[:title]}" }
              unattached["panes"].each { |pane| lines << "  #{render_pane(pane)}" }
            end

            lines.join("\n")
          end

          def render_pane(pane)
            focus = pane[:focused] ? "*" : " "
            agent = pane[:agent_status] ? "agent:#{pane[:agent_status]}" : "plain"
            cwd = pane[:cwd].to_s.sub(/\A#{Regexp.escape(Dir.home)}/, "~")
            title = pane[:title].to_s.empty? ? "-" : pane[:title]
            "#{focus} #{agent}  #{title}  #{cwd}"
          end
        end
      end
    end
  end
end
