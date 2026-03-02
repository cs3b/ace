# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

%w[
  ace-assign
  ace-git
  ace-git-worktree
  ace-task
  ace-tmux
  ace-support-config
  ace-support-core
  ace-support-fs
  ace-support-test-helpers
].each do |gem_name|
  gem_path = File.expand_path("../../#{gem_name}/lib", __dir__)
  $LOAD_PATH.unshift(gem_path) if Dir.exist?(gem_path)
end

require "ace/overseer"

require "minitest/autorun"
require "ace/test_support"

class AceOverseerTestCase < AceTestCase
  def setup
    super
    Ace::Overseer.reset_config!
  end
end
