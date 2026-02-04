# frozen_string_literal: true

require "time"
require "ace/llm"

module Ace
  module E2eRunner
    module Molecules
      class TestExecutor
        def initialize(config)
          @config = config
        end

        def execute(test_scenario)
          prompt_builder = Atoms::PromptBuilder.new
          result_parser = Atoms::ResultParser.new
          start_time = Time.now

          response = Ace::LLM::QueryInterface.query(
            provider_model,
            prompt_builder.build(test_scenario),
            system: Atoms::PromptBuilder::SYSTEM_PROMPT,
            timeout: @config[:defaults][:timeout],
            temperature: @config[:defaults][:temperature],
            max_tokens: @config[:defaults][:max_tokens]
          )

          parsed = result_parser.parse(response[:text], test_id: test_scenario.id)
          Models::TestResult.new(
            test_id: parsed.test_id,
            status: parsed.status,
            test_cases: parsed.test_cases,
            summary: parsed.summary,
            duration: Time.now - start_time,
            package: test_scenario.package,
            path: test_scenario.path,
            provider: response[:provider],
            model: response[:model],
            raw_response: parsed.raw_response
          )
        rescue Ace::LLM::Error => e
          Models::TestResult.new(
            test_id: test_scenario.id,
            status: "error",
            error_type: "llm_error",
            error_class: e.class.name,
            error_message: e.message,
            error_backtrace: e.backtrace&.first(10),
            duration: Time.now - start_time,
            package: test_scenario.package,
            path: test_scenario.path
          )
        rescue StandardError => e
          Models::TestResult.new(
            test_id: test_scenario.id,
            status: "error",
            error_type: "execution_error",
            error_class: e.class.name,
            error_message: e.message,
            error_backtrace: e.backtrace&.first(10),
            duration: Time.now - start_time,
            package: test_scenario.package,
            path: test_scenario.path
          )
        end

        private

        def provider_model
          @config[:defaults][:provider] || "google:gemini-2.5-flash"
        end
      end
    end
  end
end
