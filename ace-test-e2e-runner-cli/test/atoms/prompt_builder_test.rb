# frozen_string_literal: true

require "test_helper"

module Ace
  module E2eRunner
    class PromptBuilderTest < AceE2eRunnerTestCase
      def test_build_includes_test_id_and_content
        scenario = Models::TestScenario.new(
          id: "MT-TEST-001",
          title: "Sample",
          area: "lint",
          package: "ace-lint",
          path: "test/e2e/MT-TEST-001.mt.md",
          content: "# Title\n\nDo the thing.",
          frontmatter: {}
        )

        builder = Atoms::PromptBuilder.new
        prompt = builder.build(scenario)

        assert_includes prompt, "MT-TEST-001"
        assert_includes prompt, "ace-lint"
        assert_includes prompt, "Do the thing."
      end
    end
  end
end
