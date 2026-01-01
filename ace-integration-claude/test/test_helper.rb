# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "ace/integration/claude"

module Ace
  module Integration
    module Claude
      # Base test case for ace-integration-claude tests
      class TestCase < Minitest::Test
      end
    end
  end
end
