# frozen_string_literal: true

require_relative "simulation_writeback_mixin"

module Ace
  module Taskflow
    module Molecules
      # Upserts simulation-derived review guidance into task artifacts.
      class TaskSimulationWriteback
        include SimulationWritebackMixin
      end
    end
  end
end
