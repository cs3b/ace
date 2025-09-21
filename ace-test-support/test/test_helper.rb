# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/test_support"

# Since ace-test-support provides test infrastructure for other gems,
# we need to test it using Minitest directly without circular dependencies
require "minitest/autorun"