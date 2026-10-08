# frozen_string_literal: true
require "test_helper"
require "ace/herdr/molecules/inbox_context_completion_client"

class InboxContextOriginalClientTest < Minitest::Test
  Client = Ace::Herdr::Molecules::InboxContextCompletionClient
  Error = Ace::Herdr::ValidationError
  class SocketFixture
    def shutdown(*) = nil
  end
  class Wire
    attr_accessor :data, :writes
    def initialize(data); @data = data; @writes = []; end
    def root_path!(*, **) = true
    def socket_identity(*) = [1, 2, 13000]
    def deadline(*) = 1
    def connect(*, **); yield SocketFixture.new; end
    def write(_socket, frame, **); @writes << frame; end
    def read(*, **) = {"data" => @data, "status" => "ok", "transport" => {"replayed" => false}}
  end
  class Kernel
    attr_accessor :changed
    def peer(*) = {"uid" => 13000, "gid" => 13000, "groups" => [13000], "pid" => changed ? 2 : 1}
    def live!(*) = true
    def same?(left, right) = left == right
  end

  def setup
    @params = {assignment_id: "assignment", attempt_id: "attempt", event_id: "event", inbox_context_id: "context",
      purpose: "enqueue", payload_sha256: "a" * 64, receipt_key_sha256: "b" * 64}
    child = {"pid" => 12, "parent_pid" => 11, "uid" => 13001, "gid" => 13001, "groups" => [13001],
      "host" => "fixture", "started_at" => "linux:12345678-1234-1234-1234-123456789abc:91"}
    server = child.merge("pid" => 11, "parent_pid" => 1)
    native = {"scope_generation" => 2, "scope_binding_event_id" => "e" * 64, "service_invocation_id" => "f" * 32,
      "workspace_id" => "w1", "server_identity" => server, "socket_identity" => [1, 2, 13001]}
    @data = @params.transform_keys(&:to_s).slice("assignment_id", "attempt_id", "event_id", "inbox_context_id", "purpose")
      .merge("schema" => "ace.assign.inbox-context-original/v1", "project_id" => "project", "mapping_id" => "mapping",
        "commit" => "c" * 40, "registered" => false, "original_binding_digest" => "d" * 64,
        "registration" => @params.transform_keys(&:to_s).slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256"),
        "process_binding" => {"runtime" => "herdr", "session" => "w1", "pane" => "p1", "terminal_id" => "term_ab",
          "process_identity" => child, "shell_identity" => child, "native_origin" => {"workspace" => "w1", "tab" => "t1",
            "pane" => "p1", "server_identity" => server, "socket_identity" => [1, 2, 13001],
            "command" => ["/fixed/gate", "mapping", "ticket"], "cwd" => "/fixed/workspace"}},
        "guarded_origin" => {"terminal_id" => "term_ab", "runtime_incarnation" => "12345678-1234-1234-1234-123456789abc", "child" => child},
        "native_binding" => native, "native_channel" => {"socket_path" => "/fixed/native.sock", "version" => "0.9.3"})
    @wire, @kernel = Wire.new(@data), Kernel.new
    @client = Client.new(authority: {"socket_path" => "/fixed/authority.sock", "uid" => 13000, "gid" => 13000, "groups" => [13000]},
      project_id: "project", mapping_id: "mapping", wire: @wire, kernel: @kernel)
  end

  def test_fixed_query_is_bodyless_and_returns_immutable_identity_only
    result = @client.original!(**@params)
    assert_equal @data, result
    assert result.fetch("guarded_origin").fetch("child").frozen?
    frame = @wire.writes.fetch(0)
    assert_equal "inbox_context_original", frame.fetch("operation")
    assert_nil frame.fetch("mutation_id")
    assert_equal "mapping", frame.dig("params", "mapping_id")
    refute result.key?("native_thread")
  end

  def test_foreign_tuple_key_guard_and_noncanonical_registration_cannot_be_used
    [{"assignment_id" => "other"}, {"registration" => @data.fetch("registration").merge("receipt_key_sha256" => "f" * 64)},
      {"guarded_origin" => @data.fetch("guarded_origin").merge("terminal_id" => "term_cd")},
      {"extra" => "caller permit"}, {"commit" => "not-canonical"}, {"native_binding" => {}},
      {"native_binding" => @data.fetch("native_binding").merge("workspace_id" => "w2")}].each do |change|
      @wire.data = @data.merge(change)
      assert_raises(Error) { @client.original!(**@params) }
    end
    @wire.data = @data.merge("purpose" => "deliver")
    assert_raises(Error) { @client.original!(**@params.merge(purpose: "deliver")) }
  end

  def test_channel_shape_path_and_version_are_closed
    [{}, {"socket_path" => "/fixed/native.sock", "version" => "old"},
      {"socket_path" => "relative", "version" => "0.9.3"},
      {"socket_path" => "/fixed/../native.sock", "version" => "0.9.3"},
      {"socket_path" => "/" + "x" * 107, "version" => "0.9.3"},
      @data.fetch("native_channel").merge("worker_uid" => 13001)].each do |channel|
      @wire.data = @data.merge("native_channel" => channel)
      assert_raises(Error) { @client.original!(**@params) }
    end
  end

  def test_bad_selectors_refuse_before_transport
    assert_raises(Error) { @client.original!(**@params.merge(assignment_id: "")) }
    assert_empty @wire.writes
  end
end
