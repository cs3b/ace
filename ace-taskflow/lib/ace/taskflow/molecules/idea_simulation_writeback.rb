# frozen_string_literal: true

require_relative "simulation_writeback_mixin"

module Ace
  module Taskflow
    module Molecules
      # Upserts simulation-derived review guidance into idea artifacts.
      class IdeaSimulationWriteback
        include SimulationWritebackMixin
      end
    end
  end
end
