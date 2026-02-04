# frozen_string_literal: true

require "fugit"

module Ace
  module Scheduler
    module Atoms
      class CronParser
        def parse(expression)
          Fugit.parse(expression)
        end

        def valid?(expression)
          !!Fugit.parse(expression)
        end
      end
    end
  end
end
