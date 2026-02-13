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
        class List < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

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
          option :format, aliases: ["-f"], desc: "Output format (table, json)", default: "table"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(**options)
            discoverer = Molecules::AssignmentDiscoverer.new
            manager = Molecules::AssignmentManager.new
            current_id = manager.current_id

            assignments = if options[:task]
                            discoverer.find_by_task(task_ref: options[:task], active_only: !options[:all])
                          else
                            discoverer.find_all(include_completed: options[:all])
                          end

            if options[:format] == "json"
              print_json(assignments, current_id: current_id)
            else
              print_table(assignments, current_id: current_id)
            end
          end

          private

          def print_table(assignments, current_id:)
            if assignments.empty?
              puts "No assignments found."
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
            puts "#{assignments.size} assignment(s) found"
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
