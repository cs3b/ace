# frozen_string_literal: true

module Ace
  module Demo
    module Models
      class CastRecording
        attr_reader :header, :events

        def initialize(header:, events:)
          @header = header
          @events = events
        end
      end
    end
  end
end
