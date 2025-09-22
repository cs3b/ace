# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/taskflow"
require "ace/test_support"
require "tmpdir"
require "fileutils"

# AceTestCase is provided by ace-test-support
# It includes all the helper methods we need