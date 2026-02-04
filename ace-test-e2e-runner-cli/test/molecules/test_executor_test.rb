# frozen_string_literal: true

require "test_helper"

module Ace
  module E2eRunner
    class TestExecutorTest < AceE2eRunnerTestCase
      def test_execute_returns_parsed_result
        config = {
          defaults: {
            provider: "google:gemini-2.5-flash",
            timeout: 1,
            temperature: 0.1,
            max_tokens: 10
          },
          execution: {}
        }

        scenario = Models::TestScenario.new(
          id: "MT-EXEC-001",
          title: "Sample",
          area: "lint",
          package: "ace-lint",
          path: "test/e2e/MT-EXEC-001.mt.md",
          content: "Run it",
          frontmatter: {}
        )

        response = {
          text: '{"test_id":"MT-EXEC-001","status":"pass","summary":"ok"}',
          provider: "google",
          model: "gemini-2.5-flash"
        }

        executor = Molecules::TestExecutor.new(config)
        Ace::LLM::QueryInterface.stub(:query, response) do
          result = executor.execute(scenario)
          assert_equal "pass", result.status
          assert_equal "MT-EXEC-001", result.test_id
          assert_equal "ok", result.summary
        end
      end
    end
  end
end
