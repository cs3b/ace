# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Renders the executor brief (table or json). Pure formatting.
      class BriefFormatter
        def self.format_table(brief)
          h = brief.to_h
          lines = []
          lines << "Coworker brief"
          lines << "  toolchain:         #{h.dig('toolchain', 'mode')}"
          if h.dig("toolchain", "mode") == "installed"
            lines << "  runtime rule:      keep ACE_TOOLCHAIN=installed; use installed ACE commands and packaged generic instructions, never project binstubs or bundle exec"
            lines << "  project context:   retain domain instructions/tasks/config; source-development launch advice does not select this runtime"
          end
          lines << "  role:              #{h['role']}"
          lines << "  instructions:      #{h['instructions']}"
          lines << "  instructions src:  #{h['instructions_source']}"
          lines << "  start prompt:      #{h['start_prompt']}"
          lines << "  task:              #{h['task']} (#{h['task_path']})"
          lines << "  assignment:        drive with --assignment #{h['assignment']}"
          lines << "  assignment state:  #{h['assignment_state']} (#{h['assignment_progress']})"
          lines << "  overseer:          #{h['overseer']} (channel: #{h['reporting_channel']})"
          lines << "  on failure:        #{h['on_failure']}"
          lines << "  report with:      ace-coworker report --assignment #{h['assignment']}"
          lines << "  project root:      #{h['project_root']}"
          lines.join("\n")
        end

        def self.format_json(brief)
          require "json"
          JSON.pretty_generate(brief.to_h)
        end
      end
    end
  end
end
