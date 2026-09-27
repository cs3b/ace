# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    class GemSkeletonTest < Minitest::Test
      def test_version_is_present
        refute_nil VERSION
      end

      def test_config_cascades_from_gem_defaults
        Ace::Herdr.reset_config!
        config = Ace::Herdr.config

        assert_equal "pi", config["default_agent_kind"]
        assert_equal 3, config.dig("delivery", "max_attempts")
        assert_equal [1, 2, 4], config.dig("delivery", "backoff_seconds")
        assert_equal ".ace-local/herdr/deliveries", config["deliveries_dir"]
      ensure
        Ace::Herdr.reset_config!
      end
    end
  end
end
