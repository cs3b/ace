# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/organisms/protected_cleanup_owner"
require "delegate"

class ProtectedCleanupOwnerListenerTest < Minitest::Test
  def test_failed_publication_removes_only_original_socket_and_allows_restart
    with_endpoint do |path|
      owner = socket = thread = replacement = nil
      observer = Object.new
      observer.define_singleton_method(:observe_self!) { |**_| {"controlled" => "original root"} }
      admission = Object.new
      admission.define_singleton_method(:connection_group!) { |_| true }
      admission.define_singleton_method(:identity_reader!) { |_| true }
      kernel = Object.new
      kernel.define_singleton_method(:peer) { |_| {} }
      build = lambda do
        Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
          snapshots: Object.new, journals: Object.new, kernel: kernel, installer: Object.new,
          scratch_root: @scratch, protection: controlled_protection)
      end
      wire = Ace::Runtime::Molecules::ProtectedSocket
      wire.stub(:root_path!, ->(*_, **_) { true }) do
        original_chmod = File.method(:chmod)
        fail_publication = lambda do |mode, selected|
          raise Errno::EIO, "controlled publication failure" if selected == path
          original_chmod.call(mode, selected)
        end
        File.stub(:chmod, fail_publication) do
          assert_raises(Errno::EIO) { build.call.serve(connect_gid: Process.gid) }
        end
        refute File.exist?(path), "unpublished original socket must not block a new owner"
        File.open("#{path}.lock", File::RDWR) { |lock| assert lock.flock(File::LOCK_EX | File::LOCK_NB) }
        ready = Queue.new
        original_server = UNIXServer.method(:new)
        owner = build.call
        UNIXServer.stub(:new, ->(selected) { original_server.call(selected).tap { ready << true } }) do
          thread = Thread.new { owner.serve(connect_gid: Process.gid) }
          Timeout.timeout(5) { ready.pop }
          socket = UNIXSocket.new(path)
          wire.write(socket, {"schema" => Ace::Lab::Molecules::ProtectedCleanupOwnerClient::SCHEMA, "kind" => "identity"}, deadline: wire.deadline(5))
          socket.shutdown(Socket::SHUT_WR)
          assert_equal "original root", wire.read(socket, deadline: wire.deadline(5)).dig("operation_owner_binding", "controlled")
          socket.close
          owner.stop
          assert thread.join(6)
          thread.value
        end
        # A replacement during failed publication is not ours to remove.
        replace_then_fail = lambda do |mode, selected|
          next original_chmod.call(mode, selected) unless selected == path
          File.unlink(path)
          replacement = original_server.call(path)
          raise Errno::EIO, "controlled replacement before failure"
        end
        File.stub(:chmod, replace_then_fail) do
          assert_raises(Errno::EIO) { build.call.serve(connect_gid: Process.gid) }
        end
        assert File.socket?(path), "failed publication must preserve replacement endpoint"
      end
    ensure
      owner&.stop
      socket&.close unless socket&.closed?
      thread&.join(6)
      replacement&.close
    end
  end

  def test_fixed_listener_identity_and_lifetime_lock_preserve_replacement_endpoint
    with_endpoint do |path|
      ready = Queue.new
      observer = Object.new
      binding = {"controlled" => "original root"}
      observer.define_singleton_method(:observe_self!) { |deadline:| binding }
      admission = Object.new
      admission.define_singleton_method(:connection_group!) { |gid| raise "wrong installed group" unless gid == Process.gid }
      admission.define_singleton_method(:identity_reader!) { |_| true }
      kernel = Object.new
      kernel.define_singleton_method(:peer) { |_| {"controlled" => "installed authority"} }
      owner = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
        snapshots: ->(&_) { raise "identity must not read journal" }, journals: ->(_) { raise "no journal" },
        kernel: kernel, installer: Object.new, scratch_root: @scratch, protection: controlled_protection)
      original_server = UNIXServer.method(:new)
      publish = ->(selected) { server = original_server.call(selected); ready << true; server }
      wire = Ace::Runtime::Molecules::ProtectedSocket
      protected_parent = lambda do |selected, directory:|
        assert_equal File.dirname(path), selected
        assert directory
      end
      thread = nil
      wire.stub(:root_path!, protected_parent) do
        UNIXServer.stub(:new, publish) do
          thread = Thread.new { owner.serve(connect_gid: Process.gid) }
          Timeout.timeout(5) { ready.pop }
          socket = UNIXSocket.new(path)
          wire.write(socket, {"schema" => Ace::Lab::Molecules::ProtectedCleanupOwnerClient::SCHEMA, "kind" => "identity"}, deadline: wire.deadline(5))
          socket.shutdown(Socket::SHUT_WR)
          reply = wire.read(socket, deadline: wire.deadline(5))
          assert_equal binding, reply.fetch("operation_owner_binding")
          socket.close
          lock = File.open("#{path}.lock", File::RDWR)
          refute lock.flock(File::LOCK_EX | File::LOCK_NB), "original listener retains lifetime exclusion"
          File.unlink(path)
          replacement = original_server.call(path)
          replacement_identity = File.lstat(path).ino
          owner.stop
          thread.value
          assert_equal replacement_identity, File.lstat(path).ino, "teardown cannot unlink a replacement"
          assert lock.flock(File::LOCK_EX | File::LOCK_NB)
          lock.close
          replacement.close
        end
      end
    ensure
      owner&.stop
      thread&.join(6)
    end
  end

  def test_original_accepted_time_is_not_renewed_at_handler_entry
    with_endpoint do |path|
      observer = Object.new
      observer.define_singleton_method(:observe_self!) { |**_| raise "expired input must not observe identity" }
      kernel = Object.new
      kernel.define_singleton_method(:peer) { |_| {} }
      owner = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: Object.new,
        snapshots: Object.new, journals: Object.new, kernel: kernel, installer: Object.new, scratch_root: @scratch, protection: controlled_protection)
      reader, writer = Socket.pair(:UNIX, :STREAM, 0)
      assert_raises(Ace::Runtime::RuntimeUnavailableError) do
        owner.handle(reader, accepted_at: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 6)
      end
      assert reader.closed?
      writer.close
    end
  end

  def test_held_lock_protection_refusal_preserves_stale_endpoint
    with_endpoint do |path|
      stale = UNIXServer.new(path)
      File.chmod(0o660, path)
      inode = File.lstat(path).ino
      observer = Object.new
      observer.define_singleton_method(:observe_self!) { |**_| {} }
      admission = Object.new
      admission.define_singleton_method(:connection_group!) { |_| true }
      inspected = []
      protection = Object.new
      protection.define_singleton_method(:verify!) do |selected, handle, directory:|
        inspected << [selected, directory, handle.stat.file?]
        raise Ace::Runtime::RuntimeUnavailableError, "controlled unsafe lock protection" if selected == "#{path}.lock"
      end
      owner = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
        snapshots: Object.new, journals: Object.new, kernel: Object.new, installer: Object.new,
        scratch_root: @scratch, protection: protection)
      Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, ->(*_, **_) { true }) do
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { owner.serve(connect_gid: Process.gid) }
      end
      assert_includes inspected, ["#{path}.lock", false, true]
      assert_equal inode, File.lstat(path).ino, "unsafe held lock must refuse before stale endpoint removal"
      lock = File.open("#{path}.lock", File::RDWR)
      assert lock.flock(File::LOCK_EX | File::LOCK_NB)
      lock.close
      stale.close
    ensure
      stale&.close unless stale&.closed?
    end
  end

  def test_finite_capacity_and_shutdown_retain_lock_until_original_handlers_finish
    with_endpoint do |path|
      ready, entered, release = Queue.new, Queue.new, Queue.new
      observer = Object.new
      observer.define_singleton_method(:observe_self!) { |deadline:| {"controlled" => "original root"} }
      admission = Object.new
      admission.define_singleton_method(:connection_group!) { |gid| raise "wrong group" unless gid == Process.gid }
      admission.define_singleton_method(:identity_reader!) { |_| true }
      kernel = Object.new
      kernel.define_singleton_method(:peer) { |_| {} }
      owner = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
        snapshots: Object.new, journals: Object.new, kernel: kernel, installer: Object.new, scratch_root: @scratch, protection: controlled_protection)
      actual_handle = owner.method(:handle)
      owner.define_singleton_method(:handle) do |socket, accepted_at:|
        entered << accepted_at
        release.pop
        actual_handle.call(socket, accepted_at: accepted_at)
      end
      server = UNIXServer.method(:new)
      publish = ->(selected) { listener = server.call(selected); ready << true; listener }
      wire = Ace::Runtime::Molecules::ProtectedSocket
      clients = []
      thread = nil
      wire.stub(:root_path!, ->(*_, **_) { true }) do
        UNIXServer.stub(:new, publish) do
          thread = Thread.new { owner.serve(connect_gid: Process.gid) }
          Timeout.timeout(5) { ready.pop }
          Ace::Lab::Organisms::ProtectedCleanupOwner::MAX_CONNECTIONS.times do
            socket = UNIXSocket.new(path)
            clients << socket
            wire.write(socket, {"schema" => Ace::Lab::Molecules::ProtectedCleanupOwnerClient::SCHEMA, "kind" => "identity"}, deadline: wire.deadline(5))
            socket.shutdown(Socket::SHUT_WR)
          end
          timestamps = Timeout.timeout(5) { clients.map { entered.pop } }
          assert_equal 16, timestamps.size
          assert timestamps.all? { |time| time.is_a?(Float) && time <= Process.clock_gettime(Process::CLOCK_MONOTONIC) }
          extra = UNIXSocket.new(path)
          assert_equal "", Timeout.timeout(5) { extra.read }, "capacity refusal creates no additional handler"
          extra.close
          owner.stop
          lock = File.open("#{path}.lock", File::RDWR)
          refute lock.flock(File::LOCK_EX | File::LOCK_NB), "stop cannot release lifetime while handlers remain"
          clients.size.times { release << true }
          assert thread.join(6), "bounded original handlers must finish"
          thread.value
          assert lock.flock(File::LOCK_EX | File::LOCK_NB)
          refute File.exist?(path)
          lock.close
        end
      end
    ensure
      clients&.each { |socket| socket.close unless socket.closed? }
      16.times { release << true } if release
      owner&.stop
      thread&.join(6)
    end
  end

  def test_raised_callback_is_consumed_and_actual_inspector_still_must_prove_no_effect
    with_endpoint do
      original_error = Errno::EIO.new("controlled pre-fence callback failure")
      invocations, inspections = [], []
      installer = Object.new
      installer.define_singleton_method(:execute_cleanup!) { |**arguments| invocations << arguments; raise original_error }
      installer.define_singleton_method(:inspect_cleanup!) do |**arguments|
        inspections << arguments
        raise SecurityError, "domain proof unavailable: unknown child or partial capture"
      end
      owner, context, binding, frame = invocation_fixture(installer)
      assert_same original_error, dispatch_error(owner, frame)
      retained = owner.instance_variable_get(:@consumed).fetch("request")
      assert_equal :unconfirmed, retained.fetch(:state)
      assert retained.fetch(:inhibited)
      refute retained.key?(:result)
      assert_instance_of Ace::Runtime::RuntimeUnavailableError, dispatch_error(owner, frame)
      assert_equal 1, invocations.size, "same original execute must never reissue"
      error = inspection_error(owner, frame, context, binding)
      assert_instance_of SecurityError, error
      assert_includes error.message, "domain proof unavailable"
      assert_equal 1, inspections.size
      assert_equal 0, inspections.first.fetch(:context).fetch("input_inhibition").fetch("pending_effects")
      assert_equal :unconfirmed, retained.fetch(:state), "inspector refusal cannot settle the outcome"
      refute retained.key?(:result)
    end
  end

  def test_concurrent_inspection_waits_for_callback_ensure_to_actually_unwind
    with_endpoint do
      unwinding, release, waiting, inspected = Queue.new, Queue.new, Queue.new, Queue.new
      original_error = IOError.new("controlled callback error")
      installer = Object.new
      installer.define_singleton_method(:execute_cleanup!) do |**_|
        begin
          raise original_error
        ensure
          unwinding << true
          release.pop
        end
      end
      installer.define_singleton_method(:inspect_cleanup!) do |**_|
        inspected << true
        raise SecurityError, "actual inspector refuses unproven no-effect"
      end
      owner, context, binding, frame = invocation_fixture(installer)
      changed = owner.instance_variable_get(:@changed)
      real_wait = changed.method(:wait)
      changed.define_singleton_method(:wait) { |*arguments| waiting << true; real_wait.call(*arguments) }
      effect = Thread.new { dispatch_error(owner, frame) }
      Timeout.timeout(2) { unwinding.pop }
      inspection = Thread.new { inspection_error(owner, frame, context, binding, seconds: 2) }
      Timeout.timeout(2) { waiting.pop }
      assert inspected.empty?, "exception raised is not callback unwind"
      assert_equal :invoked, owner.instance_variable_get(:@consumed).fetch("request").fetch(:state)
      release << true
      assert effect.join(2)
      assert_same original_error, effect.value
      assert inspection.join(2)
      assert_instance_of SecurityError, inspection.value
      assert_equal 1, inspected.size
      assert_equal :unconfirmed, owner.instance_variable_get(:@consumed).fetch("request").fetch(:state)
    ensure
      release << true if release
      effect&.join(2)
      inspection&.join(2)
    end
  end

  def test_unconfirmed_ended_callback_shutdown_reports_error_without_settlement
    with_endpoint do |path|
      inspections = 0
      installer = Object.new
      installer.define_singleton_method(:execute_cleanup!) { |**_| raise IOError, "controlled unconfirmed invocation" }
      installer.define_singleton_method(:inspect_cleanup!) { |**_| inspections += 1; raise "shutdown cannot inspect or settle" }
      owner, _, _, frame = invocation_fixture(installer)
      assert_instance_of IOError, dispatch_error(owner, frame)
      server = UNIXServer.method(:new)
      ready = Queue.new
      thread = nil
      Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, ->(*_, **_) { true }) do
        UNIXServer.stub(:new, ->(selected) { server.call(selected).tap { ready << true } }) do
          thread = Thread.new do
            begin
              owner.serve(connect_gid: Process.gid)
            rescue Exception => error
              error
            end
          end
          Timeout.timeout(2) { ready.pop }
          owner.stop
          assert thread.join(2), "ended callback must not become an indefinite shutdown wait"
          assert_instance_of Ace::Runtime::RuntimeUnavailableError, thread.value
          assert_includes thread.value.message, "unconfirmed after callback termination"
          File.open("#{path}.lock", File::RDWR) { |lock| assert lock.flock(File::LOCK_EX | File::LOCK_NB) }
          assert_equal 0, inspections
          refute File.exist?(path)
          retained = owner.instance_variable_get(:@consumed).fetch("request")
          assert_equal :unconfirmed, retained.fetch(:state)
          refute retained.key?(:result)
        end
      end
    ensure
      owner&.stop
      thread&.join(2)
    end
  end

  private

  # Invocation-state unit boundary: real wire and callback synchronization,
  # controlled canonical admission/snapshot and domain proof. No grant claimed.
  def invocation_fixture(installer)
    binding = {"controlled" => "same original root"}
    context = {"record" => {"request_id" => "request", "operation_owner_binding" => binding}}
    observer = Object.new
    observer.define_singleton_method(:observe_self!) { |**_| binding }
    admission = Object.new
    admission.define_singleton_method(:receiver!) { |_| true }
    admission.define_singleton_method(:connection_group!) { |_| true }
    admission.define_singleton_method(:admit!) { |**_| context }
    snapshot = Object.new
    snapshot.define_singleton_method(:with) { |deadline:, &block| block.call(:controlled_view) }
    kernel = Object.new
    kernel.define_singleton_method(:peer) { |_| {"controlled" => "actual ingress receiver"} }
    owner = Ace::Lab::Organisms::ProtectedCleanupOwner.new(observer: observer, admission: admission,
      snapshots: ->(&block) { block.call(snapshot) }, journals: ->(_) { Object.new }, kernel: kernel,
      installer: installer, scratch_root: @scratch, protection: controlled_protection)
    frame = {"schema" => Ace::Lab::Molecules::ProtectedCleanupOwnerClient::SCHEMA, "kind" => "execute",
      "request_id" => "request", "input_digest" => "a" * 64, "dispatch_event_digest" => "b" * 64,
      "operation_owner_binding_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(binding)}
    [owner, context, binding, frame]
  end

  def dispatch_error(owner, frame)
    server, client = UNIXSocket.pair
    wire = Ace::Runtime::Molecules::ProtectedSocket
    wire.write(client, frame, deadline: wire.deadline(2))
    client.shutdown(Socket::SHUT_WR)
    owner.handle(server)
    flunk "unconfirmed invocation cannot emit success"
  rescue Exception => error
    error
  ensure
    server&.close unless server&.closed?
    client&.close unless client&.closed?
  end

  def inspection_error(owner, frame, context, binding, seconds: 0.2)
    server, client = UNIXSocket.pair
    owner.send(:inspection, server, frame.merge("kind" => "inspect", "challenge_ref" => {}), context, binding,
      Ace::Runtime::Molecules::ProtectedSocket.deadline(seconds), receiver_peer: {"controlled" => "fresh receiver"})
    flunk "unproved inspection cannot emit a result"
  rescue Exception => error
    error
  ensure
    server&.close unless server&.closed?
    client&.close unless client&.closed?
  end

  def controlled_protection
    Object.new.tap { |protection| protection.define_singleton_method(:verify!) { |*_, **_| true } }
  end

  # Only the installed endpoint/OS protection observation is injected. Actual
  # listener, socket, flock, mode, deadline and inode teardown remain exercised.
  def with_endpoint
    Dir.mktmpdir("cleanup-listener-", File.realpath(File.join(Dir.home, ".cache"))) do |root|
      @scratch = root
      Dir.mktmpdir("co-", "/tmp") do |directory|
      File.chmod(0o2750, directory)
      client = Ace::Lab::Molecules::ProtectedCleanupOwnerClient
      original = client::PATH
      client.send(:remove_const, :PATH)
      directory = File.realpath(directory)
      client.const_set(:PATH, File.join(directory, "owner.sock"))
      selected = client::PATH
      original_stat = File.method(:lstat)
      normalize_stat = lambda do |stat, path|
        if path == directory || path == selected
          proxy = SimpleDelegator.new(stat)
          proxy.define_singleton_method(:gid) { Process.gid }
          proxy.define_singleton_method(:mode) { stat.mode | 0o2000 } if path == directory
          proxy
        else
          stat
        end
      end
      boundary_stat = ->(path) { normalize_stat.call(original_stat.call(path), path) }
      original_open = File.method(:open)
      boundary_open = lambda do |path, *args, **options|
        handle = original_open.call(path, *args, **options)
        if path == directory
          proxy = SimpleDelegator.new(handle)
          proxy.define_singleton_method(:stat) { normalize_stat.call(handle.stat, path) }
          proxy
        else
          handle
        end
      end
      File.stub(:lstat, boundary_stat) { File.stub(:open, boundary_open) { yield selected } }
    ensure
      client.send(:remove_const, :PATH)
      client.const_set(:PATH, original)
      end
    end
  end
end
