# frozen_string_literal: true

require "minitest"
require_relative "test_reporter/configuration"
require_relative "test_reporter/agent_reporter"
require_relative "test_reporter/group_detector"
require_relative "test_reporter/report_generator"

module AceTools
  module TestReporter
    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield(config) if block_given?
        config
      end

      def use!
        Minitest::Reporters.use!(
          AgentReporter.new(config.to_h),
          ENV["CI"] ? {} : {color: true}
        )
      end
    end
  end
end
