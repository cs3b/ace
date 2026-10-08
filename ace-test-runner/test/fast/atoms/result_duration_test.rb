# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/test_runner/atoms/result_parser"

class ResultDurationTest < Minitest::Test
  def test_standard_and_reporter_duration_formats
    parser = Ace::TestRunner::Atoms::ResultParser.new
    ["Finished in 51.486202s", "Finished tests in 51.486202s, 0.0194 tests/s"].each do |output|
      assert_in_delta 51.486202, parser.parse_duration(output), 0.000001
    end
  end
end
