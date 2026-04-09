# frozen_string_literal: true

require_relative "end_to_end_runner/version"

# Models
require_relative "end_to_end_runner/models/test_case"
require_relative "end_to_end_runner/models/test_scenario"
require_relative "end_to_end_runner/models/test_result"

# Atoms
require_relative "end_to_end_runner/atoms/prompt_builder"
require_relative "end_to_end_runner/atoms/result_parser"
require_relative "end_to_end_runner/atoms/skill_prompt_builder"
require_relative "end_to_end_runner/atoms/skill_result_parser"
require_relative "end_to_end_runner/atoms/suite_report_prompt_builder"
require_relative "end_to_end_runner/atoms/test_case_parser"
require_relative "end_to_end_runner/atoms/tc_fidelity_validator"
require_relative "end_to_end_runner/atoms/display_helpers"

# Molecules
require_relative "end_to_end_runner/molecules/fixture_copier"
require_relative "end_to_end_runner/molecules/scenario_loader"
require_relative "end_to_end_runner/molecules/setup_executor"
require_relative "end_to_end_runner/molecules/config_loader"
require_relative "end_to_end_runner/molecules/test_discoverer"
require_relative "end_to_end_runner/molecules/integration_runner"
require_relative "end_to_end_runner/molecules/test_executor"
require_relative "end_to_end_runner/molecules/pipeline_sandbox_builder"
require_relative "end_to_end_runner/molecules/pipeline_prompt_bundler"
require_relative "end_to_end_runner/molecules/pipeline_report_generator"
require_relative "end_to_end_runner/molecules/pipeline_executor"
require_relative "end_to_end_runner/molecules/report_writer"
require_relative "end_to_end_runner/molecules/suite_report_writer"
require_relative "end_to_end_runner/molecules/simple_display_manager"
require_relative "end_to_end_runner/molecules/progress_display_manager"
require_relative "end_to_end_runner/molecules/suite_simple_display_manager"
require_relative "end_to_end_runner/molecules/suite_progress_display_manager"
require_relative "end_to_end_runner/molecules/affected_detector"
require_relative "end_to_end_runner/molecules/failure_finder"

# Organisms
require_relative "end_to_end_runner/organisms/test_orchestrator"
require_relative "end_to_end_runner/organisms/suite_orchestrator"

# CLI
require_relative "end_to_end_runner/cli/commands/run_test"
require_relative "end_to_end_runner/cli/commands/run_suite"

module Ace
  module Test
    module EndToEndRunner
      # Entry point for gem
      #
      # This gem provides infrastructure for agent-executed end-to-end tests:
      # - CLI command (ace-test-e2e) for running tests via LLM
      # - Workflows for test execution (run-e2e-test.wf.md)
      # - Templates for test scenarios (test-e2e.template.md)
      # - Conventions for E2E testing (e2e-testing.g.md)
      #
      # Tests can be executed by AI agents or via the CLI tool.
      # See handbook/ for workflows and guides.

      REFRESH_INTERVAL = 0.25

      # Module namespaces
      module Atoms; end
      module Molecules; end
      module Organisms; end
      module Models; end
    end
  end
end
