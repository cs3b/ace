# frozen_string_literal: true

require_relative "../../test_helper"

class TelegramTransportTest < AceHermesTestCase
  T = Ace::Hitl::Hermes::Transport

  class Boundary
    attr_reader :answers, :effects
    attr_accessor :unavailable

    def initialize
      @requests, @answers, @effects = {}, [], 0
    end

    def add(id, secret: false)
      @requests[id] = {"id" => id, "attempt" => "attempt651", "assignment" => "assign651", "project" => "lab",
                       "requester" => "agent", "kind" => secret ? "otp" : "text",
                       "sensitive" => secret, "question" => "Proceed?", "state" => "created"}
      envelope = {"schema" => Ace::Hitl::Contract::ManagedEnvelope::SCHEMA, "request_id" => id,
        "request_incarnation" => "0123456789abcdef",
        "project" => "lab", "assignment_id" => "assign651", "attempt_id" => "attempt651", "requester" => "agent",
        "correlation_id" => id, "kind" => secret ? "otp" : "text", "reverse" => nil}
      envelope["payload_sha256"] = Digest::SHA256.hexdigest("Proceed?") unless secret
      @requests[id]["envelope"] = envelope
    end

    def read(id)
      raise "unavailable" if @unavailable
      @requests.fetch(id).dup
    end

    def deliver(id, answer)
      raise "unavailable #{answer}" if @unavailable
      return if @requests.fetch(id)["state"] != "created"
      @answers << [id, answer.dup]
      @effects += 1
      @requests[id]["state"] = "answer-delivered"
    end

    def close(id)
      @requests.fetch(id)["state"] = "consumed"
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("hermes-transport")
    @folders = %w[lab other].to_h do |name|
      folder = File.join(@tmp, name)
      FileUtils.mkdir_p(folder, mode: 0o750)
      [name, folder]
    end
    channels = @folders.map do |name, folder|
      {"name" => name, "chat_id" => name == "lab" ? "-424242" : "-848484",
       "captain_user_ids" => ["42"], "machine" => "host", "folder" => folder, "target" => "#{name}-overseer", "projects" => [name]}
    end
    @registry = T::Registry.new({"schema" => "ace.hitl.hermes.channels/v1", "channels" => channels})
    @journal = T::Journal.new(File.join(@tmp, "state"))
    @boundary = Boundary.new
    @time = Time.iso8601(QUESTION_TS)
    @sent = []
    @sender = lambda do |channel, question|
      @sent << [channel["name"], question]
      {"success" => true, "chat_id" => channel["chat_id"], "message_id" => "100"}
    end
    @relay = relay
  end

  def teardown
    FileUtils.remove_entry(@tmp)
    super
  end

  def box(channel = "lab", authorized: true)
    entry = @registry.resolve(channel)
    ch = Ace::Hitl::Hermes::Molecules::HermesChannels::Channel.new(
      name: entry["name"], machine: entry["machine"], folder: entry["folder"]
    )
    Ace::Hitl::Hermes::Organisms::HermesBox.new(channel: ch, euid_provider: -> { 4242 },
      answer_authorizer: authorized ? ->(id) { @boundary.read(id) } : nil)
  end

  def relay(sender: @sender)
    T::Relay.new(registry: @registry, journal: @journal, lifecycle: @boundary, sender: sender,
      clock: -> { @time }, box_factory: ->(channel) { box(channel["name"]) })
  end

  def submit(id = "q-1", secret: false, channel: "lab")
    @boundary.add(id, secret: secret)
    box(channel).publish(kind: :question, id: id, body: "Proceed?", sender: "agent", timestamp: QUESTION_TS)
    @relay.submit(channel: channel, request: id, revision: "rev-1")
  end

  def event(text = "yes", **changes)
    {"platform" => "telegram", "chat_id" => "-424242", "chat_type" => "supergroup", "user_id" => "42",
     "message_id" => "101", "reply_to_message_id" => "100", "text" => text}.merge(changes.transform_keys(&:to_s))
  end

  def test_submission_ack_is_not_a_read_receipt_and_retries_do_not_resend
    ack = submit
    assert_equal "submitted", ack["status"]
    assert_equal "100", ack["message_id"]
    assert_equal QUESTION_TS, ack["submitted_at"]
    assert_nil ack["read_at"]
    @relay.submit(channel: "lab", request: "q-1", revision: "rev-1")
    assert_equal 1, @sent.size
    assert_empty box.poll.messages
  end

  def test_same_channel_reply_delivers_folder_answer_and_only_one_effect
    submit
    result = @relay.receive(event)
    assert_equal "delivered", result["status"]
    assert_equal [["q-1", "yes"]], @boundary.answers
    assert_equal "yes", box.poll.messages.first.body
    assert_equal result, @relay.receive(event)
    @relay.receive(event("no", message_id: "102"))
    assert_equal 1, @boundary.effects
  end

  def test_unauthorized_cross_channel_unknown_and_malformed_reply_fail_closed
    submit
    [event(user_id: "99"), event(chat_id: "-848484"), event(reply_to_message_id: "999"),
     event("/hitl-reply"), event("\0"), event(platform: "discord")].each do |input|
      assert_raises(Ace::Hitl::Hermes::ContractError) { @relay.receive(input) }
    end
    assert_empty @boundary.answers
  end

  def test_command_is_scoped_and_explicit_id_does_not_override_reply_identity
    submit
    assert_raises(Ace::Hitl::Hermes::ContractError) do
      @relay.receive(event("/hitl-reply q-1 no", reply_to_message_id: "999"))
    end
    assert_equal "delivered", @relay.receive(event("/hitl-reply@bot q-1 yes", reply_to_message_id: ""))["status"]
    assert_equal [["q-1", "yes"]], @boundary.answers
  end

  def test_plain_message_is_instruction_while_request_remains_pending
    submit
    result = @relay.receive(event("new instruction", reply_to_message_id: ""))
    assert_equal "lab-overseer", result["target"]
    message = box.poll.messages.first
    assert message.question?
    assert_equal "captain", message.sender
    assert_empty @boundary.answers
  end

  def test_failed_submit_is_recoverable_and_has_no_clock
    @relay = relay(sender: ->(*) { raise T::SubmitFailed, "refused" })
    result = submit
    assert_equal "failed", result["status"]
    assert_nil result["submitted_at"]
    assert box.poll.messages.first.question?
    @relay = relay
    assert_equal "submitted", @relay.submit(channel: "lab", request: "q-1", revision: "rev-1")["status"]
  end

  def test_uncertain_submit_never_resends_or_starts_clock
    @relay = relay(sender: ->(*) { raise "lost response" })
    result = submit
    assert_equal "uncertain", result["status"]
    assert_nil result["submitted_at"]
    @relay = relay
    assert_equal "uncertain", @relay.submit(channel: "lab", request: "q-1", revision: "rev-1")["status"]
    assert_empty @sent
  end

  def test_wrong_submission_destination_is_uncertain
    @relay = relay(sender: ->(*) { {"success" => true, "chat_id" => "-999999", "message_id" => "1"} })
    assert_equal "uncertain", submit["status"]
  end

  def test_request_binding_and_revision_cannot_be_reassigned
    submit
    assert_raises(Ace::Hitl::Hermes::ContractError) do
      @relay.submit(channel: "lab", request: "q-1", revision: "rev-2")
    end
  end

  def test_otp_bypasses_answer_folder_and_never_enters_journal_or_projection
    submit(secret: true)
    surrogate = "987654"
    result = @relay.receive(event(surrogate))
    assert_equal "delivered", result["status"]
    assert_equal [["q-1", surrogate]], @boundary.answers
    assert_empty box.poll.messages
    assert_no_secret(surrogate, result)
  end

  def test_otp_unavailable_discards_secret_and_requires_fresh_challenge
    submit(secret: true)
    @boundary.unavailable = true
    result = @relay.receive(event("987654"))
    assert_equal "secret-unavailable", result["status"]
    assert_empty box.poll.messages
    @boundary.unavailable = false
    @relay.receive(event("987654"))
    assert_empty @boundary.answers
    assert_no_secret("987654", result)
  end

  def test_low_level_answer_gate_rejects_otp_and_missing_authority_before_creation
    @boundary.add("otp-1", secret: true)
    [box, box(authorized: false)].each do |target|
      assert_raises(Ace::Hitl::Hermes::ContractError) do
        target.publish(kind: :answer, id: "otp-1", body: "987654", sender: "captain", timestamp: ANSWER_TS)
      end
    end
    assert_empty Dir.children(@folders["lab"])
  end

  def test_late_reply_after_transport_restart_uses_authoritative_history
    submit
    @boundary.close("q-1")
    @relay = relay
    assert_equal "closed", @relay.receive(event)["status"]
    assert_empty @boundary.answers
  end

  def test_reconciliation_requires_real_coverage_and_excludes_untrusted_event_timestamp
    submit
    assert_equal "unknown", @relay.reconcile(request: "q-1", through: QUESTION_TS)["status"]
    @time += 60
    result = @relay.receive(event("yes", received_at: "2000-01-01T00:00:00Z"))
    assert_equal @time.iso8601, result["received_at"]
    @relay.poll_complete(channel: "lab", started_at: QUESTION_TS, through: @time.iso8601, continuous: true)
    checkpoint = @relay.reconcile(request: "q-1", through: @time.iso8601)
    assert checkpoint["healthy"]
    assert checkpoint["drained"]
    assert_equal 1, checkpoint["checkpoint"]["sequence"]
  end

  def test_queued_ingress_and_poll_gap_cannot_claim_drained
    submit
    @time += 60
    @journal.synchronize do |state, commit|
      state["ingress"] << {"request" => "q-1", "revision" => "rev-1", "channel" => "lab",
                            "sequence" => 1, "received_at" => @time.iso8601, "status" => "queued"}
      commit.call
    end
    @relay.poll_complete(channel: "lab", started_at: QUESTION_TS, through: @time.iso8601, continuous: true)
    result = @relay.reconcile(request: "q-1", through: @time.iso8601)
    refute result["drained"]
    assert_equal "queued", result["unresolved"].first["status"]
    @time += 60
    @relay.poll_complete(channel: "lab", started_at: @time.iso8601, through: @time.iso8601, continuous: true)
    refute @relay.reconcile(request: "q-1", through: @time.iso8601)["healthy"]
  end

  def test_registry_rejects_ambiguous_chat_and_missing_allowlist
    values = @registry.channels.map(&:dup)
    values[1]["chat_id"] = values[0]["chat_id"]
    assert_raises(Ace::Hitl::Hermes::ContractError) { T::Registry.new({"schema" => "ace.hitl.hermes.channels/v1", "channels" => values}) }
    values[1]["chat_id"] = "-848484"
    values[1]["captain_user_ids"] = []
    assert_raises(Ace::Hitl::Hermes::ContractError) { T::Registry.new({"schema" => "ace.hitl.hermes.channels/v1", "channels" => values}) }
  end

  def test_poller_produces_checkpoint_only_after_empty_batch_and_persisted_offset
    submit
    update = {"update_id" => 8, "message" => {"message_id" => 101, "chat" => {"id" => -424242, "type" => "supergroup"},
              "from" => {"id" => 42}, "reply_to_message" => {"message_id" => 100}, "text" => "yes"}}
    source = Object.new
    offsets = []
    batches = [[update], []]
    source.define_singleton_method(:updates) { |offset:| offsets << offset; batches.shift }
    poller = T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry, clock: -> { @time })
    assert_equal 1, poller.once
    refute @relay.reconcile(request: "q-1", through: QUESTION_TS)["healthy"]
    assert_equal 0, poller.once
    assert @relay.reconcile(request: "q-1", through: QUESTION_TS)["drained"]
    assert_equal [0, 9], offsets
  end

  def test_poller_failure_invalidates_checkpoint_and_actor_lease_excludes_competitor
    submit
    source = Object.new
    source.define_singleton_method(:updates) { |offset:| raise "failure" }
    poller = T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry, clock: -> { @time })
    assert_raises(Ace::Hitl::Hermes::ContractError) { poller.once }
    refute @relay.reconcile(request: "q-1", through: QUESTION_TS)["healthy"]
    @journal.actor do
      assert_raises(Ace::Hitl::Hermes::ContractError) { T::Journal.new(File.join(@tmp, "state")).actor {} }
    end
  end

  def test_replayed_ordinary_ingress_recovers_without_a_second_effect
    submit
    @boundary.unavailable = true
    first = @relay.receive(event)
    assert_equal "unresolved", first["status"]
    @boundary.unavailable = false
    @relay = relay
    replay = @relay.receive(event)
    assert_equal "delivered", replay["status"]
    assert_equal first["sequence"], replay["sequence"]
    assert_equal first["received_at"], replay["received_at"]
    assert_equal 1, @boundary.effects
  end

  def test_replayed_crash_after_folder_write_reuses_original_answer
    submit
    box.publish(kind: :answer, id: "q-1", body: "first answer", sender: "captain", timestamp: ANSWER_TS)
    @journal.synchronize do |state, commit|
      state["sequence"] = 1
      state["ingress"] << {"request" => "q-1", "revision" => "rev-1", "channel" => "lab",
        "message_id" => "101", "sequence" => 1, "received_at" => QUESTION_TS, "status" => "queued"}
      commit.call
    end
    assert_equal "delivered", @relay.receive(event("replacement"))["status"]
    assert_equal [["q-1", "first answer"]], @boundary.answers
    assert_equal "first answer", box.poll.messages.first.body
  end

  def test_poll_does_not_confirm_unresolved_ordinary_reply
    submit
    @boundary.unavailable = true
    update = {"update_id" => 8, "message" => {"message_id" => 101, "chat" => {"id" => -424242, "type" => "supergroup"},
      "from" => {"id" => 42}, "reply_to_message" => {"message_id" => 100}, "text" => "yes"}}
    source = Object.new
    offsets = []
    source.define_singleton_method(:updates) { |offset:| offsets << offset; [update] }
    poller = T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry, clock: -> { @time })
    poller.once
    @boundary.unavailable = false
    poller.once
    assert_equal [0, 0], offsets
    assert_equal 1, @boundary.effects
  end

  def test_retention_lapse_and_secret_unavailable_prevent_timeout_drainage
    submit(secret: true)
    @boundary.unavailable = true
    @relay.receive(event("987654"))
    @time += 60
    @relay.poll_complete(channel: "lab", started_at: QUESTION_TS, through: @time.iso8601, continuous: true)
    refute @relay.reconcile(request: "q-1", through: @time.iso8601)["drained"]
    @journal.synchronize do |state, commit|
      state["cursor"] = {"offset" => 0, "through" => QUESTION_TS, "coverage_from" => QUESTION_TS, "generation" => 0}
      commit.call
    end
    @time += 24 * 60 * 60
    source = Object.new
    source.define_singleton_method(:updates) { |offset:| [] }
    T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry,
      clock: -> { @time }).once
    refute @relay.reconcile(request: "q-1", through: @time.iso8601)["healthy"]
  end

  def test_timeout_checkpoint_serializes_with_reply_durable_receipt_and_delivery
    submit
    @relay.poll_complete(channel: "lab", started_at: QUESTION_TS, through: QUESTION_TS, continuous: true)
    arrived, release, checking = Queue.new, Queue.new, Queue.new
    original = @boundary.method(:deliver)
    @boundary.define_singleton_method(:deliver) do |id, answer|
      arrived << true
      release.pop
      original.call(id, answer)
    end
    reply = Thread.new { @relay.receive(event) }
    arrived.pop
    checkpoint = Thread.new do
      checking << true
      @relay.reconcile(request: "q-1", through: QUESTION_TS)
    end
    checking.pop
    assert checkpoint.alive?, "checkpoint escaped a pending reply transition"
    release << true
    reply.value
    result = checkpoint.value
    assert result["drained"]
    assert_equal 1, result["checkpoint"]["sequence"]
    assert_equal 1, @boundary.effects
  ensure
    release << true if release && reply&.alive?
    reply&.join(1)
    checkpoint&.join(1)
  end

  def test_nonempty_batch_after_retention_gap_does_not_restore_old_coverage
    submit
    source = Object.new
    unrelated_update = {'update_id' => 8, 'message' => {'message_id' => 123, 'date' => @time.to_i, 'chat' => {'id' => -999999, 'type' => 'supergroup'}, 'from' => {'id' => 99}, 'text' => 'unrelated'}}
    batches = [[], [unrelated_update], []]
    source.define_singleton_method(:updates) { |offset:| batches.shift }
    poller = T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry, clock: -> { @time })
    poller.once
    @time += 25 * 60 * 60
    poller.once
    @time += 1
    poller.once
    refute @relay.reconcile(request: 'q-1', through: @time.iso8601)['healthy'], 'Nonempty first batch after Telegram retention gap erased the gap and certified old coverage'
  end

  def test_recovered_empty_polls_restore_healthy_coverage_for_a_new_request
    submit
    source = Object.new
    failing = true
    source.define_singleton_method(:updates) { |offset:| raise 'temporary network fault' if failing; [] }
    poller = T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry, clock: -> { @time })
    assert_raises(Ace::Hitl::Hermes::ContractError) { poller.once }
    failing = false
    @time += 60
    poller.once
    @time += 60
    submit('q-new')
    poller.once
    assert @relay.reconcile(request: 'q-new', through: @time.iso8601)['healthy'], 'A newly submitted request cannot obtain healthy coverage even after successful empty polls'
  end

  def test_queued_secret_after_crash_is_not_confirmed_without_delivery_or_explicit_failure
    submit(secret: true)
    @journal.synchronize do |state, commit|
      state['sequence'] = 1
      state['ingress'] << {'request' => 'q-1', 'revision' => 'rev-1', 'channel' => 'lab', 'message_id' => '101', 'sequence' => 1, 'received_at' => QUESTION_TS, 'status' => 'queued'}
      commit.call
    end
    result = @relay.receive(event('987654'))
    assert_equal 'secret-unavailable', result['status'], 'Crashed queued secret must become explicit unavailable instead of blocking Telegram offset forever'
  end

  def test_recovery_epoch_preserves_old_unknown_and_allows_fresh_request
    submit
    source = Object.new
    failing = false
    source.define_singleton_method(:updates) { |offset:| raise "poll failed" if failing; [] }
    poller = T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry,
      clock: -> { @time })
    poller.once
    failing = true
    @time += 1
    assert_raises(Ace::Hitl::Hermes::ContractError) { poller.once }
    failing = false
    @time += 60
    poller.once
    submit("q-fresh")
    poller.once
    refute @relay.reconcile(request: "q-1", through: @time.iso8601)["healthy"]
    assert @relay.reconcile(request: "q-fresh", through: @time.iso8601)["healthy"]
    @journal.synchronize do |state, _|
      assert state["poll_history"]["lab"].any? { |epoch| epoch["generation"] == 0 }
      refute_equal state["requests"]["q-1"]["coverage_generation"], state["poll"]["lab"]["generation"]
    end
  end

  def test_crashed_secret_replay_advances_cursor_without_ipc_or_old_challenge_retry
    submit(secret: true)
    @journal.synchronize do |state, commit|
      state["sequence"] = 1
      state["ingress"] << {"request" => "q-1", "revision" => "rev-1", "channel" => "lab",
        "message_id" => "101", "sequence" => 1, "received_at" => QUESTION_TS, "status" => "queued"}
      commit.call
    end
    updates = [{"update_id" => 8, "message" => {"message_id" => 101,
      "chat" => {"id" => -424242, "type" => "supergroup"}, "from" => {"id" => 42},
      "reply_to_message" => {"message_id" => 100}, "text" => "987654"}}]
    source = Object.new
    source.define_singleton_method(:updates) { |offset:| updates }
    T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry,
      clock: -> { @time }).once
    @journal.synchronize do |state, _|
      assert_equal 9, state["cursor"]["offset"]
      assert_equal "secret-unavailable", state["ingress"][0]["status"]
    end
    assert_equal "secret-unavailable", @relay.receive(event("123456", message_id: "102"))["status"]
    assert_empty @boundary.answers
    assert_empty box.poll.messages
    assert_no_secret("987654", @relay.delivery("q-1"))
  end

  def assert_no_secret(secret, projection)
    require "digest"
    bytes = File.read(File.join(@tmp, "state", "journal.json")) + JSON.generate(projection)
    refute_includes bytes, secret
    refute_includes bytes, Digest::SHA256.hexdigest(secret)
  end
end
