# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/git_diff"

# Base test case for ace-git-diff tests
class AceGitDiffTestCase < AceTestCase
  def setup
    super
    # Reset config cache before each test
    Ace::GitDiff.reset_config!
  end

  def teardown
    super
    # Reset config cache after each test
    Ace::GitDiff.reset_config!
  end
end
