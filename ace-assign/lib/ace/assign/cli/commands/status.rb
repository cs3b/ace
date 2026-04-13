# frozen_string_literal: true

require "json"

module Ace
  module Assign
    module CLI
      module Commands
        # Display current queue status.
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          STATUS_ICONS = {
            done: "✓ Done",
            in_progress: "▶ Active",
            pending: "○ Pending",
            failed: "✗ Failed"
          }.freeze

          STATE_LABELS = {
            running: "running",
            paused: "paused",
            completed: "completed",
            failed: "failed",
            empty: "empty",
            stalled: "stalled"
          }.freeze
          PROGRESS_BAR_WIDTH = 10

          COL_NUMBER = 12
          COL_STATUS = 12
          COL_NAME = 30
          COL_FORK = 6
          PREVIEW_LIMIT = 5

          desc "Display current workflow queue status"

          option :flat, aliases: ["-f"], type: :boolean, default: false, desc: "Show flat list (full mode only)"
          option :mode, desc: "Text output mode (compact, progress, full)", default: "compact"
          option :format, desc: "Output format (table, json)", default: "table"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"
          option :assignment, desc: "Show status for specific assignment ID"
          option :all, aliases: ["-a"], type: :boolean, default: false, desc: "Include completed assignments in other assignments section"

          def call(**options)
            target = resolve_assignment_target(options)
            view = resolve_assignment_view(target)

            return if options[:quiet]

            if options[:format] == "json"
              scoped_fork_step = scoped_fork_metadata_step(view.state, view.current_step, target.scope, view.scope_root)
              puts JSON.pretty_generate(
                status_to_h(view.assignment, view.scoped_state, view.current_step, scoped_fork_step: scoped_fork_step)
              )
              return
            end

            mode = normalize_mode(options[:mode])
            raise Ace::Support::Cli::Error, "--flat is supported only with --mode full" if options[:flat] && mode != "full"
            raise Ace::Support::Cli::Error, "--all is supported only with --mode full or compact" if options[:all] && mode == "progress"

            case mode
            when "progress"
              puts progress_summary_line(view.assignment, view.scoped_state, view.current_step)
            when "full"
              print_full_status(view, target, flat: options[:flat], include_completed: options[:all])
            else
              print_compact_status(view, target, include_completed: options[:all])
            end
          end

          private

          def normalize_mode(value)
            mode = value.to_s.strip
            mode = "compact" if mode.empty?
            allowed = %w[compact progress full]
            raise Ace::Support::Cli::Error, "Unsupported status mode '#{mode}'. Use one of: #{allowed.join(', ')}." unless allowed.include?(mode)

            mode
          end

          def status_to_h(assignment, state, current_step, scoped_fork_step: nil)
            {
              assignment: {
                id: assignment.id,
                name: assignment.name,
                state: state.assignment_state.to_s
              },
              steps: state.steps.map { |step| step_to_h(step) },
              current_step: step_to_h(
                current_step,
                effective_fork_provider: effective_fork_provider_for(current_step, scoped_fork_step)
              ),
              progress: "#{state.done.size}/#{state.size} done"
            }
          end

          def step_to_h(step, effective_fork_provider: nil)
            return nil unless step

            {
              number: step.number,
              name: step.name,
              status: step.status.to_s,
              skill: step.skill,
              workflow: step.workflow,
              context: step.context,
              fork_provider: effective_fork_provider || step.fork_provider,
              batch_parent: step.batch_parent,
              parallel: step.parallel,
              max_parallel: step.max_parallel,
              fork_retry_limit: step.fork_retry_limit,
              parent: step.parent
            }.compact
          end

          def print_compact_status(view, target, include_completed:)
            lines = []
            lines.concat(compact_summary_lines(view.assignment, view.scoped_state, view.current_step))

            unless target.assignment_id
              other_line = compact_other_assignments_line(view.assignment.id, include_completed: include_completed)
              lines << other_line if other_line
            end

            puts lines.take(10).join("\n")
          end

          def compact_summary_lines(assignment, state, current_step)
            lines = [
              compact_assignment_line(assignment, state, current_step),
              compact_last_done_line(state)
            ]

            pending = pending_preview_steps(state)
            unless pending.empty?
              lines << "Pending steps:"
              pending.each do |step|
                lines << preview_step_line(step)
              end
            end

            lines << compact_steps_summary_line(state)
            lines
          end

          def progress_summary_line(assignment, state, current_step)
            state_label = STATE_LABELS[state.assignment_state] || state.assignment_state.to_s
            details = ["State: #{state_label}", "Progress: #{state.done.size}/#{state.size} done"]

            if current_step
              details << "Current: #{current_step.number} #{current_step.name}"
            elsif state.complete?
              details << "Current: complete"
            end

            if state.last_done
              details << "Last: #{state.last_done.number} #{state.last_done.name}"
            end

            details.join(" | ")
          end

          def compact_assignment_line(assignment, state, current_step)
            state_label = STATE_LABELS[state.assignment_state] || state.assignment_state.to_s
            details = ["Assignment: #{assignment.id}  #{compact_assignment_name(assignment.name)}", "Status: #{state_label}"]

            if current_step
              details << "Current: #{current_step.number} #{current_step.name}"
            end
            details.join(" | ")
          end

          def compact_last_done_line(state)
            return "Last done: none" unless state.last_done

            "Last done: #{state.last_done.number} #{state.last_done.name}"
          end

          def compact_steps_summary_line(state)
            summary = state.summary
            "Steps: #{progress_bar(state.done.size, state.size)} #{state.done.size}/#{state.size} done | Pending: #{summary[:pending]} | Failed: #{summary[:failed]}"
          end

          def compact_assignment_name(name)
            File.basename(name.to_s, File.extname(name.to_s))
          end

          def pending_preview_steps(state)
            state.steps.select { |step| %i[in_progress pending failed].include?(step.status) }.first(PREVIEW_LIMIT)
          end

          def preview_step_line(step)
            status = case step.status
            when :in_progress then "active"
            when :pending then "next"
            when :failed then "failed"
            else step.status.to_s
            end
            "#{step.number} #{status} #{step.name}"
          end

          def progress_bar(done, total)
            return "░" * PROGRESS_BAR_WIDTH if total <= 0

            filled = ((done.to_f / total) * PROGRESS_BAR_WIDTH).round
            filled = [[filled, 0].max, PROGRESS_BAR_WIDTH].min
            ("█" * filled) + ("░" * (PROGRESS_BAR_WIDTH - filled))
          end

          def compact_other_assignments_line(current_assignment_id, include_completed:)
            discoverer = Molecules::AssignmentDiscoverer.new
            others = discoverer.find_all(include_completed: include_completed).reject { |info| info.id == current_assignment_id }
            return nil if others.empty?

            active = others.count { |info| %i[running stalled].include?(info.state) }
            pending = others.count { |info| info.state == :paused }
            failed = others.count { |info| info.state == :failed }
            "other assignments: #{others.size} total | active: #{active} paused: #{pending} failed: #{failed}"
          end

          def print_full_status(view, target, flat:, include_completed:)
            print_queue_status(view.assignment, view.scoped_state, flat: flat, root_number: view.scope_root)

            if view.current_step
              scoped_fork_step = scoped_fork_metadata_step(view.state, view.current_step, target.scope, view.scope_root)

              puts
              puts "Current Step: #{view.current_step.number} - #{view.current_step.name}"
              puts "Current Status: #{view.current_step.status}"
              print_stall_details(view.current_step)
              puts "Workflow: #{view.current_step.workflow}" if view.current_step.workflow
              puts "Skill: #{view.current_step.skill}" if !view.current_step.workflow && view.current_step.skill
              puts "Context: #{view.current_step.context}" if view.current_step.context

              effective_fork_provider = effective_fork_provider_for(view.current_step, scoped_fork_step)
              puts "Fork Provider: #{effective_fork_provider}" if effective_fork_provider
              print_scoped_fork_pid_info(scoped_fork_step)
            elsif view.scoped_state.complete?
              puts
              puts "Assignment completed!"
            end

            print_other_assignments_table(view.assignment.id, include_completed: include_completed) unless target.assignment_id
          end

          def print_stall_details(step)
            return unless step.stall_reason

            lines = step.stall_reason.to_s.strip.lines
            puts "Stall Reason: #{lines.first&.chomp}"
            lines[1..].each { |line| puts "             #{line.chomp}" } if lines.length > 1
            print_hitl_stall_guidance(lines.first.to_s)
          end

          def print_queue_status(assignment, state, flat: false, root_number: nil)
            puts "QUEUE - Assignment: #{assignment.name} (#{assignment.id})"
            puts

            if flat || !has_nested_steps?(state)
              print_flat_status(state)
            else
              print_hierarchical_status(state, root_number: root_number)
            end
          end

          def has_nested_steps?(state)
            state.steps.any? { |step| !Atoms::StepNumbering.top_level?(step.number) }
          end

          def print_flat_status(state)
            file_width = [30, state.steps.map { |step| File.basename(step.file_path || "").length }.max || 20].max
            status_width = 12
            name_width = 20

            puts format("%-#{file_width}s %-#{status_width}s %-#{name_width}s", "FILE", "STATUS", "NAME")

            state.steps.each do |step|
              file = File.basename(step.file_path || "#{step.number}-#{step.name}.st.md")
              status = format_status(step.status)
              row = format("%-#{file_width}s %-#{status_width}s %-#{name_width}s", file, status, step.name)
              row += "  (#{step.error})" if step.status == :failed && step.error
              puts row
            end
          end

          def print_hierarchical_status(state, root_number: nil)
            puts format("%-#{COL_NUMBER}s %-#{COL_STATUS}s %-#{COL_NAME}s %-#{COL_FORK}s %s", "NUMBER", "STATUS", "NAME", "FORK", "CHILDREN")
            puts "-" * 78

            nodes = root_hierarchy_nodes(state, root_number)
            print_hierarchy_level(nodes, depth: 0)
          end

          def root_hierarchy_nodes(state, root_number)
            return state.hierarchical if root_number.nil? || root_number.strip.empty?

            root = state.find_by_number(root_number)
            return [] unless root

            [build_hierarchy_node(state, root)]
          end

          def build_hierarchy_node(state, step)
            {
              step: step,
              children: state.children_of(step.number).map { |child| build_hierarchy_node(state, child) }
            }
          end

          def print_hierarchy_level(nodes, depth:)
            nodes.each_with_index do |node, index|
              step = node[:step]
              children = node[:children]
              prefix = if depth.zero?
                ""
              else
                ("  " * (depth - 1)) + (index == nodes.size - 1 ? "\\-- " : "|-- ")
              end

              status_icon = STATUS_ICONS[step.status] || step.status.to_s.capitalize
              fork_info = step.fork? ? "yes" : ""
              child_info = children.any? ? "(#{children.count { |c| c[:step].status == :done }}/#{children.size} done)" : ""
              error_suffix = (step.status == :failed && step.error) ? " - #{step.error}" : ""
              display_name = step.name.length > COL_NAME ? "#{step.name[0..COL_NAME - 4]}..." : step.name

              puts format(
                "%-#{COL_NUMBER}s %-#{COL_STATUS}s %-#{COL_NAME}s %-#{COL_FORK}s %s%s",
                prefix + step.number, status_icon, display_name, fork_info, child_info, error_suffix
              )

              print_hierarchy_level(children, depth: depth + 1) if children.any?
            end
          end

          def format_status(status)
            STATUS_ICONS[status]&.split(" ")&.last || status.to_s.capitalize
          end

          def print_scoped_fork_pid_info(step)
            return unless step

            has_pid = step.fork_launch_pid
            has_tree = step.fork_tracked_pids && !step.fork_tracked_pids.empty?
            has_file = step.fork_pid_file && !step.fork_pid_file.empty?
            return unless has_pid || has_tree || has_file

            puts "Scoped Fork PID: #{step.fork_launch_pid}" if has_pid
            puts "Scoped Fork PID Tree: #{step.fork_tracked_pids.join(', ')}" if has_tree
            puts "Scoped Fork PID File: #{step.fork_pid_file}" if has_file
          end

          def print_hitl_stall_guidance(first_line)
            hitl = parse_hitl_stall_reason(first_line)
            return unless hitl

            puts "HITL Guidance:"
            puts "  Review event: ace-hitl show #{hitl[:id]}"
            puts "  Stored path: #{hitl[:path]}" if hitl[:path]
            puts "  Requester default: ace-hitl wait #{hitl[:id]}"
            puts "  Fallback dispatch: ace-hitl update #{hitl[:id]} --answer \"<decision>\" --resume"
          end

          def parse_hitl_stall_reason(line)
            stripped = line.to_s.strip
            return nil unless stripped.start_with?("HITL:")

            payload = stripped.sub(/^HITL:\s*/, "")
            id, path = payload.split(/\s+/, 2)
            return nil if id.to_s.strip.empty?

            path = path.to_s.strip
            {id: id, path: path.empty? ? nil : path}
          end

          def print_other_assignments_table(current_assignment_id, include_completed:)
            discoverer = Molecules::AssignmentDiscoverer.new
            others = discoverer.find_all(include_completed: include_completed).reject { |info| info.id == current_assignment_id }
            return if others.empty?

            puts
            suffix = include_completed ? "" : " (use --all to show completed)"
            puts "OTHER ASSIGNMENTS:#{suffix}"

            col_id = 10
            col_status = 12
            col_progress = 10
            col_step = 20
            puts format("%-#{col_id}s %-#{col_status}s %-#{col_progress}s %-#{col_step}s %s",
              "ASSIGNMENT", "STATUS", "PROGRESS", "CURRENT STEP", "UPDATED")

            others.each do |info|
              state_label = STATE_LABELS[info.state] || info.state.to_s
              updated = format_relative_time(info.updated_at)
              step = info.current_step.length > col_step ? "#{info.current_step[0..col_step - 4]}..." : info.current_step
              puts format("%-#{col_id}s %-#{col_status}s %-#{col_progress}s %-#{col_step}s %s",
                info.id, state_label, info.progress, step, updated)
            end
          end

          def format_relative_time(time)
            return "-" unless time

            diff = Time.now - time
            return "#{diff.to_i}s ago" if diff < 60
            return "#{(diff / 60).to_i}m ago" if diff < 3600
            return "#{(diff / 3600).to_i}h ago" if diff < 86_400

            "#{(diff / 86_400).to_i}d ago"
          end
        end
      end
    end
  end
end
