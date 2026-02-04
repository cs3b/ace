# frozen_string_literal: true

require "fugit"

module Ace
  module Scheduler
    module Atoms
      class NextRunCalculator
        def calculate(cron_expression, from: Time.now)
          cron = Fugit.parse(cron_expression)
          return nil unless cron

          cron.next_time(from).to_t
        end

        def time_until(next_run, from: Time.now)
          return "-" unless next_run

          seconds = (next_run - from).to_i
          return "now" if seconds <= 0

          minutes = (seconds / 60) % 60
          hours = (seconds / 3600) % 24
          days = seconds / 86_400

          parts = []
          parts << "#{days}d" if days.positive?
          parts << "#{hours}h" if hours.positive?
          parts << "#{minutes}m" if minutes.positive?
          parts.empty? ? "<1m" : parts.join(" ")
        end
      end
    end
  end
end
