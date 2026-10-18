# frozen_string_literal: true

require_relative "hitl_address"

module Ace
  module Hitl
    module Atoms
      # Shared, adapter-independent rendering of a HITL event for delivery.
      # Every route receives the identical text — the adapter translates
      # transport, not role rules. Pure; no IO.
      class HitlEventText
        # @param event [Models::HitlEvent]
        # @return [String] single rendered message body
        def self.call(event)
          lines = []
          if event.report?
            lines << "[HITL report #{event.result}] #{event.title} (case #{event.id})"
            body_lines(event).each { |line| lines << line }
          else
            lines << "[HITL question] #{event.title} (case #{event.id})"
            questions = event.questions.empty? ? ["(pending human input)"] : event.questions
            questions.each { |q| lines << "Q: #{q}" }
            if event.reply_to
              lines << "Reply-To: #{HitlAddress.to_s(event.reply_to)}"
            end
          end

          context_lines(event).each { |line| lines << line }
          lines.join("\n")
        end

        # Report body = the `## Report` section the creator writes. The
        # section boundary is the next `## ` heading; reports are created by
        # HitlCreator with plain `- ` content lines only, so nothing is lost
        # for creator-written reports (documented boundary).
        def self.body_lines(event)
          body = event.content.to_s
          report_section = body.split(/^## Report\s*$/m, 2)[1].to_s
          report_section = report_section.sub(/\A\n+/, "").split(/^## /m, 2)[0].to_s
          lines = report_section.lines.map(&:strip).reject(&:empty?)
          lines.empty? ? ["(no content)"] : lines
        end

        def self.context_lines(event)
          lines = []
          lines << "Task: #{event.metadata["task"]}" if event.metadata["task"].to_s.strip != ""
          lines << "Assignment: #{event.metadata["assignment"]}" if event.metadata["assignment"].to_s.strip != ""
          lines << "Step: #{event.metadata["step"]}" if event.metadata["step"].to_s.strip != ""
          lines
        end
      end
    end
  end
end
