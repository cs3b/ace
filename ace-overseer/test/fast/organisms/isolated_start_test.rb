# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/organisms/isolated_start"

class IsolatedStartTest < Minitest::Test
  Result = Struct.new(:parsed_json)
  def setup
    @root = File.realpath(Dir.mktmpdir)
    @env = {"ACE_TOOLCHAIN" => "installed", "ACE_LAB_SESSION" => "1"}
    @document = {"projects" => [{"id" => "ace", "path" => @root}], "roles" => [{"id" => "project-overseer", "instructions" => "wfi://overseer/start"}],
      "session_runtime" => {"model" => "test/model"}}
    @calls = []
    @agent = {"name" => "overseer-ace", "terminal_id" => "term_1234", "workspace_id" => "w2",
      "isolated_session" => {"project" => "ace", "role" => "project-overseer"}}
    @existing = []
    owner = self
    @executor = Object.new
    %i[agent_list workspace_list workspace_create agent_start_isolated agent_wait agent_prompt].each do |method|
      @executor.define_singleton_method(method) { |**args| owner.execute(method, args) }
    end
    @client = Object.new
    @client.define_singleton_method(:readiness) { |**args| owner.readiness(args) }
    @resolver = Object.new
    @resolver.define_singleton_method(:resolve) { |cwd:| cwd }
  end

  def teardown = FileUtils.remove_entry(@root)

  def execute(method, args)
    @calls << [method, args]
    raise Ace::Herdr::CommandError, "lost acknowledgement" if method == :agent_prompt && @lost_prompt_ack
    value = case method
    when :agent_list then {"agents" => @existing}
    when :workspace_list then {"workspaces" => []}
    when :workspace_create then {"workspace" => {"workspace_id" => "w2", "label" => "ace"}}
    when :agent_start_isolated then {"agent" => @agent}
    when :agent_wait then {"agent" => @agent.merge("interactive_ready" => !@not_ready)}
    when :agent_prompt then {"type" => "agent_prompted", "agent" => @agent}
    end
    Result.new({"result" => value})
  end

  def readiness(args)
    @calls << [:readiness, args]
    {"ready" => true, "root" => @root, "role" => "project-overseer", "terminal_id" => "term_1234"}
  end

  def operation
    Ace::Overseer::Organisms::IsolatedStart.new(executor: @executor, cwd: @root, env: @env,
      scope: "project", loader: -> { @document }, client: @client, root_resolver: @resolver)
  end

  def test_start_uses_protected_launcher_then_one_prompt_without_waiting_for_model_work
    report = operation.call
    assert_equal "started", report["status"]
    refute report["ready"]
    assert_equal %i[agent_list workspace_list workspace_create agent_start_isolated agent_wait agent_prompt], @calls.map(&:first)
    assert_equal({name: "overseer-ace", workspace_id: "w2", project: "ace", role: "project-overseer"}, @calls[3][1])
    assert_equal ["idle"], @calls[4][1][:until_states]
    refute @calls.last[1].key?(:wait)
  end

  def test_noninteractive_admission_never_receives_first_prompt
    @not_ready = true
    assert_raises(Ace::Overseer::Error) { operation.call }
    refute @calls.any? { |method, _| method == :agent_prompt }
  end

  def test_lab_start_selects_coordinator_without_starting_children
    @document["coordinator"] = {"id" => "lab", "path" => @root}
    @document["roles"] << {"id" => "lab-overseer", "instructions" => "wfi://overseer/lab-start"}
    @agent = @agent.merge("name" => "lab-overseer", "isolated_session" => {"project" => "lab", "role" => "lab-overseer"})
    operation = Ace::Overseer::Organisms::IsolatedStart.new(executor: @executor, cwd: @root, env: @env,
      loader: -> { @document }, client: @client, root_resolver: @resolver)
    report = operation.call
    assert_equal "lab", report["scope"]
    assert_equal "lab-overseer", @calls.find { |method, _| method == :agent_start_isolated }[1][:role]
    assert_equal 1, @calls.count { |method, _| method == :agent_start_isolated }
  end

  def test_reuse_only_checks_evidence_and_never_resubmits_uncertain_prompt
    @existing = [@agent]
    report = operation.call
    assert_equal "reused", report["status"]
    assert report["ready"]
    assert_equal %i[agent_list readiness], @calls.map(&:first)
  end

  def test_lost_prompt_acknowledgement_never_resends_on_reuse
    @lost_prompt_ack = true
    assert_raises(Ace::Overseer::Error) { operation.call }
    @existing = [@agent]
    assert_equal "reused", operation.call["status"]
    assert_equal 1, @calls.count { |method, _| method == :agent_prompt }
    assert_equal 1, @calls.count { |method, _| method == :agent_start_isolated }
  end

  def test_foreign_named_owner_is_not_reused_or_replaced
    @existing = [@agent.merge("isolated_session" => {"project" => "other", "role" => "project-overseer"})]
    assert_raises(Ace::Overseer::Error) { operation.call }
    assert_equal [:agent_list], @calls.map(&:first)
  end

  def test_wrong_runtime_or_unconfigured_root_cannot_launch
    @env["ACE_TOOLCHAIN"] = "auto"
    assert_raises(Ace::Overseer::Error) { operation.call }
    @env["ACE_TOOLCHAIN"] = "installed"
    @document["projects"] = []
    assert_raises(Ace::Overseer::Error) { operation.call }
    assert_empty @calls
  end

  def test_dry_run_does_not_discover_or_launch_sessions
    assert_equal "dry_run", operation.call(dry_run: true)["status"]
    assert_empty @calls
  end
end
