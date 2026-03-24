# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/test_runner/suite"

module Ace
  module TestRunner
    module Suite
      class OrchestratorTest < Minitest::Test
        def setup
          @packages = [
            {"name" => "ace-support-core", "path" => File.expand_path("../../..", __dir__)}
          ]
        end

        def test_create_display_manager_returns_simple_by_default
          config = {
            "test_suite" => {
              "packages" => @packages
            }
          }

          orchestrator = Orchestrator.new(config)
          display_manager = orchestrator.send(:create_display_manager)

          assert_instance_of SimpleDisplayManager, display_manager
        end

        def test_create_display_manager_returns_simple_when_progress_false
          config = {
            "test_suite" => {
              "packages" => @packages,
              "progress" => false
            }
          }

          orchestrator = Orchestrator.new(config)
          display_manager = orchestrator.send(:create_display_manager)

          assert_instance_of SimpleDisplayManager, display_manager
        end

        def test_create_display_manager_returns_animated_when_progress_true
          config = {
            "test_suite" => {
              "packages" => @packages,
              "progress" => true
            }
          }

          orchestrator = Orchestrator.new(config)
          display_manager = orchestrator.send(:create_display_manager)

          assert_instance_of DisplayManager, display_manager
        end
      end
    end
  end
end
