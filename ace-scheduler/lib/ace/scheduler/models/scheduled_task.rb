# frozen_string_literal: true

module Ace
  module Scheduler
    module Models
      class ScheduledTask
        attr_reader :name, :cron, :command, :enabled, :description, :timeout

        def initialize(name:, cron:, command:, enabled: true, description: nil, timeout: nil)
          @name = name
          @cron = cron
          @command = command
          @enabled = enabled
          @description = description
          @timeout = timeout
        end

        def enabled?
          !!@enabled
        end
      end
    end
  end
end
