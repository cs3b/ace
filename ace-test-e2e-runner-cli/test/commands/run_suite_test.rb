# frozen_string_literal: true

require "test_helper"

module Ace
  module E2eRunner
    class RunSuiteTest < AceE2eRunnerTestCase
      def test_rejects_package_argument
        command = CLI::Commands::RunSuite.new
        error = assert_raises(Ace::Core::CLI::Error) do
          command.call(unused: "ace-coworker")
        end

        assert_includes error.message, "ace-e2e-test-suite runs globally"
      end
    end
  end
end
