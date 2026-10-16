# frozen_string_literal: true
require "test_helper"
require "ace/hitl/hermes/runtime"

class MultiProjectRelayTest < AceHermesTestCase
  T = Ace::Hitl::Hermes::Transport
  class Lifecycle
    attr_reader :answers
    attr_accessor :unavailable
    def initialize(project)
      @project, @answers = project, []
    end
    def read(id)
      raise Ace::Hitl::Lifecycle::TransportError, "authority unavailable" if @unavailable
      envelope = {"schema" => Ace::Hitl::Contract::ManagedEnvelope::SCHEMA, "request_id" => id,
        "request_incarnation" => "0123456789abcdef", "project" => @project,
        "assignment_id" => "assign651", "attempt_id" => "attempt651", "requester" => "agent",
        "correlation_id" => id, "kind" => "text", "reverse" => nil,
        "payload_sha256" => Digest::SHA256.hexdigest("Proceed #{@project}?")}
      {"id" => id, "attempt" => "attempt651", "assignment" => "assign651", "project" => @project,
        "requester" => "agent", "kind" => "text", "sensitive" => false,
        "question" => "Proceed #{@project}?", "state" => @answers.empty? ? "created" : "answer-delivered",
        "envelope" => envelope}
    end
    def deliver(id, answer)
      @answers << [id, answer.dup] if @answers.empty?
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("multi-project-hermes", "/tmp")
    @root = File.join(@tmp, "lab")
    %w[ace nervus].each { |p| FileUtils.mkdir_p(File.join(@root, "projects", p), mode: 0o750) }
    @channel = {"name" => "lab", "chat_id" => "-424242", "captain_user_ids" => ["42"],
      "machine" => "lab", "folder" => @root, "target" => "lab-overseer", "projects" =>
        %w[ace nervus].to_h { |p| [p, {"hitl_socket" => File.join(@tmp, p + ".sock"), "hitl_service_uid" => Process.uid}] }}
    @registry = registry(@channel)
    @journal = T::Journal.new(File.join(@tmp, "state"))
    @clients = %w[ace nervus].to_h { |p| [p, Lifecycle.new(p)] }
    @sent = []
    @relay = relay
  end
  def teardown
    FileUtils.remove_entry(@tmp)
    super
  end
  def registry(channel)
    T::Registry.new("schema" => "ace.hitl.hermes.channels/v2", "channels" => [channel])
  end
  def relay(registry: @registry)
    T::Relay.new(registry: registry, journal: @journal,
      lifecycle_for: ->(_channel, project) { @clients.fetch(project) }, clock: -> { Time.iso8601(QUESTION_TS) },
      sender: ->(channel, question) {
        @sent << [channel.fetch("project"), question]
        {"success" => true, "chat_id" => channel.fetch("chat_id"), "message_id" => (99 + @sent.size).to_s}
      })
  end
  def submit(project)
    box = T::Relay.folder_box(@registry.project_channel("lab", project))
    box.publish(kind: :question, id: "same-id", body: "Proceed #{project}?", sender: "agent", timestamp: QUESTION_TS)
    @relay.submit(channel: "lab", project: project, request: "same-id", revision: "attempt651")
  end
  def event(reply: "100", text: "approved", message: "201")
    {"platform" => "telegram", "chat_type" => "supergroup", "chat_id" => "-424242", "user_id" => "42",
      "message_id" => message, "reply_to_message_id" => reply, "text" => text}
  end

  def test_same_group_and_request_id_keep_exact_project_reply_and_folder_identity
    submit("ace")
    submit("nervus")
    assert_equal "ace", @relay.receive(event)["project"]
    assert_empty @clients.fetch("nervus").answers
    assert_equal [["same-id", "approved"]], @clients.fetch("ace").answers
    assert_equal "nervus", @relay.receive(event(reply: "101", message: "202", text: "other"))["project"]
    assert_equal [["same-id", "other"]], @clients.fetch("nervus").answers
    %w[ace nervus].each do |project|
      assert_equal project, @relay.delivery(channel: "lab", project: project, request: "same-id").fetch("project")
      box = T::Relay.folder_box(@registry.project_channel("lab", project))
      assert_equal "lab/lab/#{project}/same-id", box.address("same-id")
      assert box.poll.messages.first.answer?
    end
  end
  def test_ambiguous_command_refuses_and_exact_reply_works_after_restart
    submit("ace")
    submit("nervus")
    @relay = relay
    assert_raises(Ace::Hitl::Hermes::ContractError) { @relay.receive(event(reply: "", text: "/hitl-reply same-id yes")) }
    assert @clients.values.all? { |c| c.answers.empty? }
    assert_equal "nervus", @relay.receive(event(reply: "101"))["project"]
  end
  def test_unregistered_project_never_selects_a_client
    assert_raises(Ace::Hitl::Hermes::ContractError) do
      @relay.submit(channel: "lab", project: "other", request: "same-id", revision: "attempt651")
    end
    assert_empty @sent
  end
  def test_changed_authority_cannot_reuse_retained_request
    submit("ace")
    changed = Marshal.load(Marshal.dump(@channel))
    changed.fetch("projects").fetch("ace")["hitl_socket"] = File.join(@tmp, "replacement.sock")
    replacement = relay(registry: registry(changed))
    assert_raises(Ace::Hitl::Hermes::ContractError) { replacement.delivery(channel: "lab", project: "ace", request: "same-id") }
    assert_raises(Ace::Hitl::Hermes::ContractError) { replacement.receive(event) }
    assert_empty @clients.fetch("ace").answers
  end
  def test_project_folder_symlink_cannot_alias_another_project
    project = File.join(@root, "projects", "ace")
    Dir.rmdir(project)
    File.symlink(File.join(@root, "projects", "nervus"), project)
    assert_raises(Ace::Hitl::Hermes::ContractError) { submit("ace") }
    assert_empty @sent
  end
  def test_old_journal_schema_is_refused_without_rewriting_history
    path = File.join(@tmp, "state", "journal.json")
    bytes = JSON.generate("schema" => "ace.hitl.hermes.transport/v1", "requests" => {}, "ingress" => [],
      "sequence" => 19, "poll" => {}, "unregistered_chats" => {})
    File.write(path, bytes)
    File.chmod(0o600, path)
    assert_raises(Ace::Hitl::Hermes::ContractError) { @journal.synchronize { flunk "old journal accepted" } }
    assert_equal bytes, File.read(path)
  end
  Crash = Class.new(Exception)

  def test_project_outage_does_not_hold_telegram_offset_or_starve_next_page
    submit("ace")
    submit("nervus")
    @clients.fetch("ace").unavailable = true
    updates = lambda do |id, reply|
      {"update_id" => id, "message" => {"message_id" => id + 200,
        "chat" => {"id" => -424242, "type" => "supergroup"}, "from" => {"id" => 42},
        "reply_to_message" => {"message_id" => reply}, "text" => "answer-#{id}"}}
    end
    pages = [[updates.call(10, 100)], [updates.call(11, 101)], []]
    offsets = []
    telegram = Object.new
    telegram.define_singleton_method(:updates) { |offset:| offsets << offset; pages.shift }
    poller = T::Poller.new(relay: @relay, telegram: telegram, journal: @journal, registry: @registry,
      clock: -> { Time.iso8601(QUESTION_TS) })
    poller.once
    assert File.file?(File.join(@root, "projects", "ace", ".ingress", "inb-1.json"))
    @relay = relay # recovered actor uses only the retained original body
    poller = T::Poller.new(relay: @relay, telegram: telegram, journal: @journal, registry: @registry,
      clock: -> { Time.iso8601(QUESTION_TS) })
    poller.once
    assert_equal [["same-id", "answer-11"]], @clients.fetch("nervus").answers
    assert_empty @clients.fetch("ace").answers
    @clients.fetch("ace").unavailable = false
    poller.once
    assert_equal [["same-id", "answer-10"]], @clients.fetch("ace").answers
    assert_equal [0, 11, 12], offsets
    assert_empty Dir.children(File.join(@root, "projects", "ace", ".ingress"))
  end

  def test_crash_before_body_write_replays_reserved_sequence
    submit("ace")
    @relay.define_singleton_method(:persist_ingress) { |*| raise Crash }
    assert_raises(Crash) { @relay.receive(event(text: "first")) }
    @relay = relay
    assert_equal "delivered", @relay.receive(event(text: "first"))["status"]
    assert_equal [["same-id", "first"]], @clients.fetch("ace").answers
    @journal.synchronize { |state, _| assert_equal 1, state.fetch("sequence") }
  end

  def test_crash_after_body_fsync_before_metadata_keeps_original_on_edited_replay
    submit("ace")
    original_write = @journal.method(:write)
    writes = 0
    @journal.define_singleton_method(:write) do |state|
      writes += 1
      raise Crash if writes == 2
      original_write.call(state)
    end
    assert_raises(Crash) { @relay.receive(event(text: "original body")) }
    @journal = T::Journal.new(File.join(@tmp, "state"))
    @relay = relay
    assert_equal "delivered", @relay.receive(event(text: "edited replay"))["status"]
    assert_equal [["same-id", "original body"]], @clients.fetch("ace").answers
  end

  def test_crash_after_terminal_commit_never_repeats_delivery
    submit("ace")
    @relay.define_singleton_method(:cleanup_ingress) { |*| raise Crash }
    assert_raises(Crash) { @relay.receive(event(text: "once")) }
    @relay = relay
    @relay.drain
    assert_equal [["same-id", "once"]], @clients.fetch("ace").answers
    assert_empty Dir.children(File.join(@root, "projects", "ace", ".ingress"))
  end

  def test_revoked_captain_allowlist_cannot_deliver_previously_spooled_reply
    submit("ace")
    @clients.fetch("ace").unavailable = true
    assert_equal "unresolved", @relay.receive(event(text: "pending approval"))["status"]
    @clients.fetch("ace").unavailable = false
    changed = Marshal.load(Marshal.dump(@channel))
    changed["captain_user_ids"] = ["43"]
    replacement = relay(registry: registry(changed))
    replacement.drain
    assert_empty @clients.fetch("ace").answers
    assert_raises(Ace::Hitl::Hermes::ContractError) { replacement.receive(event) }
    assert File.file?(File.join(@root, "projects", "ace", ".ingress", "inb-1.json"))
  end

  def test_activation_refuses_alias_and_overlapping_channel_roots
    other = Marshal.load(Marshal.dump(@channel))
    other.merge!("name" => "other", "chat_id" => "-848484", "target" => "other-target",
      "projects" => {"other" => {"hitl_socket" => "/run/other.sock", "hitl_service_uid" => Process.uid}})
    [@root, File.join(@root, "nested")].each do |folder|
      FileUtils.mkdir_p(folder)
      other["folder"] = folder
      value = T::Registry.new("schema" => "ace.hitl.hermes.channels/v2", "channels" => [@channel, other]) rescue nil
      if value
        assert_raises(Ace::Hitl::Hermes::ContractError) { value.verify_folders! }
      else
        assert_equal @root, folder # exact textual duplicate is rejected during registry parsing
      end
    end
    alias_folder = File.join(@tmp, "alias")
    File.symlink(@root, alias_folder)
    other["folder"] = alias_folder
    value = T::Registry.new("schema" => "ace.hitl.hermes.channels/v2", "channels" => [@channel, other])
    assert_raises(Ace::Hitl::Hermes::ContractError) { value.verify_folders! }
  end

  def test_malformed_v2_ingress_cannot_cross_project_or_repeat_an_origin
    submit("ace")
    submit("nervus")
    @clients.fetch("ace").unavailable = true
    assert_equal "unresolved", @relay.receive(event)["status"]
    path = File.join(@tmp, "state", "journal.json")
    original = JSON.parse(File.read(path))
    mutations = [
      ->(state) { state.fetch("ingress").first["project"] = "unknown" },
      ->(state) { state.fetch("ingress").first["revision"] = "wrong" },
      ->(state) {
        duplicate = state.fetch("ingress").first.dup.merge("sequence" => 2)
        state["sequence"] = 2
        state.fetch("ingress") << duplicate
      },
      ->(state) { state.fetch("requests").values.first["sensitive"] = nil }
    ]
    mutations.each do |mutate|
      state = Marshal.load(Marshal.dump(original))
      mutate.call(state)
      bytes = JSON.generate(state)
      File.write(path, bytes)
      assert_raises(Ace::Hitl::Hermes::ContractError) { @relay.drain }
      assert_equal bytes, File.read(path)
      assert @clients.values.all? { |client| client.answers.empty? }
    end
  end

end
