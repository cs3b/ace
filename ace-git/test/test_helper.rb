# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/git"

# Base test case for ace-git tests
class AceGitTestCase < AceTestCase
  def setup
    super
    # Reset ace-git config cache to ensure clean state
    Ace::Git.reset_config!
  end

  def teardown
    Ace::Git.reset_config!
    super
  end
end
