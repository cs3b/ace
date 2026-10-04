# frozen_string_literal: true

require "test_helper"
require "socket"
require "json"
require "timeout"
require "support/lifecycle_fixtures"

# The scoped store boundary (spec 8wq.t.34i): the REAL service and the
# REAL client talk over a REAL AF_UNIX socket in-process — classified
# errors cross the wire, roles are enforced from the (same-uid) peer
# identity, and idempotent terminals survive transport retries.
class ScopedServiceTest < AceHitlTestCase
  include LifecycleFixtures

  REQUESTER = "lab-asker"

  def setup
    @scratch = Dir.mktmpdir("ace-hitl-boundary", "/tmp")
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
    identity = File.lstat(@socket_path).then { |stat| [stat.dev, stat.ino] }
    error = assert_raises(Ace::Hitl::Lifecycle::TransportError) do
      second.run
    end
    assert_match(/already serving/, error.message)
    assert File.socket?(@socket_path), "refused startup removed the active endpoint"
    assert_equal identity, File.lstat(@socket_path).then { |stat| [stat.dev, stat.ino] }
    assert_equal true, client.ping["pong"]
    client.create(**managed_args.transform_keys(&:to_s))
    assert_equal "created", client.read("hitl001")["state"]
    client.deliver("hitl001", "approved")
    assert_equal "approved", client.consume("hitl001", timeout: 2)["answer"]
  end


  def extra_service(path, **options)
    Ace::Hitl::Lifecycle::Service.new(
      root: File.join(@scratch, "extra-store"), binding: @binding, policy: @policy,
      socket_path: path, group: "staff", **options
    )
  end

  def run_extra(service)
    ready = Queue.new
    service.instance_variable_set(:@logger, ->(message) { ready << true if message.include?("serving ") })
    thread = Thread.new { service.run }
    Timeout.timeout(5) { ready.pop }
    thread
  end

  def test_failed_start_preserves_regular_file_and_symlink_endpoints
    path = File.join(@scratch, "regular")
    File.write(path, "preserve me")
    assert_raises(Ace::Hitl::Lifecycle::TransportError) { extra_service(path).run }
    assert_equal "preserve me", File.read(path)
    link = File.join(@scratch, "link")
    File.symlink(path, link)
    assert_raises(Ace::Hitl::Lifecycle::TransportError) { extra_service(link).run }
    assert File.symlink?(link)
    assert_equal "preserve me", File.read(path)
  end

  def test_unprotected_stale_socket_and_lock_are_preserved
    path = File.join(@scratch, "unsafe-stale.sock")
    stale = UNIXServer.open(path)
    stale.close
    File.chmod(0o777, path)
    identity = File.lstat(path).ino
    assert_raises(Ace::Hitl::Lifecycle::TransportError) { extra_service(path).run }
    assert_equal identity, File.lstat(path).ino

    lock_path = File.join(@scratch, "unsafe-lock.sock")
    File.write("#{lock_path}.lock", "preserve lock")
    File.chmod(0o666, "#{lock_path}.lock")
    assert_raises(Ace::Hitl::Lifecycle::TransportError) { extra_service(lock_path).run }
    assert_equal "preserve lock", File.read("#{lock_path}.lock")
    refute File.exist?(lock_path)
  end

  def test_failed_directory_validation_does_not_remove_endpoint
    dir = File.join(@scratch, "unsafe")
    Dir.mkdir(dir, 0o777)
    File.chmod(0o777, dir)
    path = File.join(dir, "endpoint")
    File.write(path, "preserve me")
    assert_raises(Ace::Hitl::Lifecycle::TransportError) { extra_service(path).run }
    assert_equal "preserve me", File.read(path)
  end

  def test_failed_store_setup_releases_bound_socket_and_allows_restart
    path = File.join(@scratch, "setup.sock")
    service = extra_service(path)
    store = Object.new
    store.define_singleton_method(:ensure_layout!) { raise Errno::EACCES, "setup refused" }
    service.define_singleton_method(:root_store) { store }
    assert_raises(Ace::Hitl::Lifecycle::TransportError) { service.run }
    refute File.exist?(path)
    replacement = extra_service(path)
    thread = run_extra(replacement)
    assert_equal true, Ace::Hitl::Lifecycle::Client.new(socket_path: path, service_uid: Process.uid).ping["pong"]
  ensure
    replacement&.stop
    thread&.join(5)
  end

  def test_normal_stop_releases_socket_and_stale_socket_can_be_recovered
    path = File.join(@scratch, "stale.sock")
    stale = UNIXServer.open(path)
    stale.close
    service = extra_service(path)
    thread = run_extra(service)
    assert_equal true, Ace::Hitl::Lifecycle::Client.new(socket_path: path, service_uid: Process.uid).ping["pong"]
    service.stop
    thread.join(5)
    refute thread.alive?
    refute File.exist?(path)
    replacement = extra_service(path)
    next_thread = run_extra(replacement)
    assert_equal true, Ace::Hitl::Lifecycle::Client.new(socket_path: path, service_uid: Process.uid).ping["pong"]
  ensure
    service&.stop
    thread&.join(5)
    replacement&.stop
    next_thread&.join(5)
  end

  def test_shutdown_preserves_a_replacement_listener
    path = File.join(@scratch, "replace.sock")
    service = extra_service(path)
    thread = run_extra(service)
    File.unlink(path)
    replacement = UNIXServer.open(path)
    identity = File.lstat(path).then { |stat| [stat.dev, stat.ino] }
    service.stop
    thread.join(5)
    assert_equal identity, File.lstat(path).then { |stat| [stat.dev, stat.ino] }
    peer = UNIXSocket.open(path)
    accepted = replacement.accept
    peer.write("reachable")
    assert_equal "reachable", accepted.read(9)
  ensure
    service&.stop
    thread&.join(5)
    peer&.close
    accepted&.close
    replacement&.close
  end

  def test_concurrent_public_starts_have_one_reachable_winner
    path = File.join(@scratch, "race.sock")
    arrived = Queue.new
    release = Queue.new
    ready = Queue.new
    outcomes = Queue.new
    services = 2.times.map do
      service = extra_service(path, logger: ->(message) { ready << service if message.include?("serving ") })
      service.define_singleton_method(:acquire_endpoint_lock!) do
        arrived << true
        release.pop
        super()
      end
      service
    end
    threads = services.map do |service|
      Thread.new do
        service.run
      rescue Ace::Hitl::Lifecycle::TransportError => error
        outcomes << error
      end
    end
    Timeout.timeout(5) { 2.times { arrived.pop } }
    2.times { release << true }
    winner = Timeout.timeout(5) { ready.pop }
    error = Timeout.timeout(5) { outcomes.pop }
    assert_match(/already serving/, error.message)
    assert ready.empty?, "more than one startup succeeded"
    assert_equal true, Ace::Hitl::Lifecycle::Client.new(socket_path: path, service_uid: Process.uid).ping["pong"]
    winner.stop
    threads.each { |thread| thread.join(5) }
    refute File.exist?(path)
  ensure
    services&.each(&:stop)
    threads&.each { |thread| thread.join(5) }
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
