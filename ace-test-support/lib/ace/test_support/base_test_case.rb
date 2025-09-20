# frozen_string_literal: true

require 'minitest/test'

module Ace
  module TestSupport
    # Base test case class with common utilities for all ace-* gems
    class BaseTestCase < Minitest::Test
      include TestHelper

      def fixture_path(path)
        File.expand_path("fixtures/#{path}", File.dirname(caller_locations(1, 1)[0].path))
      end

      def setup
        @original_pwd = Dir.pwd
        super
      end

      def teardown
        Dir.chdir(@original_pwd) if @original_pwd
        super
      end
    end

    # Alias for backward compatibility
    AceTestCase = BaseTestCase
  end
end

# Make AceTestCase available at top level for convenience
AceTestCase = Ace::TestSupport::AceTestCase