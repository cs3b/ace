# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

%w[ace-support-config ace-support-core ace-support-test-helpers].each do |gem_name|
  gem_path = File.expand_path("../../#{gem_name}/lib", __dir__)
  $LOAD_PATH.unshift(gem_path) if Dir.exist?(gem_path)
end

require "ace/demo"
require "minitest/autorun"
require "ace/test_support"

class AceDemoTestCase < AceTestCase
end
