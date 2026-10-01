# frozen_string_literal: true

require "test_helper"
require "ace/runtime/testing"
require_relative "../../support/scripted_herdr_executor"

module Ace
  module Runtime
    module Testing
      class HerdrAdapterContractTest < Minitest::Test
        include AdapterContract
        include AdapterContract::AgentAwareSendMatrix

        def setup
          @identity_dir = Dir.mktmpdir("herdr-contract-tabs")
          super
        end

        def teardown
          FileUtils.remove_entry(@identity_dir)
        end

        def build_fixture
          ScriptedRuntime.new
        end

        def build_adapter(fixture)
          executor = HerdrContractSupport::ScriptedExecutor.new(fixture)
          surface = HerdrContractSupport::ScriptedSurface.new(executor: executor)
          Ace::Herdr::Organisms::RuntimeAdapter.new(executor: executor,
            surface: surface, env: HerdrContractSupport::FixtureEnv.new(fixture),
            identity_dir: @identity_dir)
        end
      end
    end
  end
end
