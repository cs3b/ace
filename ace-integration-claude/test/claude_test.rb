# frozen_string_literal: true

require_relative "test_helper"

module Ace
  module Integration
    module Claude
      class ClaudeTest < TestCase
        def test_version_defined
          assert_kind_of String, Ace::Integration::Claude::VERSION
          refute_empty Ace::Integration::Claude::VERSION
        end
      end
    end
  end
end
