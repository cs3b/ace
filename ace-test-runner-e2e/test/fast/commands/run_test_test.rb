# frozen_string_literal: true

require_relative "../../test_helper"

class RunTestTest < Minitest::Test
  RunTest = Ace::Test::EndToEndRunner::CLI::Commands::RunTest

  def test_parse_tags_normalizes_values
    command = RunTest.new

    tags = command.send(:parse_tags, "Smoke, happy-path, use-case:Lint")

    assert_equal ["smoke", "happy-path", "use-case:lint"], tags
  end

  def test_parse_tags_handles_blank_value
    command = RunTest.new

    assert_equal [], command.send(:parse_tags, nil)
    assert_equal [], command.send(:parse_tags, "   ")
  end
end
