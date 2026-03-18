# frozen_string_literal: true

require "json"

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
        #
        # @example Status for specific assignment
        #   ace-assign status --assignment abc123
        #
        # @example Show all assignments including completed
        #   ace-assign status --all
        class Status < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base
          include AssignmentTarget

          # Status icons for consistent display
          STATUS_ICONS = {
            done: "✓ Done",
            in_progress: "▶ Active",
            pending: "○ Pending",
            failed: "✗ Failed"
          }.freeze

          # State labels for other assignments section
          STATE_LABELS = {
            running: "running",
            paused: "paused",
            completed: "completed",
            failed: "failed",
            empty: "empty"
          }.freeze

          # Column widths for hierarchical display
          COL_NUMBER = 12
          COL_STATUS = 12
          COL_NAME = 30
          COL_FORK = 6

          desc "Display current workflow queue status"

          option :flat, aliases: ["-f"], type: :boolean, default: false, desc: "Show flat list (no hierarchy)"
          option :format, desc: "Output format (table, json)", default: "table"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"
          option :assignment, desc: "Show status for specific assignment ID"
          option :all, aliases: ["-a"], type: :boolean, default: false, desc: "Include completed assignments in other assignments section"

          def call(**options)
            target = resolve_assignment_target(options)

            executor = build_executor_for_target(target)
            result = executor.status
            state = result[:state]
            assignment = result[:assignment]
            scoped = scoped_status_view(state, target.scope)
            scoped_state = scoped[:state]
            current_for_display = scoped[:current]
            scope_root = scoped[:root]

            unless options[:quiet]
              if options[:format] == "json"
                puts JSON.pretty_generate(status_to_h(assignment, scoped_state, current_for_display))
                return
              end

              print_queue_status(assignment, scoped_state, flat: options[:flat], root_number: scope_root)

              if current_for_display
                fork_root = fork_scope_root(state, current_for_display)
                scoped_fork_phase = scoped_fork_metadata_phase(state, current_for_display, target.scope, scope_root)

                puts
                puts "Current Phase: #{current_for_display.number} - #{current_for_display.name}"
                puts "Current Status: #{current_for_display.status}"
                if current_for_display.stall_reason
                  lines = current_for_display.stall_reason.to_s.strip.lines
                  puts "Stall Reason: #{lines.first&.chomp}"
                  lines[1..].each { |l| puts "             #{l.chomp}" } if lines.length > 1
                end
                if current_for_display.workflow
                  puts "Workflow: #{current_for_display.workflow}"
                elsif current_for_display.skill
                  puts "Skill: #{current_for_display.skill}"
                end
                if current_for_display.context
                  puts "Context: #{current_for_display.context}"
                end
                puts
                print_scoped_fork_pid_info(scoped_fork_phase)

                if current_for_display.fork? && %i[pending in_progress].include?(current_for_display.status)
                  # Fork context: output Task tool instructions
                  print_fork_instructions(current_for_display, assignment)
                else
                  puts "Instructions:"
                  puts current_for_display.instructions

                  if fork_root && (target.scope.nil? || target.scope.strip.empty?)
                    puts
                    puts "Fork subtree detected (root: #{fork_root.number} - #{fork_root.name})."
                    puts "Run in forked process:"
                    puts "  ace-assign fork-run --root #{fork_root.number} --assignment #{assignment.id}"
                  end
                end
              elsif scoped_state.complete?
                puts
                puts "Assignment completed!"
              end

              # Show other assignments section (unless targeting a specific assignment)
              unless target.assignment_id
                print_other_assignments(result[:assignment].id, include_completed: options[:all])
              end
            end
          end

          private

          def status_to_h(assignment, state, current_phase)
            {
              assignment: {
                id: assignment.id,
                name: assignment.name,
                state: state.assignment_state.to_s
              },
              phases: state.phases.map { |phase| phase_to_h(phase) },
              current_phase: phase_to_h(current_phase),
              progress: "#{state.done.size}/#{state.size} done"
            }
          end

          def phase_to_h(phase)
            return nil unless phase

            {
              number: phase.number,
              name: phase.name,
              status: phase.status.to_s,
              skill: phase.skill,
              workflow: phase.workflow,
              context: phase.context,
              batch_parent: phase.batch_parent,
              parallel: phase.parallel,
              max_parallel: phase.max_parallel,
              fork_retry_limit: phase.fork_retry_limit,
              parent: phase.parent
            }.compact
          end

          def scoped_status_view(state, scope)
            return { state: state, current: state.current, root: nil } if scope.nil? || scope.strip.empty?

            root = state.find_by_number(scope.strip)
            raise PhaseErrors::NotFound, "Phase #{scope} not found in queue" unless root

            scoped_phases = state.subtree_phases(root.number)
            scoped_state = Models::QueueState.new(phases: scoped_phases, assignment: state.assignment)
            current = scoped_state.current || scoped_state.next_workable

            { state: scoped_state, current: current, root: root.number }
          end

          def print_queue_status(assignment, state, flat: false, root_number: nil)
            puts "QUEUE - Assignment: #{assignment.name} (#{assignment.id})"
            puts

            if flat || !has_nested_phases?(state)
              print_flat_status(state)
            else
              print_hierarchical_status(state, root_number: root_number)
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

          def print_hierarchical_status(state, root_number: nil)
            # Header
            puts format("%-#{COL_NUMBER}s %-#{COL_STATUS}s %-#{COL_NAME}s %-#{COL_FORK}s %s", "NUMBER", "STATUS", "NAME", "FORK", "CHILDREN")
            puts "-" * 78

            # Print hierarchy with tree structure
            nodes = root_hierarchy_nodes(state, root_number)
            print_hierarchy_level(nodes, state, depth: 0)
          end

          def root_hierarchy_nodes(state, root_number)
            return state.hierarchical if root_number.nil? || root_number.strip.empty?

            root = state.find_by_number(root_number)
            return [] unless root

            [build_hierarchy_node(state, root)]
          end

          def build_hierarchy_node(state, phase)
            children = state.children_of(phase.number).map do |child|
              build_hierarchy_node(state, child)
            end

            { step: phase, children: children }
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

              # Fork indicator reflects execution context, not child presence.
              fork_info = phase.fork? ? "yes" : ""

              # Children count (progress visibility)
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
              puts format("%-#{COL_NUMBER}s %-#{COL_STATUS}s %-#{COL_NAME}s %-#{COL_FORK}s %s%s",
                          number_display, status_icon, display_name, fork_info, child_info, error_suffix)

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
            # Derive project root from cache_dir: /project/.ace-local/assign/assignment-id -> /project
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
            puts "After completing, run:"
            puts "  ace-assign finish --message <report-file.md>"
            puts
            puts "To execute entire subtree in one forked process:"
            puts "  ace-assign fork-run --root #{phase.number} --assignment #{assignment.id}"
          end

          def fork_scope_root(state, current_phase)
            return nil unless current_phase
            return current_phase if current_phase.fork?

            state.nearest_fork_ancestor(current_phase.number)
          end

          def scoped_fork_metadata_phase(state, current_phase, scope, scope_root)
            return nil unless current_phase

            if scope && !scope.strip.empty?
              return state.find_by_number(scope_root || scope.strip)
            end

            fork_scope_root(state, current_phase)
          end

          def print_scoped_fork_pid_info(phase)
            return unless phase

            has_pid = phase.fork_launch_pid
            has_tree = phase.fork_tracked_pids && !phase.fork_tracked_pids.empty?
            has_file = phase.fork_pid_file && !phase.fork_pid_file.empty?
            return unless has_pid || has_tree || has_file

            puts "Scoped Fork PID: #{phase.fork_launch_pid}" if has_pid
            puts "Scoped Fork PID Tree: #{phase.fork_tracked_pids.join(', ')}" if has_tree
            puts "Scoped Fork PID File: #{phase.fork_pid_file}" if has_file
            puts
          end

          # Print other assignments section
          def print_other_assignments(current_assignment_id, include_completed:)
            discoverer = Molecules::AssignmentDiscoverer.new
            all_assignments = discoverer.find_all(include_completed: include_completed)

            # Exclude the current assignment
            others = all_assignments.reject { |ai| ai.id == current_assignment_id }
            return if others.empty?

            puts
            suffix = include_completed ? "" : " (use --all to show completed)"
            puts "OTHER ASSIGNMENTS:#{suffix}"

            col_id = 10
            col_status = 12
            col_progress = 10
            col_phase = 20
            puts format("%-#{col_id}s %-#{col_status}s %-#{col_progress}s %-#{col_phase}s %s",
                        "ASSIGNMENT", "STATUS", "PROGRESS", "CURRENT PHASE", "UPDATED")

            others.each do |info|
              state_label = STATE_LABELS[info.state] || info.state.to_s
              updated = format_relative_time(info.updated_at)
              phase = info.current_phase.length > col_phase ? info.current_phase[0..col_phase - 4] + "..." : info.current_phase

              puts format("%-#{col_id}s %-#{col_status}s %-#{col_progress}s %-#{col_phase}s %s",
                          info.id, state_label, info.progress, phase, updated)
            end
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
