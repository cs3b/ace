# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "tmpdir"
require "fileutils"
require "yaml"
require "minitest/autorun"
require "ace/test_support"
require "ace/handbook"

module Ace
  module Handbook
    TestCase = AceTestCase
  end
end
