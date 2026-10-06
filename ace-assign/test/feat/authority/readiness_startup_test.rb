# frozen_string_literal: true
require_relative "../../test_helper"
require "open3"
require "rbconfig"

module Ace
  module Assign
    class ReadinessStartupTest < AceAssignTestCase
      def test_inherited_rubylib_is_rejected_before_external_json_code_can_execute
        with_temp_cache do |cache|
          malicious = File.join(cache, "untrusted-load")
          FileUtils.mkdir_p(malicious)
          marker = File.join(cache, "executed")
          File.write(File.join(malicious, "json.rb"), "File.write(#{marker.inspect}, 'untrusted')\n")
          script = File.expand_path("../../../exe/ace-scope-ready", __dir__)
          environment = {"RUBYLIB" => malicious, "RUBYOPT" => nil, "GEM_HOME" => nil, "GEM_PATH" => nil,
            "BUNDLE_GEMFILE" => nil, "BUNDLE_BIN_PATH" => nil, "RUBY_DEBUG_OPEN" => nil}
          output, error, status = Open3.capture3(environment, RbConfig.ruby, "--disable=gems,rubyopt", script, "slot")
          refute status.success?
          assert_empty output
          assert_match(/readiness startup features differ/, error)
          refute File.exist?(marker)
          {"RUBYOPT" => "-r#{File.join(malicious, 'json.rb')}", "GEM_HOME" => malicious,
            "GEM_PATH" => malicious, "BUNDLE_GEMFILE" => File.join(malicious, "Gemfile")}.each do |key, value|
            selected = environment.merge("RUBYLIB" => nil, key => value)
            output, error, status = Open3.capture3(selected, RbConfig.ruby, "--disable=gems,rubyopt", script, "slot")
            refute status.success?, key
            assert_empty output
            assert_match(/readiness startup features differ/, error)
            refute File.exist?(marker), key
          end
        end
      end
    end
  end
end
