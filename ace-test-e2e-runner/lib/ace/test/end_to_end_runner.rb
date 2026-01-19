# frozen_string_literal: true

require_relative "end_to_end_runner/version"

module Ace
  module Test
    module EndToEndRunner
      # Entry point for gem
      #
      # This gem provides infrastructure for agent-executed end-to-end tests:
      # - Workflows for test execution (run-e2e-test.wf.md)
      # - Templates for test scenarios (test-scenario.template.md)
      # - Conventions for manual testing (manual-testing.g.md)
      #
      # Tests are executed by AI agents, not by automated test runners.
      # See handbook/ for workflows and guides.
    end
  end
end
