# frozen_string_literal: true

require "test_helper"

module Ace
  module E2eRunner
    class RunIdGeneratorTest < AceE2eRunnerTestCase
      def test_generates_six_char_id
        generator = Atoms::RunIdGenerator.new
        run_id = generator.generate(time: Time.utc(2026, 2, 4, 12, 0, 0))

        assert_equal 6, run_id.length
      end
    end
  end
end
