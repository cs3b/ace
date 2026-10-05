# frozen_string_literal: true
require "test_helper"
require "support/lifecycle_fixtures"
require "etc"
require "timeout"

class HitlWaitLabTest < AceHitlTestCase
  include LifecycleFixtures
  def setup
    super
    @scratch = Dir.mktmpdir("ace-hitl-ask")
    @root = File.join(@scratch, "store")
    @socket = File.join(@scratch, "hitl.sock")
    @failure = nil
    test = self
    @binding = TestBinding.new(reverse: {"schema" => "ace.hitl.ref/v1", "session" => "workspace1", "pane" => "pane1"},
      on_validate: ->(**) { raise test.failure if test.failure })
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {
      "hitl" => {"service_uid" => Process.uid, "transport_uids" => [Process.uid]},
      "authorization" => {"principals" => {Process.uid.to_s => {"projects" => ["ace"]}}}
    })
    @service = Ace::Hitl::Lifecycle::Service.new(root: @root, binding: @binding,
      policy: policy, socket_path: @socket, group: Etc.getgrgid(Process.gid).name)
    @thread = Thread.new { @service.run }
    Timeout.timeout(5) { sleep 0.01 until File.socket?(@socket) || !@thread.alive? }
    @thread.value unless @thread.alive?
    @client = Ace::Hitl::Lifecycle::Client.new(socket_path: @socket, service_uid: Process.uid)
    @original_client = Ace::Hitl::Providers::Lab.method(:boundary_client)
    client = @client
    Ace::Hitl::Providers::Lab.define_singleton_method(:boundary_client) { |**| client }
  end

  attr_reader :failure

  def teardown
    Ace::Hitl::Providers::Lab.define_singleton_method(:boundary_client, @original_client)
    @service&.stop
    @thread&.join(5)
    @thread&.kill
    FileUtils.remove_entry(@scratch)
    super
  end

  def test_create_attributes_requester_to_kernel_peer_pid_and_refuses_unavailable_pid
    seen = []
    original = @binding.method(:validate_request)
    @binding.define_singleton_method(:validate_request) do |**args|
      seen << args[:caller_pid]
      raise Ace::Hitl::Lifecycle::BindingError, "kernel peer PID unavailable" unless args[:caller_pid]
      original.call(**args)
    end
    @client.create(**request_args(id: "peer001"))
    assert_equal [Process.pid], seen
    @service.define_singleton_method(:peer_pid) { |_| nil }
    assert_raises(Ace::Hitl::Lifecycle::BindingError) { @client.create(**request_args(id: "peer002")) }
    refute File.exist?(File.join(@root, "requests", "peer002.json"))
  end

  def test_pane_less_wait_consumes_authenticated_request_without_native_delivery
    @client.create(**request_args(id: "wait001"))
    @client.deliver("wait001", "approved")
    result = run_cli(["wait", "--request", "wait001", "--timeout", "1"])
    assert_equal 0, result[:exit_code], result[:stderr]
    value = JSON.parse(result[:stdout])
    assert_equal "approved", value["answer"]
    refute_equal true, value["native_delivery"]
    assert_equal "consumed", @client.read("wait001")["state"]
  end

  def test_managed_event_wait_ignores_forged_local_answer_and_public_folder
    @client.create(**request_args(id: "wait002"))
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "8ppq7w", slug: "managed", status: "pending",
        extra_frontmatter: {"lab_request_id" => "wait002"})
      with_cli_root(root) do
        result = run_cli(["wait", "8ppq7w", "--timeout", "1"])
        assert_equal 1, result[:exit_code]
        assert_match(/timed out|timeout/i, result[:stderr])
        assert_equal "created", @client.read("wait002")["state"]
        @client.deliver("wait002", "scoped answer")
        result = run_cli(["wait", "8ppq7w", "--timeout", "1"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_equal "scoped answer", JSON.parse(result[:stdout])["answer"]
        event = Ace::Hitl::Organisms::HitlManager.new(root_dir: root).show("8ppq7w")[:event]
        assert_empty event.answer.to_s
      end
    end
  end

  def test_missing_request_and_ambiguous_reference_do_not_fall_back
    result = run_cli(["wait", "--request", "absent", "--timeout", "1"])
    assert_equal 1, result[:exit_code]
    result = run_cli(["wait", "8ppq7w", "--request", "wait003"])
    assert_equal 1, result[:exit_code]
    assert_match(/not both/, result[:stderr])
  end

  def test_local_manager_refuses_managed_wait_and_unscoped_resume
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "8ppq7w", slug: "managed", status: "pending",
        extra_frontmatter: {"lab_request_id" => "wait004"})
      with_cli_root(root) do
        manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
        assert_raises(Ace::Hitl::Lifecycle::StateError) { manager.wait_for_answer("8ppq7w") }
        assert_equal :managed_request, manager.dispatch_resume("8ppq7w")[:status]
      end
    end
  end
end
