# frozen_string_literal: true

require_relative "suite/orchestrator"
require_relative "suite/process_monitor"
require_relative "suite/display_manager"
require_relative "suite/result_aggregator"

module Ace
  module TestRunner
    module Suite
      class Error < StandardError; end

      def self.run(config_path = ".ace/test-suite.yml")
        orchestrator = Orchestrator.new(config_path)
        orchestrator.run
      end
    end
  end
end