# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/git"

# Base test case for ace-git tests
class AceGitTestCase < AceTestCase
  def teardown
    super
    # Reset config cache after each test to ensure clean state
    # Note: Only in teardown to avoid redundant calls (setup is implicit clean state)
    Ace::Git.reset_config!
  end
end
