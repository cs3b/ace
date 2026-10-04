# frozen_string_literal: true

require "test_helper"
require "socket"
require "json"
require "support/lifecycle_fixtures"

# The scoped store boundary (spec 8wq.t.34i): the REAL service and the
# REAL client talk over a REAL AF_UNIX socket in-process — classified
# errors cross the wire, roles are enforced from the (same-uid) peer
# identity, and idempotent terminals survive transport retries.
class ScopedServiceTest < AceHitlTestCase
  include LifecycleFixtures

  REQUESTER = "lab-asker"

  def setup
    @scratch = Dir.mktmpdir("ace-hitl-boundary")
    @store_root = File.join(@scratch, "store")
    @socket_path = File.join(@scratch, "hitl.sock")
    @binding = LifecycleFixtures::TestBinding.new
    @policy = LifecycleFixtures::AllowTransportPolicy.new
    @service = Ace::Hitl::Lifecycle::Service.new(
      root: @store_root,
      binding: @binding,
      policy: @policy,
      socket_path: @socket_path,
      group: "staff"
    )
    @thread = Thread.new { @service.run }
    wait_for_socket
  end

  def teardown
    @service&.stop
    @thread&.join(5)
    @thread&.exit
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
  end

  def client
    Ace::Hitl::Lifecycle::Client.new(socket_path: @socket_path, service_uid: Process.uid)
  end

  def wait_for_socket
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    until File.exist?(@socket_path)
      raise "boundary socket never appeared" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.02
    end
  end

  def managed_args(id: "hitl001", kind: "decision", assignment: "8x3test", attempt: "a1b2c3")
    {
      id: id, assignment: assignment, attempt: attempt, kind: kind,
      project: "ace", harness: "agy", plan: "configure CI",
      question: "approve the exact change?", ace_hitl_id: "ace-hitl-1"
    }
  end

  def test_ping_and_full_lifecycle_round_trip_through_the_boundary
    result = client.ping
    assert_equal true, result["pong"]

    created = client.create(**managed_args.transform_keys(&:to_s))
    assert_equal "hitl001", created["id"]

    facts = client.read("hitl001")
    assert_equal "created", facts["state"]
    refute_includes JSON.generate(facts), "answer"

    delivered = client.deliver("hitl001", "approved")
    assert_equal true, delivered["delivered"]

    consumed = client.consume("hitl001", timeout: 2)
    assert_equal "approved", consumed["answer"]
    assert_equal "ace", consumed["project"]

    # A late cancel of a consumed request is a classified conflict.
    error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
      client.cancel("hitl001", reason: "not needed")
    end
    assert_match(/already consumed/, error.message)

    # ...and cancelling a live request still works end-to-end.
    client.create(**managed_args(id: "hitl002").transform_keys(&:to_s))
    cancelled = client.cancel("hitl002", reason: "not needed")
    assert_equal true, cancelled["cancelled"]
    replay = client.cancel("hitl002", reason: "not needed")
    assert_equal true, replay["replay"]
  end

  def test_transport_operations_reach_the_store_through_the_boundary
    client.create(**managed_args.transform_keys(&:to_s))
    client.create(**managed_args(id: "hitl002").transform_keys(&:to_s))

    pending = client.pending
    assert_equal %w[hitl001 hitl002], pending.map { |value| value["id"] }
    states = client.states
    assert_equal 2, states.length
  end

  def test_classified_errors_cross_the_wire_under_their_own_classes
    error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
      client.read("absent1")
    end
    assert_match(/unknown or invalid HITL request/, error.message)

    error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
      client.create(**managed_args.transform_keys(&:to_s).merge("assignment" => "../evil"))
    end
    assert_match(/exact managed assignment and attempt/, error.message)
  end

  def test_requester_gate_enforced_through_the_peer_identity
    # The peer identity IS the store identity: the service resolves it
    # from kernel credentials, so a payload requester name cannot
    # impersonate anyone. The pinned service-side identity here is the
    # test process owner; a foreign-requester consume fails with the
    # classified permission error.
    client.create(**managed_args.transform_keys(&:to_s))
    store = Ace::Hitl::Lifecycle::Store.new(
      root: @store_root, binding: @binding, policy: @policy,
      identity: LifecycleFixtures::TestIdentity.new(username: "someone-else")
    )
    error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      store.consume("hitl001", timeout: 1)
    end
    assert_match(/only the requesting role/, error.message)
  end

  def test_idempotent_terminals_survive_transport_retries
    client.create(**managed_args.transform_keys(&:to_s))
    client.deliver("hitl001", "approved")
    consumed = client.consume("hitl001", timeout: 2)

    # A retry after a cut response reports the committed receipt and
    # never re-runs the answer hand-off.
    replay = client.consume("hitl001", timeout: 2)
    assert_equal true, replay["replay"]
    assert_equal consumed["answer"], replay["answer"]

    error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
      client.deliver("hitl001", "late answer")
    end
    assert_match(/already consumed/, error.message)
  end

  def test_unavailable_boundary_is_a_classified_transport_error
    absent = Ace::Hitl::Lifecycle::Client.new(
      socket_path: File.join(@scratch, "absent.sock"), service_uid: Process.uid
    )
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      absent.ping
    end
    assert_match(/does not exist|unavailable/, error.message)
  end

  def test_world_writable_endpoint_is_refused_before_any_byte_is_sent
    File.chmod(0o666, @socket_path)
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      client.ping
    end
    assert_match(/world-writable/, error.message)
  end

  def test_non_socket_endpoint_is_refused
    decoy = File.join(@scratch, "decoy.sock")
    File.write(decoy, "not a socket")
    decoy_client = Ace::Hitl::Lifecycle::Client.new(socket_path: decoy, service_uid: Process.uid)
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      decoy_client.ping
    end
    assert_match(/not a socket/, error.message)
  end

  def test_terminal_replay_never_discloses_to_a_foreign_requester
    # A direct store view with a FOREIGN identity proves the gate: the
    # committed answer replays only to the requester of record (review
    # 8x327buc, critical).
    client.create(**managed_args.transform_keys(&:to_s))
    client.deliver("hitl001", "approved")
    client.consume("hitl001", timeout: 2)

    foreign = Ace::Hitl::Lifecycle::Store.new(
      root: @store_root, binding: @binding, policy: @policy,
      identity: LifecycleFixtures::TestIdentity.new(username: "someone-else")
    )
    # Foreign callers get the uniform denial — never the terminal
    # state, never the answer (review 8x32r9b1).
    error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
      foreign.consume("hitl001", timeout: 1)
    end
    assert_match(/only the requesting role/, error.message)
    refute_includes error.message, "approved"
  end

  def test_a_second_service_refuses_a_live_endpoint
    second = Ace::Hitl::Lifecycle::Service.new(
      root: File.join(@scratch, "store3"), binding: @binding, policy: @policy,
      socket_path: @socket_path, group: "staff"
    )
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      second.send(:prepare!)
    end
    assert_match(/already serving/, error.message)
  end

  def test_consume_waits_for_a_pending_otp_delivery_through_the_boundary
    vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
    otp_service = Ace::Hitl::Lifecycle::Service.new(
      root: File.join(@scratch, "store4"), binding: @binding, policy: @policy,
      socket_path: File.join(@scratch, "hitl4.sock"), group: "staff", vault: vault
    )
    thread = Thread.new { otp_service.run }
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    until File.exist?(File.join(@scratch, "hitl4.sock"))
      raise "socket never appeared" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.02
    end
    otp_client = Ace::Hitl::Lifecycle::Client.new(
      socket_path: File.join(@scratch, "hitl4.sock"), service_uid: Process.uid
    )
    otp_args = managed_args.transform_keys(&:to_s).merge(
      "kind" => "otp",
      "otp" => {operation: "gem-push", result_ref: "publisher-result",
                input_digest: "b" * 64, expires_at: Time.now.to_i + 600}
    )
    otp_client.create(**otp_args)

    # The answer arrives AFTER the consume starts: absence waits, and
    # the late delivery completes the hand-off (review 8x327bue).
    deliverer = Thread.new do
      sleep 0.4
      otp_client.deliver("hitl001", "654321")
    end
    consumed = otp_client.consume("hitl001", timeout: 5, operation: "gem-push")
    deliverer.join
    assert_equal "654321", consumed["answer"]
  ensure
    otp_service&.stop
    thread&.join(5)
    thread&.exit
  end

  def test_otp_challenge_deadline_and_operation_are_enforced_over_authenticated_ipc
    now = Time.now
    Time.stub(:now, -> { now }) do
      args = managed_args.transform_keys(&:to_s).merge("kind" => "otp", "otp" => otp_context(expires_in: 10))
      client.create(**args)
      client.deliver("hitl001", "654321")
      error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        client.consume("hitl001", timeout: 1, operation: "other-op")
      end
      refute_includes error.message, "654321"
      now += 9
      assert_equal "654321", client.consume("hitl001", timeout: 1, operation: "gem-push")["answer"]
      refute_includes JSON.generate(client.consume("hitl001", timeout: 1, operation: "gem-push")), "654321"

      args["id"] = "hitl002"
      args["otp"] = otp_context(expires_in: 10)
      client.create(**args)
      now += 9
      client.deliver("hitl002", "123456")
      now += 1
      2.times do
        error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
          client.consume("hitl002", timeout: 1, operation: "gem-push")
        end
        assert_match(/expired/, error.message)
        refute_includes error.message, "123456"
      end
      refute_equal "consumed", client.read("hitl002")["state"]
    end
  end

  def test_ended_attempt_cancels_the_request_through_the_boundary
    failing = LifecycleFixtures::TestBinding.new(
      on_validate: ->(**_kwargs) { nil },
      on_active: ->(**_kwargs) { raise Ace::Hitl::Lifecycle::EndedAttemptError, "HITL Attempt is no longer active" }
    )
    service = Ace::Hitl::Lifecycle::Service.new(
      root: File.join(@scratch, "store2"), binding: failing, policy: @policy,
      socket_path: File.join(@scratch, "hitl2.sock"), group: "staff"
    )
    thread = Thread.new { service.run }
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    until File.exist?(File.join(@scratch, "hitl2.sock"))
      raise "socket never appeared" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.02
    end
    second = Ace::Hitl::Lifecycle::Client.new(
      socket_path: File.join(@scratch, "hitl2.sock"), service_uid: Process.uid
    )

    # Validation passes at creation (on_validate is a no-op)...
    second.create(**managed_args.transform_keys(&:to_s))
    # ...and liveness re-verification cancels the request at deliver.
    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      second.deliver("hitl001", "approved")
    end
    assert_match(/no longer active/, error.message)
    states = second.states
    assert_equal "cancelled", states[0]["state"]
  ensure
    service&.stop
    thread&.join(5)
    thread&.exit
  end
end
