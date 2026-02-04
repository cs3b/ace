# frozen_string_literal: true

require "test_helper"

module Ace
  module E2eRunner
    class ReportPathBuilderTest < AceE2eRunnerTestCase
      def test_build_paths
        builder = Atoms::ReportPathBuilder.new(base_dir: ".cache/ace-test-e2e")
        paths = builder.build(test_id: "MT-COWORKER-001", package: "ace-coworker", run_id: "8p3ywe")

        assert_equal ".cache/ace-test-e2e/8p3ywe-coworker-mt001", paths[:test_dir]
        assert_equal ".cache/ace-test-e2e/8p3ywe-coworker-mt001-reports", paths[:report_dir]
        assert_equal "mt001", paths[:short_id]
      end
    end
  end
end
