# frozen_string_literal: true

require "ace/runtime/molecules/protected_socket"
require "ace/runtime/molecules/protected_artifact_set"
require "ace/assign/authority/transfer_codec"
require_relative "../molecules/protected_cleanup_owner_admission"

module Ace
  module Lab
    module Organisms
      # The immutable direct root entry supplies all collaborators. Durable
      # request/outcome authority stays in its original canonical journal and
      # Installer's retained physical result, never this transport owner.
      class ProtectedCleanupOwner
        Wire = Ace::Runtime::Molecules::ProtectedSocket
        Client = Molecules::ProtectedCleanupOwnerClient
        MAX_RETAINED = 256
        MAX_CONNECTIONS = 16

        def initialize(observer:, admission:, snapshots:, journals:, kernel:, installer:, scratch_root:,
          protection: Ace::Runtime::Molecules::ProtectedArtifactSet::Protection.new)
          @observer, @admission, @snapshots, @journals = observer, admission, snapshots, journals
          @kernel, @installer = kernel, installer
          @protection = protection
          @codec = Ace::Assign::Authority::TransferCodec.new(root: scratch_root)
          @lock, @consumed = Mutex.new, {}
          @connections, @changed = [], ConditionVariable.new
          @stopping = false
        end

        # Only the trusted fixed entry supplies the installed connection group.
        # Endpoint and lock paths remain source constants, never request inputs.
        def serve(connect_gid:)
          @admission.connection_group!(connect_gid)
          @observer.observe_self!(deadline: Wire.deadline(5))
          path = Client::PATH
          parent = File.dirname(path)
          Wire.root_path!(parent, directory: true)
          parents = hold_parent!(parent)
          parent_stat = File.lstat(parent)
          unless parent_stat.directory? && parent_stat.uid == Process.uid && parent_stat.gid == connect_gid && (parent_stat.mode & 0o7777) == 0o2750
            raise SecurityError, "cleanup listener parent differs"
          end
          parent_identity = [parent_stat.dev, parent_stat.ino]
          lifetime = File.open("#{path}.lock", File::RDWR | File::CREAT | File::NOFOLLOW | File::NONBLOCK, 0o600)
          lifetime.close_on_exec = true
          stat = lifetime.stat
          unless stat.file? && stat.uid == Process.uid && stat.nlink == 1 && (stat.mode & 0o7777) == 0o600
            raise SecurityError, "cleanup lifetime lock differs"
          end
          @protection.verify!("#{path}.lock", lifetime, directory: false)
          raise SecurityError, "cleanup lifetime lock path changed" unless file_identity(File.lstat("#{path}.lock")) == file_identity(lifetime.stat)
          raise Ace::Runtime::RuntimeUnavailableError, "cleanup listener already active" unless lifetime.flock(File::LOCK_EX | File::LOCK_NB)
          raise SecurityError, "cleanup lifetime lock path changed after flock" unless file_identity(File.lstat("#{path}.lock")) == file_identity(lifetime.stat)
          verify_parents!(parents)
          begin
            stale = File.lstat(path)
            unless stale.socket? && stale.uid == Process.uid && stale.gid == connect_gid && (stale.mode & 0o7777) == 0o660
              raise SecurityError, "cleanup stale endpoint differs"
            end
            File.unlink(path)
          rescue Errno::ENOENT
            nil
          end
          @listener = UNIXServer.new(path)
          @listener.close_on_exec = true
          File.chmod(0o660, path)
          own = File.lstat(path)
          unless own.socket? && (own.mode & 0o7777) == 0o660 && own.uid == Process.uid && own.gid == connect_gid && [File.lstat(parent).dev, File.lstat(parent).ino] == parent_identity
            raise SecurityError, "cleanup endpoint publication differs"
          end
          endpoint = [own.dev, own.ino, own.uid, own.gid]
          until @stopping
            socket = @listener.accept
            accepted_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            socket.close_on_exec = true
            admitted = @lock.synchronize do
              @connections.reject! { |thread| !thread.alive? }
              if @connections.size >= MAX_CONNECTIONS
                false
              else
                worker = Thread.new(socket, accepted_at) do |owned_socket, original_acceptance|
                  begin
                    verify_parents!(parents)
                    current = File.lstat(path)
                    unless current.socket? && (current.mode & 0o7777) == 0o660 && [current.dev, current.ino, current.uid, current.gid] == endpoint
                      raise SecurityError, "cleanup endpoint changed"
                    end
                    handle(owned_socket, accepted_at: original_acceptance)
                  rescue SecurityError, Ace::Runtime::RuntimeUnavailableError, Ace::Assign::Error, IOError, SystemCallError => error
                    # Refusal/transport failure closes only this connection.
                    # Its consumed state, including uncertainty, is preserved.
                    code = error.is_a?(SecurityError) ? "unauthorized_or_changed_selection" : "unavailable"
                    warn("cleanup connection refused: #{code}")
                  ensure
                    owned_socket.close unless owned_socket.closed?
                    @lock.synchronize { @changed.broadcast }
                  end
                end
                @connections << worker
                true
              end
            end
            socket.close unless admitted
          end
        rescue IOError, Errno::EBADF
          raise unless @stopping
        ensure
          @listener.close if @listener && !@listener.closed?
          @lock.synchronize do
            # An exceptional effect is unconfirmed even after its Ruby thread
            # exits. Keep the lifetime exclusion until actual recovery settles it.
            while @connections.any?(&:alive?) || @consumed.values.any? { |entry| entry[:state] == :invoked }
              @changed.wait(@lock, 0.1)
            end
          end
          if endpoint
            begin
              verify_parents!(parents)
              current = File.lstat(path)
              File.unlink(path) if current.socket? && (current.mode & 0o7777) == 0o660 && [current.dev, current.ino, current.uid, current.gid] == endpoint
            rescue Errno::ENOENT
              nil
            end
          end
          lifetime&.close
          parents&.each { |entry| entry.fetch(:handle).close }
        end

        def stop
          @stopping = true
          @listener.close if @listener && !@listener.closed?
        end

        # Listener construction and fixed socket ownership are separately
        # provisioned; every accepted connection still authenticates its peer.
        def handle(socket, accepted_at: Process.clock_gettime(Process::CLOCK_MONOTONIC))
          admission_deadline = accepted_at + 5
          peer = @kernel.peer(socket)
          frame = Wire.read(Wire::Ingress.new(socket), deadline: admission_deadline, limit: 65_536)
          eof!(socket, admission_deadline)
          original = @observer.observe_self!(deadline: admission_deadline)
          if frame == {"schema" => Client::SCHEMA, "kind" => "identity"}
            @admission.identity_reader!(peer)
            Wire.write(socket, {"schema" => Client::SCHEMA, "kind" => "identity", "operation_owner_binding" => original},
              deadline: admission_deadline, limit: Client::LIMIT)
            return
          end
          @admission.receiver!(peer)
          deadline = accepted_at + 300
          context = nil
          @snapshots.call do |snapshot|
            snapshot.with(deadline: deadline) do |view|
              context = if frame["kind"] == "inspect"
                @admission.inspect!(frame: frame, peer: peer, operation_owner_binding: original, journal: @journals.call(view))
              else
                @admission.admit!(frame: frame, peer: peer, operation_owner_binding: original, journal: @journals.call(view))
              end
            end
          end
          if frame["kind"] == "inspect"
            inspection(socket, frame, context, original, deadline)
            return
          end
          key = Ace::Assign::Atoms::EvidenceDigest.digest(frame)
          retained = @lock.synchronize do
            if (entry = @consumed[context.fetch("record").fetch("request_id")])
              raise SecurityError, "cleanup original invocation input differs" unless entry.fetch(:key) == key
              entry
            else
              raise Ace::Runtime::RuntimeUnavailableError, "cleanup lifetime capacity unavailable" if @consumed.size >= MAX_RETAINED
              @consumed[context.fetch("record").fetch("request_id")] = {key: key, state: :invoking}
            end
          end
          result = @lock.synchronize { retained[:result] }
          unless result
            authorized = @lock.synchronize do
              next false unless retained[:state] == :invoking && !retained[:inhibited]
              retained[:state] = :invoked
              true
            end
            raise Ace::Runtime::RuntimeUnavailableError, "cleanup original result unavailable" unless authorized
            # No canonical/source lock is held over fixed privileged work.
            unless @observer.observe_self!(deadline: [deadline, Wire.deadline(5)].min) == original
              raise SecurityError, "cleanup original owner changed before invocation"
            end
            result = @installer.execute_cleanup!(context: context, deadline: deadline)
            result = result!(result, frame)
            @lock.synchronize { retained[:result] = result; retained[:state] = :completed; @changed.broadcast }
          end
          unless @observer.observe_self!(deadline: [deadline, Wire.deadline(5)].min) == original
            raise SecurityError, "cleanup original owner changed before result"
          end
          ref = result.fetch(:receipt_ref)
          Wire.write(socket, {"schema" => Client::SCHEMA, "kind" => "result", "request_id" => frame.fetch("request_id"),
            "input_digest" => frame.fetch("input_digest"), "receipt_ref" => ref}, deadline: deadline, limit: Client::LIMIT)
          descriptor = @codec.descriptor([result.fetch(:bytes)], purpose: :artifacts)
          @codec.send(socket, parts: [result.fetch(:bytes)], descriptor: descriptor, purpose: :artifacts, deadline: deadline)
        ensure
          socket.close unless socket.closed?
        end

        private

        def inspection(socket, frame, context, original, deadline)
          unless context.fetch("record").fetch("operation_owner_binding") == original
            raise Ace::Runtime::RuntimeUnavailableError, "original cleanup lifetime exclusion unavailable"
          end
          executable = frame.except("challenge_ref").merge("kind" => "execute")
          key = Ace::Assign::Atoms::EvidenceDigest.digest(executable)
          @lock.synchronize do
            request = context.fetch("record").fetch("request_id")
            retained = @consumed[request]
            if retained
              raise SecurityError, "cleanup original inspection input differs" unless retained.fetch(:key) == key
            else
              raise Ace::Runtime::RuntimeUnavailableError, "cleanup lifetime capacity unavailable" if @consumed.size >= MAX_RETAINED
              retained = @consumed[request] = {key: key, state: :inhibited}
            end
            retained[:inhibited] = true
            retained[:state] = :inhibited if retained[:state] == :invoking
            while retained[:state] == :invoked
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              raise Ace::Runtime::RuntimeUnavailableError, "cleanup original effect remains unconfirmed" unless remaining.positive?
              @changed.wait(@lock, remaining)
            end
          end
          inhibition = {"operation_owner_binding_digest" => frame.fetch("operation_owner_binding_digest"),
            "dispatch_event_digest" => frame.fetch("dispatch_event_digest"), "state" => "inhibited", "pending_effects" => 0}
          context = Atoms::ProtectedWorkspacePruneInput.freeze_value(context.merge("input_inhibition" => inhibition))
          unless @observer.observe_self!(deadline: [deadline, Wire.deadline(5)].min) == original
            raise SecurityError, "cleanup original owner changed before inspection"
          end
          result = result!(@installer.inspect_cleanup!(context: context, deadline: deadline), frame)
          unless @observer.observe_self!(deadline: [deadline, Wire.deadline(5)].min) == original
            raise SecurityError, "cleanup original owner changed before inspection result"
          end
          Wire.write(socket, {"schema" => Client::SCHEMA, "kind" => "inspection", "request_id" => frame.fetch("request_id"),
            "input_digest" => frame.fetch("input_digest"), "inspection_ref" => result.fetch(:receipt_ref)}, deadline: deadline, limit: Client::LIMIT)
          descriptor = @codec.descriptor([result.fetch(:bytes)], purpose: :artifacts)
          @codec.send(socket, parts: [result.fetch(:bytes)], descriptor: descriptor, purpose: :artifacts, deadline: deadline)
        end

        def hold_parent!(parent)
          entries = []
          paths = []
          cursor = parent
          loop do
            paths << cursor
            break if cursor == "/"
            cursor = File.dirname(cursor)
          end
          paths.reverse_each do |path|
            handle = File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
            handle.close_on_exec = true
            entries << {path: path, handle: handle, identity: file_identity(handle.stat)}
            @protection.verify!(path, handle, directory: true)
            raise SecurityError, "cleanup parent changed while pinned" unless file_identity(File.lstat(path)) == entries.last.fetch(:identity)
          end
          complete = true
          entries
        ensure
          entries&.each { |entry| entry.fetch(:handle).close } unless complete
        end

        def verify_parents!(entries)
          entries.each do |entry|
            unless file_identity(entry.fetch(:handle).stat) == entry.fetch(:identity) &&
                file_identity(File.lstat(entry.fetch(:path))) == entry.fetch(:identity)
              raise SecurityError, "cleanup protected ancestry changed"
            end
          end
        end

        def file_identity(stat) = [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode]

        def result!(result, frame)
          unless result.is_a?(Hash) && result.keys.sort == %i[bytes receipt_ref] && result.fetch(:bytes).is_a?(String)
            raise SecurityError, "cleanup fixed result unavailable"
          end
          ref = result.fetch(:receipt_ref)
          Atoms::ProtectedWorkspacePruneInput.reference!(ref)
          bytes = result.fetch(:bytes)
          unless bytes.bytesize == ref.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == ref.fetch("sha256")
            raise SecurityError, "cleanup fixed result bytes differ"
          end
          result = {receipt_ref: JSON.parse(JSON.generate(ref)), bytes: bytes.dup}
          Atoms::ProtectedWorkspacePruneInput.freeze_value(result)
        end

        def eof!(socket, deadline)
          guarded = Wire::Ingress.new(socket)
          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise Ace::Runtime::RuntimeUnavailableError, "cleanup request deadline expired" unless remaining.positive? && IO.select([socket], nil, nil, remaining)
            value = guarded.read_nonblock(1, exception: false)
            next if value == :wait_readable
            raise SecurityError, "cleanup request contains trailing bytes" unless value.nil?
            return
          end
        end
      end
    end
  end
end
