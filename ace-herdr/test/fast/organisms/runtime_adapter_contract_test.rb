# frozen_string_literal: true

require "test_helper"
require "ace/runtime/testing"
require_relative "../../support/scripted_herdr_executor"

# Consumer-side contract bindings: these classes live in the ace-herdr test
# suite, outside the packaged Ace::Runtime::Testing namespace; they only
# include the shared contract modules and bind them to the herdr adapter.

# Agent-panes contract pass: prepared targets carry a live agent, so sends
# take the prompt path and the agent-aware matrix applies.
class HerdrAdapterContractTest < Minitest::Test
  include Ace::Runtime::Testing::AdapterContract
  include Ace::Runtime::Testing::AdapterContract::AgentAwareSendMatrix

  def setup
    @identity_dir = Dir.mktmpdir("herdr-contract-tabs")
    super
  end

  def teardown
    FileUtils.remove_entry(@identity_dir)
  end

  def build_fixture
    Ace::Runtime::Testing::ScriptedRuntime.new
  end

  def build_adapter(fixture)
    executor = HerdrContractSupport::ScriptedExecutor.new(fixture)
    surface = HerdrContractSupport::ScriptedSurface.new(executor: executor)
    Ace::Herdr::Organisms::RuntimeAdapter.new(executor: executor,
      surface: surface, env: HerdrContractSupport::FixtureEnv.new(fixture),
      identity_dir: @identity_dir)
  end

  def prepare_target!(name: "work", root: "/tmp/ace-runtime-contract")
    super.tap { fixture.set_agent_state(@contract_pane, "idle") }
  end
end

# Agentless-panes contract pass: prepared targets are plain shells, so sends
# take the ordered plain-pane path and its matrix applies.
class HerdrAdapterPlainPaneContractTest < Minitest::Test
  include Ace::Runtime::Testing::AdapterContract
  include Ace::Runtime::Testing::AdapterContract::PlainPaneSendMatrix

  def setup
    @identity_dir = Dir.mktmpdir("herdr-contract-tabs")
    super
  end

  def teardown
    FileUtils.remove_entry(@identity_dir)
  end

  def build_fixture
    Ace::Runtime::Testing::ScriptedRuntime.new
  end

  def build_adapter(fixture)
    executor = HerdrContractSupport::ScriptedExecutor.new(fixture)
    surface = HerdrContractSupport::ScriptedSurface.new(executor: executor)
    adapter = Ace::Herdr::Organisms::RuntimeAdapter.new(executor: executor,
      surface: surface, env: HerdrContractSupport::FixtureEnv.new(fixture),
      identity_dir: @identity_dir)
    # Agentless panes take the plain-pane transport; the declared profile
    # stays agent-aware on the adapter itself.
    PlainProfileAdapter.new(adapter)
  end

  # Transparent wrapper so the packaged stall-retry counting sees the
  # transport profile the agentless panes actually exercise. `send` must be
  # forwarded explicitly — the wrapper itself does not define it, so
  # Kernel#send would otherwise capture the call.
  class PlainProfileAdapter
    def initialize(adapter)
      @adapter = adapter
    end

    def send_profile
      :plain_pane
    end

    def send(pane:, command: nil, items: [])
      @adapter.send(pane: pane, command: command, items: items)
    end

    def method_missing(name, *args, **kwargs, &block)
      return @adapter.public_send(name, *args, **kwargs, &block) if @adapter.respond_to?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      @adapter.respond_to?(name, include_private) || super
    end
  end
end
