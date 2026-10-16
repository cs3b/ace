# frozen_string_literal: true
require "test_helper"
require "ace/hitl/hermes/runtime"
require "timeout"

# Real kernel-authenticated Unix boundaries. This fixture deliberately grants
# one UID both roles; it does not claim separate Captain/operator isolation.
class OperatorQuestionRoutingTest < AceHermesTestCase
  L = Ace::Hitl::Lifecycle
  def setup
    super
    @dir = Dir.mktmpdir("operator-routing", "/tmp")
    @services, @threads, @clients = {}, {}, {}
    @channels_root = File.join(@dir, "channel")
    @authorities = %w[ace nervus].to_h do |project|
      FileUtils.mkdir_p(File.join(@channels_root, "projects", project), mode: 0o750)
      start_authority(project)
      [project, {"hitl_socket" => File.join(@dir, project + ".sock"), "hitl_service_uid" => Process.uid,
        "request_contexts" => ["operator-question"]}]
    end
    registry = {"schema" => "ace.hitl.hermes.channels/v2", "channels" => [{"name" => "host",
      "machine" => "host", "folder" => @channels_root, "target" => "overseer", "chat_id" => "-424242",
      "captain_user_ids" => ["42"], "projects" => @authorities}]}
    File.write(File.join(@dir, "channels.json"), JSON.generate(registry))
    File.write(File.join(@dir, "gateway.yml"), "platforms:\n  telegram:\n    enabled: false\n")
    @config = File.join(@dir, "runtime.json")
    File.write(@config, JSON.generate("schema" => "ace.hitl.hermes.runtime/v2",
      "registry" => File.join(@dir, "channels.json"), "state" => File.join(@dir, "transport"),
      "hermes_gateway_config" => File.join(@dir, "gateway.yml"), "polling_owner" => "ace-hitl-hermes"))
    @sent = []
  end
  def teardown
    @services.each_value(&:stop)
    @threads.each_value { |thread| thread.join(3); thread.kill if thread.alive? }
    FileUtils.rm_rf(@dir)
    super
  end
  def start_authority(project)
    policy = L::GrantsPolicy.new(document: {"hitl" => {"operator_uids" => [Process.uid],
      "transport_uids" => [Process.uid]}, "authorization" => {"principals" => {
        Process.uid.to_s => {"projects" => [project]}}}})
    socket = File.join(@dir, project + ".sock")
    @services[project] = L::Service.new(root: File.join(@dir, project + "-store"),
      binding: L::OperatorOnlyBinding.new, policy: policy, socket_path: socket,
      group: Etc.getgrgid(Process.gid).name)
    @threads[project] = Thread.new { @services.fetch(project).run }
    Timeout.timeout(5) { sleep 0.01 until File.socket?(socket) || !@threads.fetch(project).alive? }
    @threads.fetch(project).value unless @threads.fetch(project).alive?
    @clients[project] = L::Client.new(socket_path: socket, service_uid: Process.uid)
  end
  def runtime
    actor = Ace::Hitl::Hermes::Runtime.new(@config)
    sent = @sent
    telegram = Object.new
    telegram.define_singleton_method(:updates) { |offset:| [] }
    telegram.define_singleton_method(:call) do |channel, question|
      sent << [channel.fetch("project"), question]
      {"success" => true, "chat_id" => channel.fetch("chat_id"), "message_id" => (99 + sent.length).to_s}
    end
    actor.define_singleton_method(:telegram) { telegram }
    actor
  end
  def create(project)
    @clients.fetch(project).operator_question(id: "same-question", project: project,
      plan: "Host operator question", question: "Choose #{project} option?")
  end
  def event(reply, answer, message)
    {"platform" => "telegram", "chat_id" => "-424242", "chat_type" => "supergroup", "user_id" => "42",
      "message_id" => message, "reply_to_message_id" => reply, "text" => answer}
  end

  def test_real_kernel_operator_questions_route_exact_replies_across_projects_and_restart
    originals = %w[ace nervus].to_h { |project| [project, create(project).fetch("envelope")] }
    originals.each do |project, envelope|
      assert_equal Process.uid, envelope.fetch("requester_uid")
      assert_equal Etc.getpwuid(Process.uid).name, envelope.fetch("requester")
      refute envelope.key?("attempt_id")
      assert_equal envelope, create(project).fetch("envelope")
    end
    actor = runtime
    actor.serve(once: true)
    assert_equal %w[ace nervus], @sent.map(&:first)
    assert_equal "ace", actor.relay.receive(event("100", "A", "201")).fetch("project")
    assert_equal "A", @clients.fetch("ace").consume("same-question", timeout: 1).fetch("answer")
    assert_equal "created", @clients.fetch("nervus").read("same-question").fetch("state")
    @services.fetch("nervus").stop
    @threads.fetch("nervus").join(3)
    start_authority("nervus")
    actor = runtime
    assert_equal "nervus", actor.relay.receive(event("101", "B", "202")).fetch("project")
    assert_equal "B", @clients.fetch("nervus").consume("same-question", timeout: 1).fetch("answer")
    assert_equal "B", @clients.fetch("nervus").consume("same-question", timeout: 1).fetch("answer")
    assert_equal originals.fetch("nervus"), create("nervus").fetch("envelope")
  end

  def test_public_api_refuses_forged_principals_effects_managed_requests_and_wrong_project
    client = @clients.fetch("ace")
    assert_raises(L::TransportError) do
      client.operator_question(id: "forged01", project: "ace", plan: "Question", question: "Choose?",
        requester_uid: 0, effect: {"argv" => ["true"]})
    end
    assert_raises(L::PermissionError) do
      client.operator_question(id: "foreign01", project: "nervus", plan: "Question", question: "Choose?")
    end
    assert_raises(L::BindingError) do
      client.create(id: "managed01", project: "ace", assignment: "assign500", attempt: "attempt500",
        plan: "fake execution", question: "Choose?", ace_hitl_id: "event001")
    end
    assert_empty client.pending(project: "ace")
  end

  def test_required_context_capability_refuses_before_polling_or_publication
    actor = runtime
    clients = actor.instance_variable_get(:@lifecycle_clients)
    route = actor.instance_variable_get(:@lifecycle_routes).fetch(["host", "ace"])
    old = Object.new
    old.define_singleton_method(:ping) { {"pong" => true} }
    clients[route] = old
    assert_raises(Ace::Hitl::Hermes::ContractError) { actor.serve(once: true) }
    assert_empty @sent
  end
end
