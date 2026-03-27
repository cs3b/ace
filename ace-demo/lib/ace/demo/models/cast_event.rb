# frozen_string_literal: true

module Ace
  module Demo
    module Models
      class CastEvent
        attr_reader :time, :type, :data

        def initialize(time:, type:, data:)
          @time = time
          @type = type
          @data = data
        end
      end
    end
  end
end
