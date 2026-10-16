# frozen_string_literal: true

require "test_helper"
require "ace/hitl/hermes/runtime"
require "digest"
require "time"

class RuntimeRoutingTest < AceHermesTestCase
  class Lifecycle
    attr_reader :pending_projects

    def initialize(project)
      @project = project
      @pending_projects = []
      @facts = request_facts(project)
    end

    def pending(project:)
      @pending_projects << project
      project == @project ? [Marshal.load(Marshal.dump(@facts))] : []
    end

    def read(id)
      raise KeyError unless id == @facts["id"]

      Marshal.load(Marshal.dump(@facts))
    end

    def proposal_due(project:, after:)
      raise "wrong authority" unless project == @project

      {"items" => [], "next" => nil}
    end

    def ping
      {"pong" => true}
    end

    private

    def request_facts(project)
      id = "shared-request"
      envelope = {"schema" => Ace::Hitl::Contract::ManagedEnvelope::SCHEMA, "request_id" => id,
                  "request_incarnation" => "0123456789abcdef", "project" => project,
                  "assignment_id" => "assign651", "attempt_id" => "attempt651", "requester" => "agent",
                  "correlation_id" => id, "kind" => "text", "reverse" => nil,
                  "payload_sha256" => Digest::SHA256.hexdigest("Proceed?")}
      {"id" => id, "attempt" => "attempt651", "assignment" => "assign651", "project" => project,
       "requester" => "agent", "kind" => "text", "sensitive" => false, "question" => "Proceed?",
       "state" => "created", "created_at" => Time.iso8601(AceHermesTestCase::QUESTION_TS).to_i,
       "envelope" => envelope}
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("hermes-routing", "/tmp")
    @registry_path = File.join(@tmp, "channels.json")
    @config_path = File.join(@tmp, "runtime.json")
    @default_socket = File.join(@tmp, "default.sock")
    @other_socket = File.join(@tmp, "other.sock")
    channels = [
      channel("lab", "-424242", "lab", 4100),
      channel("host", "-848484", "host", 4200, socket: @other_socket)
    ]
    File.write(@registry_path, JSON.generate({"schema" => "ace.hitl.hermes.channels/v2", "channels" => channels}))
    File.write(@config_path, JSON.generate({
      "schema" => "ace.hitl.hermes.runtime/v1", "registry" => @registry_path,
      "state" => File.join(@tmp, "state"),
      "polling_owner" => "ace-hitl-hermes", "hermes_gateway_config" => File.join(@tmp, "gateway.yml")
    }))
    File.write(File.join(@tmp, "gateway.yml"), "platforms:\n  telegram:\n    enabled: false\n")
  end

  def teardown
    FileUtils.remove_entry(@tmp)
    super
  end

  def test_clients_are_lazy_cached_per_socket_with_explicit_channel_service_identity
    created = []
    constructor = lambda do |**route|
      created << route
      Object.new
    end

    runtime = nil
    Ace::Hitl::Lifecycle::Client.stub(:new, constructor) do
      runtime = Ace::Hitl::Hermes::Runtime.new(@config_path)
      assert_empty created
      lab = runtime.send(:lifecycle_for, "lab", "lab")
      assert_same lab, runtime.send(:lifecycle_for, "lab", "lab")
      host = runtime.send(:lifecycle_for, "host", "host")
      refute_same lab, host
    end

    assert_equal [
      {socket_path: @default_socket, service_uid: 4100},
      {socket_path: @other_socket, service_uid: 4200}
    ], created
  end

  def test_same_socket_cannot_claim_multiple_service_identities
    registry = JSON.parse(File.read(@registry_path))
    registry["channels"][1]["projects"]["host"]["hitl_socket"] = @default_socket
    File.write(@registry_path, JSON.generate(registry))

    error = assert_raises(Ace::Hitl::Hermes::ContractError) do
      Ace::Hitl::Hermes::Runtime.new(@config_path)
    end
    assert_match(/multiple service identities/, error.message)
  end

  def test_pending_publication_and_submission_use_only_the_channels_authority
    lifecycles = {@default_socket => Lifecycle.new("lab"), @other_socket => Lifecycle.new("host")}
    constructor = ->(socket_path:, service_uid:) { lifecycles.fetch(socket_path) }
    sent = []
    telegram = Object.new
    telegram.define_singleton_method(:updates) { |offset:| [] }
    telegram.define_singleton_method(:call) do |channel, question|
      sent << [channel.fetch("name"), question]
      {"success" => true, "chat_id" => channel.fetch("chat_id"), "message_id" => "100"}
    end

    Ace::Hitl::Lifecycle::Client.stub(:new, constructor) do
      runtime = Ace::Hitl::Hermes::Runtime.new(@config_path, clock: -> { Time.iso8601(QUESTION_TS) })
      runtime.define_singleton_method(:telegram) { telegram }
      runtime.serve(once: true)
      assert_equal "submitted", runtime.relay.delivery(channel: "lab", project: "lab", request: "shared-request")["status"]
      assert_equal "submitted", runtime.relay.delivery(channel: "host", project: "host", request: "shared-request")["status"]
    end

    assert_equal [["lab", "Proceed?"], ["host", "Proceed?"]], sent
    # The activation health probe also pends once per channel; only the
    # channel->authority ISOLATION is the assertion here.
    assert_equal ["lab"], lifecycles.fetch(@default_socket).pending_projects.uniq
    assert_equal ["host"], lifecycles.fetch(@other_socket).pending_projects.uniq
  end

  def test_proposal_reconciliation_continues_after_one_channel_authority_fails
    lifecycles = {@default_socket => Lifecycle.new("lab"), @other_socket => Lifecycle.new("host")}
    lifecycles.fetch(@default_socket).define_singleton_method(:proposal_due) do |**|
      raise Ace::Hitl::Lifecycle::TransportError, "unavailable"
    end
    lifecycles.fetch(@other_socket).define_singleton_method(:proposal_due) do |project:, after:|
      {"items" => [{"request_id" => "host-proposal", "deadline" => QUESTION_TS}], "next" => nil}
    end
    reconciled = []

    Ace::Hitl::Lifecycle::Client.stub(:new, ->(socket_path:, **) { lifecycles.fetch(socket_path) }) do
      runtime = Ace::Hitl::Hermes::Runtime.new(@config_path, clock: -> { Time.iso8601(QUESTION_TS) })
      runtime.relay.define_singleton_method(:reconcile) { |**args| reconciled << args }
      _, warning = capture_io { runtime.send(:reconcile_proposals) }
      assert_match(/unavailable for lab/, warning)
    end

    assert_equal [{channel: "host", project: "host", request: "host-proposal", through: QUESTION_TS}], reconciled
  end

  private

  def channel(name, chat_id, project, service_uid, socket: nil)
    folder = File.join(@tmp, name)
    FileUtils.mkdir_p(File.join(folder, "projects", project), mode: 0o750)
    value = {"name" => name, "machine" => "local", "folder" => folder, "target" => "#{name}-overseer",
             "projects" => {project => {"hitl_socket" => socket || @default_socket, "hitl_service_uid" => service_uid}},
             "chat_id" => chat_id, "captain_user_ids" => ["42"]}
    value
  end
end
