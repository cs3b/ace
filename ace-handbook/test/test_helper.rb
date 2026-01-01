# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "ace/handbook"

module Ace
  module Handbook
    # Base test case for ace-handbook tests
    class TestCase < Minitest::Test
    end
  end
end
