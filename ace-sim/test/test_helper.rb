# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

%w[ace-support-config ace-support-core ace-support-fs ace-support-test-helpers ace-b36ts].each do |gem_name|
  gem_path = File.expand_path("../../#{gem_name}/lib", __dir__)
  $LOAD_PATH.unshift(gem_path) if Dir.exist?(gem_path)
end

require "ace/sim"
require "minitest/autorun"
require "ace/test_support"

class AceSimTestCase < AceTestCase
  def setup
    super
    Ace::Sim.reset_config!
  end
end
