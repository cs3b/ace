# frozen_string_literal: true

require "test_helper"

module Ace
  module Lab
    module Models
      class StatusReportTest < Minitest::Test
        def report(config: {state: :configured}, runtime: {state: :valid}, state: [])
          StatusReport.new(config: config, runtime_config: runtime, state: state, root: "/tmp")
        end

        def test_ok_for_configured_even_empty
          assert report(config: {state: :configured}).ok?
          assert report(config: {state: :defaults_only}).ok?
        end

        def test_not_ok_for_invalid_config
          refute report(config: {state: :invalid, error: "boom"}).ok?
        end

        def test_not_ok_for_invalid_runtime_config
          refute report(runtime: {state: :invalid, error: "boom"}).ok?
        end

        def test_not_ok_for_location_error
          refute report(state: [{key: "tasks", state: :error}]).ok?
        end

        def test_location_error_alongside_valid_results
          report = report(state: [
            {key: "tasks", state: :present},
            {key: "hitl", state: :error}
          ])

          refute report.ok?
          assert_equal :present, report.state.first[:state]
        end

        def test_immutable
          report = self.report

          assert_raises(FrozenError) { report.state << {} }
          assert_raises(FrozenError) { report.config[:state] = :invalid }
        end

        def test_to_h_carries_ok
          payload = report.to_h

          assert_equal true, payload[:ok]
          assert_equal "/tmp", payload[:root]
        end
      end
    end
  end
end
