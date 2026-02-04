# frozen_string_literal: true

module Ace
  module Scheduler
    module Models
      class EventTrigger
        attr_reader :name, :description, :triggers

        def initialize(name:, triggers:, description: nil)
          @name = name
          @description = description
          @triggers = triggers
        end
      end
    end
  end
end
