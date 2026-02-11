# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Display current queue status
        #
        # Shows the work queue with hierarchical phase structure.
        # Nested phases are indented to show parent-child relationships.
        #
        # @example Basic usage
        #   ace-assign status
        #
        # @example Flat output (no hierarchy)
        #   ace-assign status --flat
        class Status < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          # Status icons for consistent display
          STATUS_ICONS = {
            done: "✓ Done",
            in_progress: "▶ Active",
            pending: "○ Pending",
            failed: "✗ Failed"
          }.freeze

          # Column widths for hierarchical display
          COL_NUMBER = 12
          COL_STATUS = 12
          COL_NAME = 30

          desc "Display current workflow queue status"

          option :flat, aliases: ["-f"], type: :boolean, default: false, desc: "Show flat list (no hierarchy)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress detailed output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(**options)
            executor = Organisms::AssignmentExecutor.new
            result = executor.status

            unless options[:quiet]
              print_queue_status(result[:assignment], result[:state], flat: options[:flat])

              if result[:current]
                puts
                puts "Current Phase: #{result[:current].number} - #{result[:current].name}"
                if result[:current].skill
                  puts "Skill: #{result[:current].skill}"
                end
                if result[:current].context
                  puts "Context: #{result[:current].context}"
                end
                puts

                if result[:current].fork?
                  # Fork context: output Task tool instructions
                  print_fork_instructions(result[:current], result[:assignment])
                else
                  puts "Instructions:"
                  puts result[:current].instructions
                end
              elsif result[:state].complete?
                puts
                puts "Assignment completed!"
              end
            end
          end

          private

          def print_queue_status(assignment, state, flat: false)
            puts "QUEUE - Assignment: #{assignment.name} (#{assignment.id})"
            puts

            if flat || !has_nested_phases?(state)
              print_flat_status(state)
            else
              print_hierarchical_status(state)
            end
          end

          def has_nested_phases?(state)
            state.phases.any? { |s| !Atoms::PhaseNumbering.top_level?(s.number) }
          end

          def print_flat_status(state)
            # Calculate column widths
            file_width = [30, state.phases.map { |s| File.basename(s.file_path || "").length }.max || 20].max
            status_width = 12
            name_width = 20

            # Header
            puts format("%-#{file_width}s %-#{status_width}s %-#{name_width}s", "FILE", "STATUS", "NAME")

            # Rows
            state.phases.each do |phase|
              file = File.basename(phase.file_path || "#{phase.number}-#{phase.name}.ph.md")
              status = format_status(phase.status)
              name = phase.name

              row = format("%-#{file_width}s %-#{status_width}s %-#{name_width}s", file, status, name)

              # Add error message for failed phases
              if phase.status == :failed && phase.error
                row += "  (#{phase.error})"
              end

              puts row
            end
          end

          def print_hierarchical_status(state)
            # Header
            puts format("%-#{COL_NUMBER}s %-#{COL_STATUS}s %-#{COL_NAME}s %s", "NUMBER", "STATUS", "NAME", "CHILDREN")
            puts "-" * 70

            # Print hierarchy with tree structure
            print_hierarchy_level(state.hierarchical, state, depth: 0)
          end

          def print_hierarchy_level(nodes, state, depth:)
            nodes.each_with_index do |node, index|
              phase = node[:step]
              children = node[:children]
              is_last = index == nodes.size - 1

              # Build tree prefix
              prefix = if depth == 0
                         ""
                       else
                         indent = "  " * (depth - 1)
                         connector = is_last ? "\\-- " : "|-- "
                         indent + connector
                       end

              # Format number with hierarchy indicator
              number_display = prefix + phase.number

              # Status with icon
              status_icon = STATUS_ICONS[phase.status] || phase.status.to_s.capitalize

              # Children count
              child_info = if children.any?
                             incomplete = children.count { |c| c[:step].status != :done }
                             if incomplete > 0
                               "(#{children.size - incomplete}/#{children.size} done)"
                             else
                               "(#{children.size}/#{children.size} done)"
                             end
                           else
                             ""
                           end

              # Error info for failed phases
              error_suffix = phase.status == :failed && phase.error ? " - #{phase.error}" : ""

              # Truncate name with ellipsis if too long
              display_name = if phase.name.length > COL_NAME
                               phase.name[0..COL_NAME - 4] + "..."
                             else
                               phase.name
                             end
              puts format("%-#{COL_NUMBER}s %-#{COL_STATUS}s %-#{COL_NAME}s %s%s",
                          number_display, status_icon, display_name, child_info, error_suffix)

              # Recurse for children
              print_hierarchy_level(children, state, depth: depth + 1) if children.any?
            end
          end

          def format_status(status)
            STATUS_ICONS[status]&.split(" ")&.last || status.to_s.capitalize
          end

          # Print Task tool instructions for a fork context phase
          def print_fork_instructions(phase, assignment)
            escaped_name = phase.name.gsub('"', '\\"')
            # Derive project root from cache_dir: /project/.cache/ace-assign/assignment-id -> /project
            project_root = assignment.cache_dir ? File.expand_path("../../..", assignment.cache_dir) : Dir.pwd

            puts "Execute this phase in a forked context:"
            puts
            puts "  Task tool parameters:"
            puts "    description: \"#{escaped_name}\""
            puts "    prompt: (see below)"
            puts
            puts "  Prompt for forked agent:"
            puts "  ========================"
            puts phase.instructions
            puts "  ========================"
            puts
            puts "  Working directory: #{project_root}"
            puts "  Assignment: #{assignment.id}"
            puts
            puts "After completing, create a report file and run:"
            puts "  ace-assign report <report-file.md>"
          end
        end
      end
    end
  end
end
