# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/git"

# Base test case for ace-git tests
class AceGitTestCase < AceTestCase
end
