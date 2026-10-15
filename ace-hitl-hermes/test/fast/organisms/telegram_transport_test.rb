# frozen_string_literal: true

require_relative "../../test_helper"

class TelegramTransportTest < AceHermesTestCase
  T = Ace::Hitl::Hermes::Transport

  class Boundary
    attr_reader :answers, :effects
    attr_accessor :unavailable

    def initialize(project = "lab")
      @project = project
      @requests, @answers, @effects = {}, [], 0
    end

    def add(id, secret: false, kind: nil)
      kind ||= secret ? "otp" : "text"
      @requests[id] = {"id" => id, "attempt" => "attempt651", "assignment" => "assign651", "project" => @project,
                       "requester" => "agent", "kind" => kind,
                       "sensitive" => secret, "question" => "Proceed?", "state" => "created"}
      envelope = {"schema" => Ace::Hitl::Contract::ManagedEnvelope::SCHEMA, "request_id" => id,
        "request_incarnation" => "0123456789abcdef",
        "project" => @project, "assignment_id" => "assign651", "attempt_id" => "attempt651", "requester" => "agent",
        "correlation_id" => id, "kind" => kind, "reverse" => nil}
      envelope["payload_sha256"] = Digest::SHA256.hexdigest("Proceed?") unless secret
      @requests[id]["envelope"] = envelope
    end

    def add_envelope(envelope)
      id = envelope.fetch("request_id")
      @requests[id] = {"id" => id, "attempt" => envelope["attempt_id"], "assignment" => envelope["assignment_id"],
        "project" => envelope["project"], "requester" => envelope["requester"], "kind" => envelope["kind"],
        "sensitive" => envelope["kind"] == "otp", "question" => envelope.dig("message", "question"),
        "state" => "created", "envelope" => Marshal.load(Marshal.dump(envelope))}
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

    def proposal_reply(id, project:, answer:, **)
      raise "wrong project" unless project == @project

      @answers << [id, answer.dup]
      @requests.fetch(id)["state"] = "answer-delivered"
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
       "captain_user_ids" => ["42"], "machine" => "host", "folder" => folder, "target" => "#{name}-overseer",
       "projects" => [name], "hitl_service_uid" => Process.uid}
    end
    @registry = T::Registry.new({"schema" => "ace.hitl.hermes.channels/v1", "channels" => channels})
    @journal = T::Journal.new(File.join(@tmp, "state"))
    @boundaries = {"lab" => Boundary.new("lab"), "other" => Boundary.new("other")}
    @boundary = @boundaries.fetch("lab")
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
      answer_authorizer: authorized ? ->(id) { @boundaries.fetch(channel).read(id) } : nil)
  end

  def relay(sender: @sender)
    T::Relay.new(registry: @registry, journal: @journal,
      lifecycle_for: ->(channel) { @boundaries.fetch(channel.fetch("name")) }, sender: sender,
      clock: -> { @time }, box_factory: ->(channel) { box(channel["name"]) })
  end

  def submit(id = "q-1", secret: false, channel: "lab", kind: nil)
    @boundaries.fetch(channel).add(id, secret: secret, kind: kind)
    box(channel).publish(kind: :question, id: id, body: "Proceed?", sender: "agent", timestamp: QUESTION_TS)
    @relay.submit(channel: channel, request: id, revision: "rev-1")
  end

  def event(text = "yes", **changes)
    {"platform" => "telegram", "chat_id" => "-424242", "chat_type" => "supergroup", "user_id" => "42",
     "message_id" => "101", "reply_to_message_id" => "100", "text" => text}.merge(changes.transform_keys(&:to_s))
  end

  def test_identical_request_ids_remain_isolated_by_channel_authority
    submit("same-id", channel: "lab")
    submit("same-id", channel: "other")

    other_event = event("other answer", chat_id: "-848484", message_id: "202")
    assert_equal "delivered", @relay.receive(other_event)["status"]
    assert_empty @boundaries.fetch("lab").answers
    assert_equal [["same-id", "other answer"]], @boundaries.fetch("other").answers
    assert_equal "submitted", @relay.delivery(channel: "lab", request: "same-id")["status"]
    assert_equal "submitted", @relay.delivery(channel: "other", request: "same-id")["status"]
  end

  def test_reconciliation_ignores_same_request_revision_ingress_from_another_channel
    submit("same-id", channel: "lab")
    submit("same-id", channel: "other")
    @relay.poll_complete(channel: "lab", started_at: QUESTION_TS, through: QUESTION_TS, continuous: true)
    @journal.synchronize do |state, commit|
      state["ingress"] << {"request" => "same-id", "revision" => "rev-1", "channel" => "other",
        "sequence" => 1, "received_at" => QUESTION_TS, "status" => "unresolved"}
      commit.call
    end

    result = @relay.reconcile(channel: "lab", request: "same-id", through: QUESTION_TS)
    assert result["healthy"]
    assert result["drained"]
  end

  def test_proposal_reply_ignores_unresolved_same_identity_ingress_from_another_channel
    submit("same-proposal", channel: "lab", kind: "proposal")
    submit("same-proposal", channel: "other", kind: "proposal")
    @journal.synchronize do |state, commit|
      state["sequence"] = 1
      state["ingress"] << {"request" => "same-proposal", "revision" => "rev-1", "channel" => "lab",
        "message_id" => "101", "sequence" => 1, "received_at" => QUESTION_TS, "status" => "unresolved"}
      commit.call
    end

    result = @relay.receive(event("approve", chat_id: "-848484", message_id: "202"))
    assert_equal "delivered", result["status"]
    assert_equal [["same-proposal", "approve"]], @boundaries.fetch("other").answers
  end

  def shared_request
    path = Gem::Specification.find_by_name("ace-hitl-contract").full_gem_path
    value = JSON.parse(File.read(File.join(path, "lib/ace/hitl/contract/examples/managed-request.json")))
    channels = @registry.channels.map { |channel| channel.merge("projects" => channel["name"] == "lab" ? ["ace"] : ["other"]) }
    @registry = T::Registry.new({"schema" => "ace.hitl.hermes.channels/v1", "channels" => channels})
    @relay = relay
    @boundary.add_envelope(value)
    value
  end

  def test_shared_managed_example_is_consumed_without_merging_folder_and_reverse_schemas
    value = shared_request
    id = value.fetch("request_id")
    box.publish(kind: :question, id: id, body: value.dig("message", "question"), sender: "agent", timestamp: QUESTION_TS)
    assert_equal "submitted", @relay.submit(channel: "lab", request: id, revision: "revision1")["status"]
    assert_equal ["lab", "Proceed?"], @sent.first
    assert_equal "delivered", @relay.receive(event("Approved"))["status"]
    assert_equal [[id, "Approved"]], @boundary.answers
    assert_equal "ace.hitl.hermes.message/v1", JSON.parse(File.read(File.join(@folders["lab"], "#{id}.json")))["schema"]
  end

  def test_managed_wrong_version_attempt_and_correlation_refuse_before_transport
    value = shared_request
    [->(v) { v["schema"] = "ace.hitl.managed/v99" }, ->(v) { v["attempt_id"] = "other685" },
     ->(v) { v["correlation_id"] = "other-request" }].each do |change|
      facts = @boundary.read(value.fetch("request_id"))
      change.call(facts["envelope"])
      assert_raises(Ace::Hitl::Hermes::ContractError) do
        @relay.submit(channel: "lab", request: value.fetch("request_id"), revision: "revision1")
      end
      @boundary.add_envelope(value)
    end
    assert_empty @sent
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

  def test_reply_to_pre_upgrade_bare_request_key_is_delivered_after_restart
    submit
    path = File.join(@tmp, "state", "journal.json")
    state = JSON.parse(File.read(path))
    record = state["requests"].delete(JSON.generate(["lab", "q-1"]))
    state["requests"]["q-1"] = record
    File.write(path, JSON.generate(state))
    File.chmod(0o600, path)
    @journal = T::Journal.new(File.join(@tmp, "state"))
    @relay = relay

    assert_equal "delivered", @relay.receive(event)["status"]
    assert_equal [["q-1", "yes"]], @boundary.answers
  end

  def test_shared_ingress_examples_match_real_unknown_drained_and_unresolved_semantics
    path = Gem::Specification.find_by_name("ace-hitl-contract").full_gem_path
    examples = JSON.parse(File.read(File.join(path, "lib/ace/hitl/contract/examples/ingress-checkpoints.json"))).fetch("cases")
    submit
    actual = @relay.reconcile(channel: "lab", request: "q-1", through: QUESTION_TS)
    keys = %w[schema status healthy drained]
    assert_equal examples[0].slice(*keys), actual.slice(*keys)
    assert_nil actual["checkpoint"]
    @relay.poll_complete(channel: "lab", started_at: QUESTION_TS, through: QUESTION_TS, continuous: true)
    actual = @relay.reconcile(channel: "lab", request: "q-1", through: QUESTION_TS)
    assert_equal examples[1].slice(*keys), actual.slice(*keys)
    assert_equal QUESTION_TS, actual.dig("checkpoint", "through")
    @journal.synchronize do |state, commit|
      state["ingress"] << {"request" => "q-1", "revision" => "rev-1", "channel" => "lab",
        "sequence" => 1, "received_at" => QUESTION_TS, "status" => "unresolved"}
      commit.call
    end
    actual = @relay.reconcile(channel: "lab", request: "q-1", through: QUESTION_TS)
    assert_equal examples[2].slice(*keys), actual.slice(*keys)
    assert_equal QUESTION_TS, actual["unresolved"].first["received_at"]
  end

  def test_reconciliation_requires_real_coverage_and_excludes_untrusted_event_timestamp
    submit
    assert_equal "unknown", @relay.reconcile(channel: "lab", request: "q-1", through: QUESTION_TS)["status"]
    @time += 60
    result = @relay.receive(event("yes", received_at: "2000-01-01T00:00:00Z"))
    assert_equal @time.iso8601, result["received_at"]
    @relay.poll_complete(channel: "lab", started_at: QUESTION_TS, through: @time.iso8601, continuous: true)
    checkpoint = @relay.reconcile(channel: "lab", request: "q-1", through: @time.iso8601)
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
    result = @relay.reconcile(channel: "lab", request: "q-1", through: @time.iso8601)
    refute result["drained"]
    assert_equal "queued", result["unresolved"].first["status"]
    @time += 60
    @relay.poll_complete(channel: "lab", started_at: @time.iso8601, through: @time.iso8601, continuous: true)
    refute @relay.reconcile(channel: "lab", request: "q-1", through: @time.iso8601)["healthy"]
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
    refute @relay.reconcile(channel: "lab", request: "q-1", through: QUESTION_TS)["healthy"]
    assert_equal 0, poller.once
    assert @relay.reconcile(channel: "lab", request: "q-1", through: QUESTION_TS)["drained"]
    assert_equal [0, 9], offsets
  end

  def test_poller_durably_records_skipped_unregistered_group_without_message_body
    update = {"update_id" => 23, "message" => {"message_id" => 301,
      "chat" => {"id" => -999999, "type" => "supergroup"}, "text" => "must not enter journal"}}
    source = Object.new
    source.define_singleton_method(:updates) { |offset:| [update] }

    T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry,
      clock: -> { @time }).once

    @journal.synchronize do |state, _|
      record = state["unregistered_chats"]["-999999"]
      assert_equal 1, record["count"]
      assert_equal 23, record["first_update_id"]
      assert_equal 23, record["last_update_id"]
      assert_equal 24, state["cursor"]["offset"]
    end
    refute_includes File.read(File.join(@tmp, "state", "journal.json")), "must not enter journal"
  end

  def test_poller_commits_unregistered_chat_before_advancing_offset
    update = {"update_id" => 23, "message" => {"message_id" => 301,
      "chat" => {"id" => -999999, "type" => "supergroup"}, "text" => "unknown group"}}
    source = Object.new
    source.define_singleton_method(:updates) { |offset:| [update] }
    observed_cursor = nil
    state_directory = File.join(@tmp, "state")
    original_record = @journal.method(:record_unregistered)
    @journal.define_singleton_method(:record_unregistered) do |**arguments|
      original_record.call(**arguments)
      T::Journal.new(state_directory).synchronize do |state, _|
        observed_cursor = state["cursor"]
      end
    end

    T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry,
      clock: -> { @time }).once

    assert_nil observed_cursor, "Telegram offset advanced before the unregistered chat record was durable"
    @journal.synchronize do |state, _|
      assert_equal 23, state.dig("unregistered_chats", "-999999", "last_update_id")
      assert_equal 24, state.dig("cursor", "offset")
    end
  end

  def test_poller_gap_survives_restart_and_late_registration_starts_informed_generation
    updates = [21, 23].map do |update_id|
      {"update_id" => update_id, "message" => {"message_id" => update_id + 100,
        "chat" => {"id" => -999999, "type" => "supergroup"}, "text" => "unknown group"}}
    end
    source = Object.new
    source.define_singleton_method(:updates) { |offset:| updates }
    T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry,
      clock: -> { @time }).once

    channels = @registry.channels.map(&:dup)
    late_folder = File.join(@tmp, "late")
    FileUtils.mkdir_p(late_folder, mode: 0o750)
    channels << {"name" => "late", "chat_id" => "-999999", "captain_user_ids" => ["42"],
      "machine" => "host", "folder" => late_folder, "target" => "late-overseer",
      "projects" => ["late"], "hitl_service_uid" => Process.uid}
    restarted_registry = T::Registry.new({"schema" => "ace.hitl.hermes.channels/v1", "channels" => channels})
    restarted_journal = T::Journal.new(File.join(@tmp, "state"))
    restarted_relay = T::Relay.new(registry: restarted_registry, journal: restarted_journal,
      lifecycle_for: ->(_channel) { raise "late channel must not replay an unknown update" }, sender: @sender,
      clock: -> { @time })

    gap = restarted_relay.surface_registration_gaps(at: @time.iso8601).fetch(0)
    assert_equal({"chat_id" => "-999999", "first_seen_at" => @time.iso8601,
      "last_seen_at" => @time.iso8601, "first_update_id" => 21, "last_update_id" => 23,
      "count" => 2, "channel" => "late", "coverage_generation" => 1}, gap)
    assert_empty restarted_relay.surface_registration_gaps(at: @time.iso8601)
    restarted_journal.synchronize do |state, _|
      assert_equal 1, state.dig("poll", "late", "generation")
      refute state.dig("poll", "late", "healthy")
      assert_equal 23, state.dig("unregistered_chats", "-999999", "surfaced_through_update_id")
    end
    assert_equal 0, @boundary.effects
  end

  def test_registration_gap_marker_and_poll_generation_share_one_durable_commit
    @journal.record_unregistered(
      updates: [{"chat_id" => "-424242", "update_id" => 31}], observed_at: QUESTION_TS
    )
    @journal.define_singleton_method(:write) { |_| raise IOError, "injected commit failure" }

    assert_raises(IOError) { @relay.surface_registration_gaps(at: QUESTION_TS) }

    T::Journal.new(File.join(@tmp, "state")).synchronize do |state, _|
      record = state["unregistered_chats"]["-424242"]
      refute record.key?("surfaced_through_update_id")
      assert_nil state["poll"]["lab"]
    end
  end

  def test_poller_failure_invalidates_checkpoint_and_actor_lease_excludes_competitor
    submit
    source = Object.new
    source.define_singleton_method(:updates) { |offset:| raise "failure" }
    poller = T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry, clock: -> { @time })
    assert_raises(Ace::Hitl::Hermes::ContractError) { poller.once }
    refute @relay.reconcile(channel: "lab", request: "q-1", through: QUESTION_TS)["healthy"]
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
    refute @relay.reconcile(channel: "lab", request: "q-1", through: @time.iso8601)["drained"]
    @journal.synchronize do |state, commit|
      state["cursor"] = {"offset" => 0, "through" => QUESTION_TS, "coverage_from" => QUESTION_TS, "generation" => 0}
      commit.call
    end
    @time += 24 * 60 * 60
    source = Object.new
    source.define_singleton_method(:updates) { |offset:| [] }
    T::Poller.new(relay: @relay, telegram: source, journal: @journal, registry: @registry,
      clock: -> { @time }).once
    refute @relay.reconcile(channel: "lab", request: "q-1", through: @time.iso8601)["healthy"]
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
      @relay.reconcile(channel: "lab", request: "q-1", through: QUESTION_TS)
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
    refute @relay.reconcile(channel: "lab", request: "q-1", through: @time.iso8601)["healthy"],
      "Nonempty first batch after Telegram retention gap erased the gap and certified old coverage"
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
    assert @relay.reconcile(channel: "lab", request: "q-new", through: @time.iso8601)["healthy"],
      "A newly submitted request cannot obtain healthy coverage even after successful empty polls"
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
    refute @relay.reconcile(channel: "lab", request: "q-1", through: @time.iso8601)["healthy"]
    assert @relay.reconcile(channel: "lab", request: "q-fresh", through: @time.iso8601)["healthy"]
    @journal.synchronize do |state, _|
      assert state["poll_history"]["lab"].any? { |epoch| epoch["generation"] == 0 }
      key = JSON.generate(["lab", "q-1"])
      refute_equal state["requests"][key]["coverage_generation"], state["poll"]["lab"]["generation"]
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
    assert_no_secret("987654", @relay.delivery(channel: "lab", request: "q-1"))
  end

  def assert_no_secret(secret, projection)
    require "digest"
    bytes = File.read(File.join(@tmp, "state", "journal.json")) + JSON.generate(projection)
    refute_includes bytes, secret
    refute_includes bytes, Digest::SHA256.hexdigest(secret)
  end
end
