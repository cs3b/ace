# frozen_string_literal: true

require_relative "test_helper"

class DemoConfigTest < AceDemoTestCase
  def test_load_config_warns_and_falls_back_to_empty_hash
    Ace::Support::Config.stub(:create, proc { raise ArgumentError, "bad config" }) do
      _stdout, stderr = capture_io do
        config = Ace::Demo.send(:load_config)
        assert_equal({}, config)
      end

      assert_includes stderr, "ace-demo config load failed (ArgumentError): bad config"
      assert_includes stderr, "Using defaults."
    end
  end
end
