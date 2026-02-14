# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Add sibling gems to load path if they exist
%w[ace-support-config ace-support-core ace-support-fs ace-support-test-helpers].each do |gem_name|
  gem_path = File.expand_path("../../#{gem_name}/lib", __dir__)
  $LOAD_PATH.unshift(gem_path) if Dir.exist?(gem_path)
end

require "ace/b36ts"

require "minitest/autorun"
require "ace/test_support"

class AceB36tsTestCase < AceTestCase
  def setup
    super
    Ace::B36ts.reset_config!
  end
end
