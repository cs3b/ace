# frozen_string_literal: true
require "test_helper"
require "ace/hitl/hermes/runtime"
require "timeout"

class ManagedPendingPublicationTest < AceHermesTestCase
  L = Ace::Hitl::Lifecycle
  T = Ace::Hitl::Hermes::Transport
  class Binding < L::Binding
    def validate_request(**); nil; end
    def with_active(**); yield; end
  end
  class Policy
    def transport?(peer, project: nil)
      peer.uid == Process.uid && (project.nil? || project == "ace")
    end
    def service_uid; end
  end
  def setup
    super
    @tmp = Dir.mktmpdir("hermes-cli", "/tmp")
    @folder = File.join(@tmp, "inbox")
    FileUtils.mkdir_p(@folder, mode: 0o750)
    @socket = File.join(@tmp, "hitl.sock")
    @service = L::Service.new(root: File.join(@tmp, "store"), binding: Binding.new, policy: Policy.new,
      socket_path: @socket, group: Etc.getgrgid(Process.gid).name)
    @thread = Thread.new { @service.run }
    Timeout.timeout(5) { sleep 0.01 until File.socket?(@socket) || !@thread.alive? }
    @thread.value unless @thread.alive?
    @client = L::Client.new(socket_path: @socket, service_uid: Process.uid)
    @registry_path = File.join(@tmp, "channels.json")
    @config_path = File.join(@tmp, "runtime.json")
    registry = {"schema" => "ace.hitl.hermes.channels/v1", "channels" => [
      {"name" => "inbox", "machine" => "local", "folder" => @folder, "target" => "overseer", "projects" => ["ace"],
       "chat_id" => "-424242", "captain_user_ids" => ["42"]}
    ]}
    @gateway_path = File.join(@tmp, "hermes.yaml")
    File.write(@gateway_path, "platforms:\n  telegram:\n    enabled: false\n")
    @config = {"schema" => "ace.hitl.hermes.runtime/v1", "registry" => @registry_path,
               "state" => File.join(@tmp, "state"), "hitl_socket" => @socket, "hitl_service_uid" => Process.uid,
               "hermes_gateway_config" => @gateway_path, "polling_owner" => "ace-hitl-hermes"}
    File.write(@registry_path, JSON.generate(registry))
    File.write(@config_path, JSON.generate(@config))
    @registry = T::Registry.load(@registry_path)
    @journal = T::Journal.new(@config["state"])
    @relay = T::Relay.new(registry: @registry, journal: @journal, lifecycle: @client,
      sender: ->(channel, _) { {"success" => true, "chat_id" => channel["chat_id"], "message_id" => "100"} })
  end

  def teardown
    @service&.stop
    @thread&.join(5)
    @thread&.kill
    FileUtils.remove_entry(@tmp)
    super
  end

  def create(id:, project: "ace")
    @client.create(id: id, assignment: "assign685", attempt: "attempt685", kind: "text",
      project: project, harness: "agy", plan: "test", question: "Proceed?", ace_hitl_id: "event1")
  end

  def runtime
    calls = []
    transport = Object.new
    transport.define_singleton_method(:updates) { |offset:| calls << [:poll, offset]; [] }
    transport.define_singleton_method(:call) do |channel, question|
      calls << [:send, channel["name"], question]
      {"success" => true, "chat_id" => channel["chat_id"], "message_id" => "100"}
    end
    runtime = Ace::Hitl::Hermes::Runtime.new(@config_path)
    runtime.define_singleton_method(:telegram) { transport }
    [runtime, calls]
  end

  def test_scoped_request_without_manual_post_is_published_and_sent_by_single_owner
    create(id: "auto001")
    assert_empty Dir.children(@folder)
    actor, calls = runtime
    actor.serve(once: true)
    assert_equal %i[poll send poll], calls.map(&:first)
    assert_equal [:send, "inbox", "Proceed?"], calls.find { |v| v.first == :send }
    assert_equal "submitted", actor.relay.delivery("auto001")["status"]
    assert_empty Dir.children(@folder) # Telegram question ACK removes message.v1.
    actor.serve(once: true)
    assert_equal 1, calls.count { |value| value.first == :send }
    assert actor.relay.reconcile(request: "auto001", through: actor.relay.delivery("auto001")["submitted_at"])["healthy"]
  end

  def test_unregistered_project_is_left_pending_and_never_routed
    create(id: "other001", project: "other")
    actor, calls = runtime
    actor.serve(once: true)
    assert_empty calls.select { |value| value.first == :send }
    assert_empty Dir.children(@folder)
    assert_equal "created", @client.read("other001")["state"]
  end

  def test_folder_collision_refuses_without_overwriting_or_sending
    create(id: "auto001")
    original = question_payload(id: "auto001", question: "Different body")
    message_file(@folder, "auto001", original)
    actor, calls = runtime
    assert_raises(Ace::Hitl::Hermes::ContractError) { actor.serve(once: true) }
    assert_equal original, JSON.parse(File.read(File.join(@folder, "auto001.json")))
    assert_empty calls.select { |value| value.first == :send }
  end
  # Test-only control flow bypasses the poller's intentional error wrapping.
  StopLoop = Class.new(Exception)

  def test_continuous_publication_retries_transport_outage_and_retains_one_poll_owner
    create(id: "auto001")
    actor, calls = runtime
    lifecycle = actor.instance_variable_get(:@lifecycle)
    original_pending = lifecycle.method(:pending)
    attempts = 0
    lifecycle.define_singleton_method(:pending) do |**args|
      attempts += 1
      raise L::TransportError, "HITL service restarting" if attempts == 1
      original_pending.call(**args)
    end
    transport = actor.send(:telegram)
    polls = 0
    transport.define_singleton_method(:updates) do |offset:|
      polls += 1
      raise StopLoop if polls > 2
      calls << [:poll, offset]
      []
    end
    delays = []
    actor.define_singleton_method(:sleep) { |seconds| delays << seconds }
    _, errors = capture_io { assert_raises(StopLoop) { actor.serve(once: false) } }
    assert_match(/pending publication unavailable/, errors)
    assert_equal [1], delays
    assert_equal 2, attempts
    assert_equal 1, calls.count { |entry| entry.first == :send }
    assert_equal "submitted", actor.relay.delivery("auto001")["status"]
  end

  def test_once_publication_reports_transport_failure_without_consuming_request
    create(id: "auto001")
    actor, calls = runtime
    lifecycle = actor.instance_variable_get(:@lifecycle)
    lifecycle.define_singleton_method(:pending) { |**| raise L::TransportError, "HITL service restarting" }
    assert_raises(L::TransportError) { actor.serve(once: true) }
    assert_equal "created", @client.read("auto001")["state"]
    assert_empty calls.select { |entry| entry.first == :send }
    assert_empty Dir.children(@folder)
  end

end
