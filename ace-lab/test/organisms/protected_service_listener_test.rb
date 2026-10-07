# frozen_string_literal: true

require_relative "../support/protected_service_boundary_fixture"
require "ace/lab/organisms/protected_service_client"

class ProtectedServiceListenerTest < Minitest::Test
  include ProtectedServiceBoundaryFixture

  def test_actual_listener_short_claim_and_owned_worker_use_canonical_service_pipeline
    fixture do
      submission, bytes = prepared_submission
      @executor["groups"] = [13001, 13005]
      @project.fetch("peer_credentials").fetch("13005")["groups"] = @executor.fetch("groups")
      client = start_service_server
      accepted, release, invocations = Queue.new, Queue.new, Queue.new
      delegate = controlled_handler(invocations)
      handler = Object.new
      handler.define_singleton_method(:execute) do |**arguments|
        accepted << true
        release.pop
        delegate.execute(**arguments)
      end
      kernel = Object.new
      worker_identity = @worker
      executor_identity = @executor
      kernel.define_singleton_method(:peer) { |_| worker_identity }
      kernel.define_singleton_method(:capture) { |_| executor_identity }
      kernel.define_singleton_method(:live!) { |_| true }
      wire = Module.new
      real_wire = Ace::Runtime::Molecules::ProtectedSocket
      %i[deadline read write connect].each { |name| wire.define_singleton_method(name) { |*args, **options, &block| real_wire.public_send(name, *args, **options, &block) } }
      ready = Queue.new
      path = File.join(@root, "receiver.sock")
      @project.fetch("service_receivers").fetch("executor")["socket_path"] = path
      wire.define_singleton_method(:socket_identity) do |socket_path|
        stat = File.lstat(socket_path)
        raise "not the selected temporary socket" unless socket_path == path && stat.socket?
        ready << true
        [stat.dev, stat.ino, executor_identity.fetch("uid")]
      end
      wire.define_singleton_method(:root_path!) { |actual, directory:, owner:| raise "wrong protected selection" unless actual == File.dirname(path) && directory && owner == executor_identity.fetch("uid") }
      installed_receiver = receiver(client, handler)
      @listener = Ace::Lab::Organisms::ProtectedServiceListener.new(mapping_id: "mapping", service_id: "executor",
        deployment: @deployment, kernel: kernel, receiver: installed_receiver, wire: wire)
      caller = Object.new
      caller.define_singleton_method(:capture) { |_| worker_identity }
      caller.define_singleton_method(:peer) { |_| executor_identity }
      @project.fetch("peer_credentials")[@worker.fetch("uid").to_s] = @worker.slice("gid", "groups").merge("scratch_root" => @root)
      ingress = Ace::Lab::Organisms::ProtectedServiceClient.new(mapping_id: "mapping", service_id: "executor",
        deployment: @deployment, kernel: caller, wire: wire)
      original_chown = File.method(:chown)
      socket_chown = lambda do |uid, gid, *paths|
        if paths == [path]
          assert_nil uid
          assert_equal @map.fetch("worker_gid"), gid
          original_chown.call(nil, Process.gid, path)
        else
          original_chown.call(uid, gid, *paths)
        end
      end
      owner = nil
      Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, @document) do
        File.stub(:chown, socket_chown) do
        owner = Thread.new { @listener.serve }
        Timeout.timeout(5) { ready.pop }
        descriptor = Ace::Assign::Authority::TransferCodec.new(root: @root).descriptor([bytes], purpose: :service_input)
        frame = {"version" => 1, "submission" => submission, "mutation_id" => "raw-original", "transfer" => descriptor}
        before = @journal.ref_value
        malformed = [JSON.generate(frame.merge("version" => 1.0)),
          JSON.generate(frame.merge("transfer" => descriptor.merge("version" => 1.0))),
          JSON.generate(frame).sub('"version":1', '"version":1,"version":1')]
        malformed.each do |raw|
          real_wire.connect(path, deadline: real_wire.deadline(5)) do |socket|
            socket.write(raw + "\n")
            socket.shutdown(Socket::SHUT_WR)
            assert_equal "unavailable", real_wire.read(socket, deadline: real_wire.deadline(5)).fetch("code")
          end
          assert_equal before, @journal.ref_value, "malformed control cannot claim"
        end
        real_wire.connect(path, deadline: real_wire.deadline(5)) do |socket|
          socket.write(JSON.generate(frame) + "\n" + bytes + "trailing")
          socket.shutdown(Socket::SHUT_WR)
          assert_equal "unavailable", real_wire.read(socket, deadline: real_wire.deadline(5)).fetch("code")
        end
        assert_equal before, @journal.ref_value, "trailing input cannot claim"
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        real_wire.connect(path, deadline: real_wire.deadline(10)) do |socket|
          socket.write(JSON.generate(frame) + "\n")
          # Keep write-half open with declared bytes absent: bounded input wait
          # must expire under the original5s budget, without a sleep or resend.
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { real_wire.read(socket, deadline: real_wire.deadline(10)) }
        end
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
        assert_operator elapsed, :>=, 4.5
        assert_operator elapsed, :<, 8
        assert_equal before, @journal.ref_value, "expired intake cannot claim"
        reply = ingress.submit(submission: submission, input_bytes: bytes, mutation_id: "listener-original")
        assert_equal "service_claim_accepted", reply.fetch("type")
        assert_equal "service-request", reply.fetch("data").fetch("request_id")
        prefix = @journal.read_events("assignment", commit: reply.fetch("data").fetch("journal_commit"))
        assert_equal 1, prefix.count { |event| event["type"] == "service_claim" }
        Timeout.timeout(60) { accepted.pop }
        before = @journal.ref_value
        busy = ingress.submit(submission: submission.merge("request_id" => "another-request"), input_bytes: bytes, mutation_id: "listener-busy")
        assert_equal "busy", busy.fetch("code")
        assert_equal before, @journal.ref_value
        @listener.stop
        assert owner.alive?, "listener lifetime remains held through admitted worker"
        second = Ace::Lab::Organisms::ProtectedServiceListener.new(mapping_id: "mapping", service_id: "executor",
          deployment: @deployment, kernel: kernel, receiver: installed_receiver, wire: wire)
        assert_raises(Ace::Assign::AttemptErrors::Conflict) { second.serve }
        assert File.socket?(path), "second listener cannot remove original endpoint"
        release << true
        assert owner.join(60), "original listener finishes only after its worker"
        assert_nil owner.value
        assert_equal "succeeded", @journal.service_request("service-request").fetch("state")
        assert_equal 1, invocations.size
        refute File.exist?(path)
        ready.clear
        @listener = Ace::Lab::Organisms::ProtectedServiceListener.new(mapping_id: "mapping", service_id: "executor",
          deployment: @deployment, kernel: kernel, receiver: receiver(client, handler), wire: wire)
        owner = Thread.new { @listener.serve }
        Timeout.timeout(5) { ready.pop }
        before = @journal.ref_value
        replay = ingress.submit(submission: submission, input_bytes: bytes, mutation_id: "listener-original")
        assert_equal "service_claim_accepted", replay.fetch("type")
        assert replay.fetch("data").fetch("replayed")
        assert_equal "retained", replay.fetch("data").fetch("claim")
        assert_equal "succeeded", replay.fetch("data").fetch("state")
        assert_equal before, @journal.ref_value
        assert_equal 1, invocations.size, "fresh listener observes canonical replay without second handler"
        @listener.stop
        assert owner.join(5)
        end
      end
    ensure
      release << true if release
      @listener&.stop
      assert owner.join(60), "owned listener must terminate" if owner
    end
  end

  def test_receiver_ingress_rejects_ancillary_descriptors_before_json
    left, right = UNIXSocket.pair
    Tempfile.create("receiver-ancillary") do |file|
      left.sendmsg("x", 0, nil, Socket::AncillaryData.unix_rights(file))
      guarded = Ace::Lab::Organisms::ProtectedServiceListener::Ingress.new(right)
      assert_raises(SecurityError) { guarded.read_nonblock(1) }
      refute file.closed?, "sender retains its own descriptor"
    end
  ensure
    left&.close
    right&.close
  end
end
