# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "ace/test"

module Ace
  module Test
    # Base test case for ace-test tests
    class TestCase < Minitest::Test
    end
  end
end
