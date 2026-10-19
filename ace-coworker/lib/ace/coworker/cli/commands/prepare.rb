# frozen_string_literal: true

require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class Prepare < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Accept a preparation commission and ensure the task worktree"

          option :task, desc: "Task reference (required)"
          option :roles, type: :array,
            desc: "Expected role sequence, repeatable and comma-separated (e.g., --roles worker,reviewer)"
          option :to, desc: "Escalation recipient (default: coworker config overseer)"
          option :config, desc: "Path to coworker config for the overseer fallback"
          option :"dry-run", type: :boolean, default: false,
            desc: "Resolve and detect conflicts without any writes"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil)
            super()
            @orchestrator = orchestrator
          end

          def call(task: nil, roles: nil, **options)
            task_ref = task.to_s.strip
            raise Ace::Support::Cli::Error, "--task is required. Usage: ace-coworker prepare --task <ref>" if task_ref.empty?

            role_list = normalize_roles(roles)
            if role_list.empty?
              raise Ace::Support::Cli::Error,
                "--roles is required. Usage: ace-coworker prepare --task <ref> --roles worker,reviewer"
            end

            orchestrator = @orchestrator || Organisms::PrepareOrchestrator.new
            result = orchestrator.call(task_ref: task_ref, roles: role_list,
              to: options[:to], config_path: options[:config],
              dry_run: options[:"dry-run"] == true)

            # Exit semantics first: quiet suppresses output, never the
            # non-zero exit a conflict must keep.
            if result.conflict?
              render(result, options[:format]) unless options[:quiet]
              conflict = result.conflict
              raise Ace::Support::Cli::Error,
                "preparation conflict: #{conflict['kind']} - #{first_line(conflict['detail'])}"
            end

            return if options[:quiet]

            render(result, options[:format])
          rescue Ace::Coworker::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def normalize_roles(raw_roles)
            Array(raw_roles)
              .flat_map { |entry| entry.to_s.split(",") }
              .map(&:strip)
              .reject(&:empty?)
              .uniq
          end

          def first_line(text)
            text.to_s.lines.first.to_s.strip
          end

          def render(result, format)
            if format == "json"
              puts JSON.pretty_generate(result.to_h)
            else
              puts render_table(result)
            end
          end

          def render_table(result)
            lines = ["Coworker prepare"]
            lines << "  task:       #{result.task}"
            lines << "  task_path:  #{result.task_path}"
            lines << "  roles:      #{result.roles.join(', ')}"
            if result.conflict?
              conflict = result.conflict
              lines << "  conflict:   #{conflict['kind']}"
              conflict["detail"].to_s.lines.map(&:strip).reject(&:empty?).each do |line|
                lines << "    #{line}"
              end
              if conflict["hitl_event"]
                delivery = conflict["delivered"] ? "delivered" : "not delivered (retry: ace-hitl send #{conflict['hitl_event']})"
                lines << "  event:      #{conflict['hitl_event']} (#{delivery})"
              end
            else
              worktree = result.worktree
              lines << "  worktree:   #{worktree['path']}"
              lines << "  branch:     #{worktree['branch']}"
              lines << format("  result:     %s", worktree["disposition"])
            end
            unless result.assignments.empty?
              lines << "  sequence:"
              result.assignments.each do |entry|
                lines << "    #{entry['position']}/#{entry['of']} #{entry['role']}: " \
                  "#{entry['assignment']} (#{entry['disposition']}, #{entry['steps']} steps)"
                lines << "        expected outcome: #{entry['outcome']}"
              end
            end
            result.worktree_assignments.each do |assignment|
              lines << "  assignment: #{assignment['id']} #{assignment['state']} (#{assignment['progress']})"
            end
            lines.join("\n")
          end
        end
      end
    end
  end
end
