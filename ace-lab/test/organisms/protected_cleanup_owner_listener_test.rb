# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/organisms/protected_cleanup_owner"
require "delegate"

class ProtectedCleanupOwnerListenerTest < Minitest::Test
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

  private

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
