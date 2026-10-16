# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "etc"
require "ace/overseer/organisms/ordinary_work_on"
require "ace/test_support/config_helpers"

class OrdinaryWorkOnTest < AceOverseerTestCase
  include Ace::TestSupport::ConfigHelpers
  Files = Ace::Assign::Authority::RetainedInput

  class Runtime
    attr_reader :sent
    attr_accessor :lose, :pane
    def initialize
      @sent, @count, @pane = [], 0, "w1:pS"
    end
    def context = {in_runtime: true, session: "w1", window: "w1:t1", pane: @pane}
    def process_binding(pane:, caller_pid:) = {"pane" => pane, "native_identity" => "test-boundary"}
    def prepare_pane(window:)
      @count += 1
      "w1:p#{@count}"
    end
    def send_command(pane:, command:)
      @sent << [pane, command]
      raise Ace::Runtime::RuntimeUnavailableError, "injected lost send reply" if @lose
      true
    end
  end

  def setup
    super
    @root = Dir.mktmpdir("ordinary-entry-", File.realpath(Etc.getpwuid(Process.uid).dir))
    File.chmod(0o700, @root)
    @worktrees = File.join(@root, "worktrees")
    Dir.mkdir(@worktrees, 0700)
    @runtime = Runtime.new
    @config = Object.new
    root = @worktrees
    @config.define_singleton_method(:project) { "atlas" }
    @config.define_singleton_method(:verify_owner!) { true }
    @config.define_singleton_method(:worktrees) { {"root" => root, "common_dir" => "/selected/common"} }
    @config.define_singleton_method(:selected_principal!) { |_| {"workspace" => "w1", "supervisor_panes" => ["w1:pS"]} }
    @provisioner = Object.new
    @provisioner.define_singleton_method(:provision) do |task|
      raise "wrong source project" unless Dir.pwd == File.dirname(root) && ENV["PROJECT_ROOT_PATH"] == Dir.pwd
      path = File.join(root, task)
      Dir.mkdir(path, 0700) unless File.directory?(path)
      {worktree_path: path, created: true}
    end
    @windows = Object.new
    @windows.define_singleton_method(:open) { |worktree_path:| File.basename(worktree_path) }
    @prepare = lambda do |project:, task:, pane:, output:|
      Files.create_output(output)
      Files.write_file(output, "request.json", JSON.generate({"operation" => "register_assignment",
        "project_id" => project, "params" => {"assignment_id" => "assign-#{task}", "pane" => pane}}))
      {"assignment_id" => "assign-#{task}", "scope" => "010.01", "request" => File.join(output, "request.json")}
    end
    @client = Object.new
    @client.define_singleton_method(:request) do |input:, **_|
      value = Files.json(input)
      {"data" => value.fetch("params").merge("project_id" => value.fetch("project_id"), "state" => "not_started",
        "generation" => 0, "submitted_result" => nil, "binding" => {"pane" => "w1:pS", "native_identity" => "test-boundary"})}
    end
    @head = "a" * 40
    @observer = Object.new
    owner = self
    @observer.define_singleton_method(:observe) { |cwd| {"head" => owner.instance_variable_get(:@head), "cwd" => cwd} }
    @builder = Object.new
    @builder.define_singleton_method(:build) do |provider_model:, prompt:, working_dir:, subprocess_env: nil|
      raise "wrong provider project" unless Dir.pwd == working_dir && ENV["PROJECT_ROOT_PATH"] == working_dir
      {command: ["pi", "--provider", "zai", "--model", "glm-5.3-flash", "--thinking", "high", prompt],
        env: subprocess_env, working_dir: working_dir, prompt: prompt, provider: "pi", model: "zai/glm-5.3-flash", thinking_level: "high"}
    end
  end

  def teardown
    FileUtils.remove_entry(@root)
    super
  end

  def entry
    Ace::Overseer::Organisms::OrdinaryWorkOn.new(config: @config, runtime: @runtime, provisioner: @provisioner,
      windows: @windows, builder: @builder, client: @client, prepare: @prepare, observer: @observer)
  end

  def prepare(task = "one")
    entry.prepare(project: "atlas", task: task, checkout: @root, output: File.join(@root, task), provider: "pi:zai/glm-5.3-flash:high")
  end

  def test_two_fresh_workers_retain_independent_identity_cwd_and_explicit_native_watches
    one, two = prepare("one"), prepare("two")
    refute_equal one.fetch("attempt_id"), two.fetch("attempt_id")
    refute_equal one.fetch("pane"), two.fetch("pane")
    refute_equal one.fetch("cwd"), two.fetch("cwd")
    assert_match %r{/watch add ordinary-.* --path }, one.fetch("watch_command")
    assert File.file?(File.join(File.dirname(one.fetch("context")), "result-hint.json"))
    [one, two].each do |selection|
      result = entry.launch(project: "atlas", context: selection.fetch("context"))
      assert_equal "accepted_not_started", result.fetch("state")
      assert_equal "not_started", result.dig("canonical", "state")
      assert_equal "not_started", entry.resume(project: "atlas", context: selection.fetch("context")).dig("canonical", "state")
    end
    assert_equal 2, @runtime.sent.size
    assert_includes @runtime.sent.first.last, "ACE_ASSIGN_ORDINARY_CONTEXT"
    assert_includes @runtime.sent.first.last, "glm-5.3-flash"
    assert_includes @runtime.sent.first.last, "high"
  end

  def test_lost_native_send_reply_retains_intent_and_resume_never_dispatches_again
    prepared = prepare
    @runtime.lose = true
    assert_raises(Ace::Assign::Error) { entry.launch(project: "atlas", context: prepared.fetch("context")) }
    assert_equal 1, @runtime.sent.size
    assert_equal "dispatch_uncertain", entry.launch(project: "atlas", context: prepared.fetch("context")).fetch("state")
    2.times { entry.resume(project: "atlas", context: prepared.fetch("context")) }
    assert_equal 1, @runtime.sent.size
  end

  def test_moved_checkout_or_wrong_supervisor_or_project_refuses_before_dispatch
    prepared = prepare
    @head = "b" * 40
    assert_raises(Ace::Overseer::Error) { entry.launch(project: "atlas", context: prepared.fetch("context")) }
    @head = "a" * 40
    @runtime.pane = "w1:p9"
    assert_raises(Ace::Overseer::Error) { entry.launch(project: "atlas", context: prepared.fetch("context")) }
    assert_raises(ArgumentError) { entry.resume(project: "foreign", context: prepared.fetch("context")) }
    assert_empty @runtime.sent
  end

  def test_real_provider_builder_keeps_exact_pi_model_and_thinking_in_dispatch
    with_real_config do
      @builder = nil
      prepared = prepare
      result = entry.launch(project: "atlas", context: prepared.fetch("context"))
      assert_equal "accepted_not_started", result.fetch("state")
      command = @runtime.sent.fetch(0).last
      assert_includes command, "glm-5.3-flash"
      assert_includes command, "--thinking"
      assert_includes command, "high"
      assert_includes command, prepared.fetch("cwd")
      assert_includes command, "--ordinary"
      assert_includes command, prepared.fetch("context")
    end
  end
end
