# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "minitest/pride"
require "ace/test_support"

# Alias for convenience
AceTaskflowTestCase = Ace::TestSupport::BaseTestCase

# Add with_test_project helper for backward compatibility
module Minitest
  class Test
    def with_test_project(&block)
      with_temp_dir(&block)
    end
  end
end
