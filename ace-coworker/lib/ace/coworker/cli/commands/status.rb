# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Display current queue status
        #
        # Shows the work queue with hierarchical job structure.
        # Nested jobs are indented to show parent-child relationships.
        #
        # @example Basic usage
        #   ace-coworker status
        #
        # @example Flat output (no hierarchy)
        #   ace-coworker status --flat
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
            executor = Organisms::WorkflowExecutor.new
            result = executor.status

            unless options[:quiet]
              print_queue_status(result[:session], result[:state], flat: options[:flat])

              if result[:current]
                puts
                puts "Current Step: #{result[:current].number} - #{result[:current].name}"
                if result[:current].skill
                  puts "Skill: #{result[:current].skill}"
                end
                if result[:current].context
                  puts "Context: #{result[:current].context}"
                end
                puts

                if result[:current].fork?
                  # Fork context: output Task tool instructions
                  print_fork_instructions(result[:current], result[:session])
                else
                  puts "Instructions:"
                  puts result[:current].instructions
                end
              elsif result[:state].complete?
                puts
                puts "Session completed!"
              end
            end
          end

          private

          def print_queue_status(session, state, flat: false)
            puts "QUEUE - Session: #{session.name} (#{session.id})"
            puts

            if flat || !has_nested_jobs?(state)
              print_flat_status(state)
            else
              print_hierarchical_status(state)
            end
          end

          def has_nested_jobs?(state)
            state.steps.any? { |s| !Atoms::JobNumbering.top_level?(s.number) }
          end

          def print_flat_status(state)
            # Calculate column widths
            file_width = [30, state.steps.map { |s| File.basename(s.file_path || "").length }.max || 20].max
            status_width = 12
            name_width = 20

            # Header
            puts format("%-#{file_width}s %-#{status_width}s %-#{name_width}s", "FILE", "STATUS", "NAME")

            # Rows
            state.steps.each do |step|
              file = File.basename(step.file_path || "#{step.number}-#{step.name}.j.md")
              status = format_status(step.status)
              name = step.name

              row = format("%-#{file_width}s %-#{status_width}s %-#{name_width}s", file, status, name)

              # Add error message for failed steps
              if step.status == :failed && step.error
                row += "  (#{step.error})"
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
              step = node[:step]
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
              number_display = prefix + step.number

              # Status with icon
              status_icon = STATUS_ICONS[step.status] || step.status.to_s.capitalize

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

              # Error info for failed steps
              error_suffix = step.status == :failed && step.error ? " - #{step.error}" : ""

              # Truncate name with ellipsis if too long
              display_name = if step.name.length > COL_NAME
                               step.name[0..COL_NAME - 4] + "..."
                             else
                               step.name
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

          # Print Task tool instructions for a fork context job
          def print_fork_instructions(step, session)
            escaped_name = step.name.gsub('"', '\\"')
            # Derive project root from cache_dir: /project/.cache/ace-coworker/session-id -> /project
            project_root = session.cache_dir ? File.expand_path("../../..", session.cache_dir) : Dir.pwd

            puts "Execute this job in a forked context:"
            puts
            puts "  Task tool parameters:"
            puts "    description: \"#{escaped_name}\""
            puts "    prompt: (see below)"
            puts
            puts "  Prompt for forked agent:"
            puts "  ========================"
            puts step.instructions
            puts "  ========================"
            puts
            puts "  Working directory: #{project_root}"
            puts "  Session: #{session.id}"
            puts
            puts "After completing, create a report file and run:"
            puts "  ace-coworker report <report-file.md>"
          end
        end
      end
    end
  end
end
