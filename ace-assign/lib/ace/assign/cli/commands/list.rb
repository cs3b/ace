# frozen_string_literal: true

require "json"

module Ace
  module Assign
    module CLI
      module Commands
        # List all assignments with state information
        #
        # @example List active assignments
        #   ace-assign list
        #
        # @example Include completed assignments
        #   ace-assign list --all
        #
        # @example Filter by task
        #   ace-assign list --task my-task
        #
        # @example JSON output
        #   ace-assign list --format json
        class List < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          # Column widths for table display
          COL_ID = 10
          COL_NAME = 25
          COL_STATUS = 12
          COL_PROGRESS = 10
          COL_PHASE = 20
          COL_UPDATED = 15

          # Status display labels
          STATE_LABELS = {
            running: "running",
            paused: "paused",
            completed: "completed",
            failed: "failed",
            empty: "empty"
          }.freeze

          desc "List all assignments"

          option :all, aliases: ["-a"], type: :boolean, default: false, desc: "Include completed assignments"
          option :task, aliases: ["-t"], desc: "Filter by task reference"
          option :tree, type: :boolean, default: false, desc: "Show assignment hierarchy as tree"
          option :format, aliases: ["-f"], desc: "Output format (table, json)", default: "table"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(**options)
            discoverer = Molecules::AssignmentDiscoverer.new
            manager = Molecules::AssignmentManager.new
            current_id = manager.current_id

            all_assignments = discoverer.find_all(include_completed: true)
            assignments = if options[:task]
                            all_assignments.select { |ai| ai.assignment.name == options[:task] }
                              .then { |filtered| options[:all] ? filtered : filtered.reject(&:completed?) }
                          elsif options[:all]
                            all_assignments
                          else
                            all_assignments.reject(&:completed?)
                          end

            hidden_completed = options[:all] ? 0 : all_assignments.count(&:completed?)

            if options[:tree]
              print_tree(assignments)
            elsif options[:format] == "json"
              print_json(assignments, current_id: current_id)
            else
              print_table(assignments, current_id: current_id, hidden_completed: hidden_completed)
            end
          end

          private

          def print_tree(assignments)
            puts Atoms::TreeFormatter.format(assignments)
          end

          def print_table(assignments, current_id:, hidden_completed:)
            if assignments.empty?
              if hidden_completed > 0
                puts "No active assignments (#{hidden_completed} completed, use --all to show)"
              else
                puts "No assignments found."
              end
              return
            end

            # Header
            puts format(
              "%-#{COL_ID}s %-#{COL_NAME}s %-#{COL_STATUS}s %-#{COL_PROGRESS}s %-#{COL_PHASE}s %s",
              "ID", "NAME", "STATUS", "PROGRESS", "CURRENT PHASE", "UPDATED"
            )
            puts "-" * 95

            # Rows
            assignments.each do |info|
              marker = info.id == current_id ? "*" : " "
              id_display = "#{marker}#{info.id}"

              name_display = truncate(info.name.to_s, COL_NAME - 1)
              state_display = STATE_LABELS[info.state] || info.state.to_s
              phase_display = truncate(info.current_phase, COL_PHASE - 1)
              updated_display = format_relative_time(info.updated_at)

              puts format(
                "%-#{COL_ID}s %-#{COL_NAME}s %-#{COL_STATUS}s %-#{COL_PROGRESS}s %-#{COL_PHASE}s %s",
                id_display, name_display, state_display, info.progress, phase_display, updated_display
              )
            end

            puts
            total = assignments.size + hidden_completed
            if hidden_completed > 0
              puts "#{assignments.size}/#{total} assignment(s) shown (use --all to include completed)"
            else
              puts "#{assignments.size} assignment(s) found"
            end
            puts "* = current selection" if current_id
          end

          def print_json(assignments, current_id:)
            data = assignments.map do |info|
              {
                id: info.id,
                name: info.name,
                state: info.state.to_s,
                progress: info.progress,
                current_phase: info.current_phase,
                updated_at: info.updated_at.iso8601,
                is_current: info.id == current_id
              }
            end

            puts JSON.pretty_generate(data)
          end

          def truncate(str, max_length)
            return str if str.length <= max_length

            str[0..max_length - 4] + "..."
          end

          def format_relative_time(time)
            return "-" unless time

            diff = Time.now - time
            if diff < 60
              "#{diff.to_i}s ago"
            elsif diff < 3600
              "#{(diff / 60).to_i}m ago"
            elsif diff < 86_400
              "#{(diff / 3600).to_i}h ago"
            else
              "#{(diff / 86_400).to_i}d ago"
            end
          end
        end
      end
    end
  end
end
