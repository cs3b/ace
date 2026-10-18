# frozen_string_literal: true

require "time"

module Ace
  module Coworker
    module Atoms
      # Pure rendering of the durable task-folder record markdown.
      class ReportRecordFormatter
        # @param outcome [Models::Outcome]
        # @param cfg [Models::Config]
        # @param extras [Hash] event_id:, delivery:, record_path:
        # @return [String] markdown document
        def self.format(outcome, cfg, event_id: nil, delivery: nil, record_path: nil)
          lines = []
          lines << "---"
          lines << "task: #{cfg.task}"
          lines << "assignment: #{cfg.assignment}"
          lines << "result: #{outcome.result}"
          lines << "verdict: #{outcome.verdict}"
          lines << "event_id: #{event_id}" if event_id
          # Delivery can carry free-form failure detail ("failed: <cause>");
          # serialize the value so the frontmatter stays parseable YAML.
          lines << "delivery: #{delivery.to_s.inspect}" if delivery
          lines << "updated_at: #{Time.now.utc.iso8601}"
          lines << "---"
          lines << ""
          lines << "# #{outcome.success? ? "Work done" : "Assignment failed"} - #{cfg.task}/#{cfg.assignment}"
          lines << ""
          if outcome.success?
            lines << "Assignment completed (#{outcome.evidence["progress"]})."
          else
            lines << "## Cause"
            lines << ""
            lines << outcome.cause
            lines << ""
            lines << "## Unfinished steps"
            lines << ""
            if outcome.unfinished_steps.empty?
              lines << "- (none recorded)"
            else
              outcome.unfinished_steps.each { |step| lines << "- #{step}" }
            end
          end
          lines << ""
          lines << "## Evidence"
          lines << ""
          lines << "- record: #{record_path}" if record_path
          lines << "- reports: .ace-local/assign/#{cfg.assignment}/reports/"
          lines << "- event: .ace-local/hitl/ (#{event_id})" if event_id
          lines << ""
          lines << "## Delivery"
          lines << ""
          lines << (delivery ? "- #{delivery}" : "- (not attempted)")
          lines.join("\n") + "\n"
        end
      end
    end
  end
end
