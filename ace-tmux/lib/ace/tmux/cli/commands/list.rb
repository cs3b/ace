# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        class List < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            List live tmux sessions, windows, or panes

            Default behavior lists panes in the resolved current window.

            Scope flags:
              --all-panes  List panes across the resolved session
              --windows    List windows in the resolved session
              --sessions   List all tmux sessions
          DESC

          example [
            "                              # List panes in the current window",
            "--all-panes                   # List panes across the current session",
            "--windows                     # List windows in the current session",
            "--sessions                    # List tmux sessions",
            "--session dev --window work   # List panes in an explicit window"
          ]

          option :session, type: :string, aliases: %w[-s], desc: "Target session name"
          option :window, type: :string, aliases: %w[-w], desc: "Target window name, index, or tmux window id (@2)"
          option :all_panes, type: :boolean, desc: "List panes across the resolved session"
          option :windows, type: :boolean, desc: "List windows in the resolved session"
          option :sessions, type: :boolean, desc: "List all tmux sessions"

          def call(**options)
            validate_scope!(options)

            control = Organisms::ControlSurface.new
            scope = selected_scope(options)

            case scope
            when :sessions
              print_sessions(control.list_sessions)
            when :windows
              print_windows(control.list_windows(session: options[:session]))
            when :all_panes
              print_panes(control.list_panes(session: options[:session], all_panes: true))
            else
              print_panes(control.list_panes(session: options[:session], window: options[:window]))
            end
          rescue Ace::Tmux::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def validate_scope!(options)
            scopes = %i[all_panes windows sessions].select { |key| options[key] }
            raise Ace::Support::Cli::Error, "Use only one of --all-panes, --windows, or --sessions" if scopes.length > 1

            if options[:sessions] && (options[:session] || options[:window])
              raise Ace::Support::Cli::Error, "--sessions does not accept --session or --window"
            end

            if options[:windows] && options[:window]
              raise Ace::Support::Cli::Error, "--windows does not accept --window"
            end

            if options[:all_panes] && options[:window]
              raise Ace::Support::Cli::Error, "--all-panes does not accept --window"
            end
          end

          def selected_scope(options)
            return :sessions if options[:sessions]
            return :windows if options[:windows]
            return :all_panes if options[:all_panes]

            :panes
          end

          def print_sessions(rows)
            return puts("No tmux sessions found.") if rows.empty?

            table = build_table(
              %w[SESSION ATTACHED WINDOWS],
              rows.map { |row| [row[:session], row[:attached_clients].to_s, row[:window_count].to_s] }
            )
            puts table
          end

          def print_windows(rows)
            return puts("No windows found.") if rows.empty?

            table = build_table(
              %w[A WINDOW SESSION:INDEX NAME PANES],
              rows.map do |row|
                [
                  row[:active] ? "*" : " ",
                  row[:id],
                  "#{row[:session]}:#{row[:index]}",
                  row[:name],
                  row[:pane_count].to_s
                ]
              end
            )
            puts table
          end

          def print_panes(rows)
            return puts("No panes found.") if rows.empty?

            table = build_table(
              %w[A PANE TARGET CMD CWD],
              rows.map do |row|
                [
                  row[:active] ? "*" : " ",
                  row[:pane_id],
                  row[:target],
                  row[:command],
                  row[:cwd]
                ]
              end
            )
            puts table
          end

          def build_table(headers, rows)
            widths = headers.each_index.map do |index|
              ([headers[index]] + rows.map { |row| row[index].to_s }).map(&:length).max
            end

            lines = []
            lines << render_row(headers, widths)
            lines << render_row(widths.map { |width| "-" * width }, widths)
            rows.each { |row| lines << render_row(row, widths) }
            lines.join("\n")
          end

          def render_row(values, widths)
            values.each_with_index.map { |value, index| value.to_s.ljust(widths[index]) }.join("  ").rstrip
          end
        end
      end
    end
  end
end
