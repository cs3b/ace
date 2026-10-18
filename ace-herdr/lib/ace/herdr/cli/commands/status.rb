# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Show the live herdr layout: workspaces, tabs, and panes in one view

            Composes workspace/tab/pane lists into a readable tree. A live but
            empty result is a valid state; an unreachable runtime is reported
            as an error, never as an empty layout.
          DESC

          example [
            "--workspace w1           # One workspace only",
            "--format json            # Composed tree as JSON"
          ]

          option :workspace, type: :string, desc: "Scope tabs and panes to a workspace id"
          option :format, type: :string, default: "table", desc: "Output format: table or json"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(executor: nil)
            @executor = executor
          end

          def call(**options)
            translate_errors do
              format = options[:format] || "table"
              cli_error("Invalid format: #{format} (use table or json)") unless %w[table json].include?(format)

              control = Organisms::ControlSurface.new(executor: executor)
              scope = options[:workspace]
              tree = Molecules::StatusComposer.call(
                workspaces: control.list_workspaces,
                tabs: control.list_tabs(workspace_id: scope),
                panes: control.list_panes(workspace_id: scope)
              )

              return if options[:quiet]

              if format == "json"
                puts JSON.generate(tree)
              else
                puts render_table(tree)
              end
            end
          end

          private

          def render_table(tree)
            workspaces = tree[:workspaces]
            return "No live herdr workspaces." if workspaces.empty?

            tab_total = workspaces.sum { |workspace| workspace[:tab_count] }
            pane_total = workspaces.sum { |workspace| workspace[:pane_count] }
            lines = ["Herdr: #{workspaces.length} workspace(s), #{tab_total} tab(s), #{pane_total} pane(s)"]
            workspaces.each do |workspace|
              lines << format(
                "%s %-14s %-16s %d tab(s), %d pane(s)",
                workspace[:focused] ? "*" : " ", workspace[:id], workspace[:title].to_s,
                workspace[:tab_count], workspace[:pane_count]
              )
              workspace[:tabs].each do |tab|
                lines << format(
                  "    %s %-18s %-14s %d pane(s)",
                  tab[:focused] ? "*" : " ", tab[:id], tab[:title].to_s, tab[:pane_count]
                )
                tab[:panes].each do |pane|
                  lines << pane_line(pane)
                end
              end
            end
            lines.join("\n")
          end

          def pane_line(pane)
            title = pane[:title].to_s.empty? ? "—" : pane[:title]
            line = format(
              "        %s %-8s %-14s %s",
              pane[:focused] ? "*" : " ", pane[:id], title, shorten_home(pane[:cwd].to_s)
            )
            line += "  agent: #{pane[:agent_status]}" if pane[:agent_status]
            line
          end

          def shorten_home(path)
            home = Dir.home
            path.start_with?(home) ? path.sub(home, "~") : path
          end
        end
      end
    end
  end
end
