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
    @root_folder = File.join(@tmp, "inbox")
    @folder = File.join(@root_folder, "projects", "ace")
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
    registry = {"schema" => "ace.hitl.hermes.channels/v2", "channels" => [
      {"name" => "inbox", "machine" => "local", "folder" => @root_folder, "target" => "overseer", "projects" => {"ace" => {"hitl_socket" => @socket, "hitl_service_uid" => Process.uid}},
       "chat_id" => "-424242", "captain_user_ids" => ["42"]}
    ]}
    @gateway_path = File.join(@tmp, "hermes.yaml")
    File.write(@gateway_path, "platforms:\n  telegram:\n    enabled: false\n")
    @config = {"schema" => "ace.hitl.hermes.runtime/v2", "registry" => @registry_path,
               "state" => File.join(@tmp, "state"),
               "hermes_gateway_config" => @gateway_path, "polling_owner" => "ace-hitl-hermes"}
    File.write(@registry_path, JSON.generate(registry))
    File.write(@config_path, JSON.generate(@config))
    @registry = T::Registry.load(@registry_path)
    @journal = T::Journal.new(@config["state"])
    @relay = T::Relay.new(registry: @registry, journal: @journal, lifecycle_for: ->(_, _project) { @client },
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
    assert_equal "submitted", actor.relay.delivery(channel: "inbox", project: "ace", request: "auto001")["status"]
    assert_empty Dir.children(@folder) # Telegram question ACK removes message.v1.
    actor.serve(once: true)
    assert_equal 1, calls.count { |value| value.first == :send }
    submitted_at = actor.relay.delivery(channel: "inbox", project: "ace", request: "auto001")["submitted_at"]
    assert actor.relay.reconcile(channel: "inbox", project: "ace", request: "auto001", through: submitted_at)["healthy"]
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
    lifecycle = actor.send(:lifecycle_for, "inbox", "ace")
    original_pending = lifecycle.method(:pending)
    attempts = 0
    lifecycle.define_singleton_method(:pending) do |**args|
      attempts += 1
      # Attempt 1 is the activation health probe; the outage hits the
      # serve loop, which retries after the configured delay.
      raise L::TransportError, "HITL service restarting" if attempts == 2
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
    assert_equal 3, attempts
    assert_equal 1, calls.count { |entry| entry.first == :send }
    assert_equal "submitted", actor.relay.delivery(channel: "inbox", project: "ace", request: "auto001")["status"]
  end

  def test_once_publication_reports_transport_failure_without_consuming_request
    create(id: "auto001")
    actor, calls = runtime
    lifecycle = actor.send(:lifecycle_for, "inbox", "ace")
    original_pending = lifecycle.method(:pending)
    attempts = 0
    lifecycle.define_singleton_method(:pending) do |**args|
      attempts += 1
      # Activation (attempt 1) passes; the first loop publication fails
      # and once-mode propagates it without consuming the request.
      raise L::TransportError, "HITL service restarting" if attempts > 1

      original_pending.call(**args)
    end
    assert_raises(L::TransportError) { actor.serve(once: true) }
    assert_equal "created", @client.read("auto001")["state"]
    assert_empty calls.select { |entry| entry.first == :send }
    assert_empty Dir.children(@folder)
  end

  def test_requester_named_captain_still_reaches_telegram
    create(id: "auto001")
    actor, calls = runtime
    lifecycle = actor.send(:lifecycle_for, "inbox", "ace")
    original_pending = lifecycle.method(:pending)
    original_read = lifecycle.method(:read)
    lifecycle.define_singleton_method(:pending) do |**args|
      original_pending.call(**args).each do |facts|
        facts["requester"] = "captain"
        facts["envelope"]["requester"] = "captain"
      end
    end
    lifecycle.define_singleton_method(:read) do |id|
      facts = original_read.call(id)
      facts["requester"] = "captain"
      facts["envelope"]["requester"] = "captain"
      facts
    end
    actor.serve(once: true)
    assert_equal 1, calls.count { |entry| entry.first == :send },
      "authenticated request must not be mistaken for a Captain instruction"
  end
  def test_unmanaged_captain_instruction_is_left_for_target
    original = question_payload(id: "instruction1", sender: "captain", question: "Inspect status")
    message_file(@folder, "instruction1", original)
    actor, calls = runtime
    actor.serve(once: true)
    assert_empty calls.select { |entry| entry.first == :send }
    assert_equal original, JSON.parse(File.read(File.join(@folder, "instruction1.json")))
  end

  def test_registration_surfaces_durable_unregistered_chat_coverage_gap_once
    @journal.record_unregistered(
      updates: [{"chat_id" => "-424242", "update_id" => 17}], observed_at: QUESTION_TS
    )

    actor = Ace::Hitl::Hermes::Runtime.new(@config_path, clock: -> { Time.iso8601(ANSWER_TS) })
    transport = Object.new
    transport.define_singleton_method(:updates) { |offset:| [] }
    actor.define_singleton_method(:telegram) { transport }
    _, warning = capture_io { actor.serve(once: true) }
    assert_match(/registered inbox \(chat -424242\) after 1 skipped Telegram updates \(17-17\)/, warning)
    assert_match(/ingress coverage starts generation 1/, warning)
    @journal.synchronize do |state, _|
      record = state["unregistered_chats"]["-424242"]
      assert_equal "inbox", record["registered_channel"]
      assert_equal 17, record["surfaced_through_update_id"]
      assert_equal 1, state["poll"]["inbox"]["generation"]
    end

    repeated = Ace::Hitl::Hermes::Runtime.new(@config_path)
    repeated.define_singleton_method(:telegram) { transport }
    _, repeated_warning = capture_io { repeated.serve(once: true) }
    refute_match(/registered inbox .* after .* skipped Telegram updates/, repeated_warning)
    assert actor
  end

  def test_existing_transport_v1_journal_is_preserved_and_refused
    directory = File.join(@tmp, "existing-state")
    FileUtils.mkdir_p(directory, mode: 0o700)
    path = File.join(directory, "journal.json")
    retained = {"request" => "retained", "channel" => "inbox", "status" => "submitted"}
    existing = {"schema" => "ace.hitl.hermes.transport/v1", "requests" => {"retained" => retained},
                "ingress" => [], "sequence" => 7, "poll" => {}}
    File.write(path, JSON.generate(existing))
    File.chmod(0o600, path)
    journal = T::Journal.new(directory)

    bytes = File.read(path)
    assert_raises(Ace::Hitl::Hermes::ContractError) do
      journal.record_unregistered(updates: [{"chat_id" => "-999999", "update_id" => 9}], observed_at: QUESTION_TS)
    end
    assert_equal bytes, File.read(path)
  end

end
