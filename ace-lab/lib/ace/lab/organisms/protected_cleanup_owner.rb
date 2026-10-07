# frozen_string_literal: true

require "ace/runtime/molecules/protected_socket"
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

        def initialize(observer:, admission:, snapshots:, journals:, kernel:, installer:, scratch_root:)
          @observer, @admission, @snapshots, @journals = observer, admission, snapshots, journals
          @kernel, @installer = kernel, installer
          @codec = Ace::Assign::Authority::TransferCodec.new(root: scratch_root)
          @lock, @consumed = Mutex.new, {}
        end

        # Listener construction and fixed socket ownership are separately
        # provisioned; every accepted connection still authenticates its peer.
        def handle(socket)
          admission_deadline = Wire.deadline(5)
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
          deadline = Wire.deadline(300)
          context = nil
          @snapshots.call do |snapshot|
            snapshot.with(deadline: deadline) do |view|
              context = @admission.admit!(frame: frame, peer: peer,
                operation_owner_binding: original, journal: @journals.call(view))
            end
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
              next false unless retained[:state] == :invoking
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
            @lock.synchronize { retained[:result] = result; retained[:state] = :completed }
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
