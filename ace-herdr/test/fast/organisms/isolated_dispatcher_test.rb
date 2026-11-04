# frozen_string_literal: true
require "test_helper"
require "open3"
require "rbconfig"
require "ace/herdr/organisms/isolated_dispatcher"

class IsolatedDispatcherTest < Minitest::Test
  def test_standalone_dispatch_loads_complete_lab_runtime_before_manifest_read
    code = <<~'RUBY'
      require "ace/herdr"
      require "ace/herdr/organisms/isolated_dispatcher"
      # The native CLI starts with Herdr, not the Lab test helper. The default
      # loader must initialize Lab itself before evaluating its default path.
      dispatcher = Ace::Herdr::Organisms::IsolatedDispatcher.new(executor: Object.new,
        env: {"ACE_TOOLCHAIN" => "installed"})
      begin
        dispatcher.dispatch(label: "probe", prompt: "probe", kind: "pi",
          workspace_id: "w1", pane: nil, cwd: "/", role: "worker")
      rescue Ace::Herdr::ValidationError, Ace::Lab::InvalidConfigurationError
        abort "incomplete lab runtime" unless Ace::Lab.respond_to?(:install_manifest_path) &&
          Ace::Lab.respond_to?(:host_platform)
        puts "configured refusal"
      end
    RUBY
    out, err, status = Open3.capture3(RbConfig.ruby, "-I", $LOAD_PATH.join(File::PATH_SEPARATOR), "-e", code)
    assert status.success?, err
    assert_includes out, "configured refusal"
    refute_includes err, "NoMethodError"
  end

  def setup
    @calls = []
    @agent = {"terminal_id" => "term_abc", "cwd" => "/lab/ace/.ace-wt/task-1",
      "isolated_session" => {"project" => "ace", "role" => "verifier"},
      "interactive_ready" => true, "launch_pending" => false}
    calls, agent = @calls, @agent
    @executor = Object.new
    reply = ->(value) { Struct.new(:parsed_json).new({"result" => value}) }
    @executor.define_singleton_method(:agent_list) { calls << [:list]; reply.call("agents" => []) }
    @executor.define_singleton_method(:agent_start_isolated) { |**args| calls << [:start, args]; reply.call("agent" => agent.dup) }
    @executor.define_singleton_method(:agent_wait) { |**args| calls << [:wait, args]; reply.call("agent" => agent.dup) }
    @executor.define_singleton_method(:agent_prompt) { |**args| calls << [:prompt, args]; reply.call("type" => "agent_prompted", "agent" => agent.dup) }
    @dispatch = Ace::Herdr::Organisms::IsolatedDispatcher.new(executor: @executor,
      env: {"ACE_TOOLCHAIN" => "installed"}, loader: -> { {"projects" => [{"id" => "ace", "path" => "/lab/ace"}]} })
  end

  def call(**options)
    File.stub(:realpath, ->(path) { path }) do
      @dispatch.dispatch(**{label: "8y0.t.x27", prompt: "verify assignment", kind: "pi",
        workspace_id: "w1", pane: nil, cwd: "/lab/ace/.ace-wt/task-1", role: "verifier"}.merge(options))
    end
  end

  def test_public_dispatcher_routes_isolated_session_and_discovers_native_workspace
    old = ENV.to_h.slice("ACE_LAB_SESSION", "ACE_TOOLCHAIN", "HERDR_WORKSPACE_ID")
    ENV["ACE_LAB_SESSION"], ENV["ACE_TOOLCHAIN"] = "1", "installed"
    ENV.delete("HERDR_WORKSPACE_ID")
    @executor.define_singleton_method(:pane_current) do
      Struct.new(:parsed_json).new({"result" => {"pane" => {"workspace_id" => "w1"}}})
    end
    outer = Ace::Herdr::Organisms::Dispatcher.new(executor: @executor,
      default_agent_kind: "pi", agent_start_timeout_ms: 60_000)
    File.stub(:realpath, ->(path) { path }) do
      Ace::Herdr::Organisms::IsolatedDispatcher.stub(:new, @dispatch) do
        outcome = outer.dispatch(label: "review", prompt: "verify assignment",
          cwd: "/lab/ace/.ace-wt/task-1", role: "verifier")
        assert_equal "w1", outcome.workspace_id
        assert_equal "term_abc", outcome.pane
        assert outcome.prompted
      end
    end
  ensure
    %w[ACE_LAB_SESSION ACE_TOOLCHAIN HERDR_WORKSPACE_ID].each { |key| ENV[key] = old[key] }
  end

  def test_dispatch_uses_configured_launcher_and_only_waits_for_input_acceptance
    outcome = call
    assert_equal "term_abc", outcome.pane
    assert outcome.prompted
    assert_match(/\A[a-z][a-z0-9_-]{0,31}\z/, outcome.agent_name)
    assert_equal [:list, :start, :wait, :prompt], @calls.map(&:first)
    assert_equal "verifier", @calls[1][1][:role]
    assert_equal "/lab/ace/.ace-wt/task-1", @calls[1][1][:cwd]
    assert_equal ["idle"], @calls[2][1][:until_states]
    refute @calls.last[1].key?(:wait)
  end

  def test_foreign_directory_existing_pane_or_unready_worker_never_receives_prompt
    assert_raises(Ace::Herdr::ValidationError) { call(cwd: "/lab/other") }
    assert_raises(Ace::Herdr::ValidationError) { call(pane: "w1:p1") }
    assert_empty @calls
    @agent["interactive_ready"] = false
    assert_raises(Ace::Herdr::AgentNotReadyError) { call }
    refute @calls.any? { |entry| entry.first == :prompt }
  end

  def test_existing_name_is_preserved_without_duplicate_launch_or_prompt
    @executor.define_singleton_method(:agent_list) do
      Struct.new(:parsed_json).new({"result" => {"agents" => [{"name" => "worker"}]}})
    end
    assert_raises(Ace::Herdr::ValidationError) { call(label: "worker") }
    assert_empty @calls
  end
end
