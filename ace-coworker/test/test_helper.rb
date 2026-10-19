# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

%w[
  ace-assign
  ace-git-worktree
  ace-hitl
  ace-nav
  ace-task
  ace-support-config
  ace-support-core
  ace-support-fs
  ace-support-items
  ace-support-nav
  ace-support-test-helpers
].each do |gem_name|
  gem_path = File.expand_path("../../#{gem_name}/lib", __dir__)
  $LOAD_PATH.unshift(gem_path) if Dir.exist?(gem_path)
end

require "ace/coworker"
require "ace/coworker/cli"

require "minitest/autorun"
require "ace/test_support"

class AceCoworkerTestCase < AceTestCase
  def setup
    super
    Ace::Coworker.reset_config!
  end
end
