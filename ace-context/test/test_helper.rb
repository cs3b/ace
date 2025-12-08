# frozen_string_literal: true

require "ace/context"
require "ace/test_support"
require_relative "support/command_mock_helper"

# AceTestCase is provided by ace-support-test-helpers with all helpers

# Enable command mocking for all tests to ensure deterministic, fast execution
CommandMockHelper.enable_mocking!