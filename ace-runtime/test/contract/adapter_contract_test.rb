# frozen_string_literal: true

require "test_helper"
require "ace/runtime/testing"
require_relative "../support/fake_runtime_adapter"

module Ace
  module Runtime
    module Testing
      # Proves the packaged contract suite against the reference fake
      # adapter in both send profiles. Real adapters (ace-tmux, ace-herdr)
      # run this same battery in their own suites.
      class FakePlainPaneAdapterContractTest < AceRuntimeTestCase
        include AdapterContract
        include AdapterContract::PlainPaneSendMatrix

        def build_fixture
          ScriptedRuntime.new
        end

        def build_adapter(fixture)
          Ace::Runtime::FakeRuntimeAdapter.new(fixture: fixture, send_profile: :plain_pane)
        end
      end

      class FakeAgentAwareAdapterContractTest < AceRuntimeTestCase
        include AdapterContract
        include AdapterContract::AgentAwareSendMatrix

        def build_fixture
          ScriptedRuntime.new
        end

        def build_adapter(fixture)
          Ace::Runtime::FakeRuntimeAdapter.new(fixture: fixture, send_profile: :agent_aware)
        end
      end
    end
  end
end
