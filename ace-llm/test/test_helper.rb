# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "simplecov"
SimpleCov.start

require "ace/llm"
require "ace/test_support"

# Base test case for ace-llm tests
class AceLlmTestCase < AceTestCase
  # Additional helper methods specific to ace-llm can be added here
end
