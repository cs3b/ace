# frozen_string_literal: true

require "socket"
require "fileutils"
require_relative "transfer_codec"
require_relative "../molecules/evidence_journal"

module Ace
  module Assign
    module Authority
      # Shared endpoint lifetime and bounded wire protocol. Concrete source
      # compositions authenticate their own installed principals before dispatch.
      # Protected deployment/kernel requirements remain in Server.
      class SocketServer
        CONNECTIONS = 16

        def initialize(service:, lifecycle:, hitl_service: nil)
          @service, @lifecycle, @hitl_service = service, lifecycle, hitl_service
          @mutex = Mutex.new
          @connections = []
          @handlers = []
          @transfers = 0
          @stopped = false
        end

        def serve
          verify_listener!
          directory = File.dirname(@service.fetch("socket_path"))
          wire.root_path!(directory, directory: true, owner: @service.fetch("uid"))
          lock = File.open(File.join(directory, "listener.lock"), File::RDWR | File::CREAT | File::NOFOLLOW, 0o600)
          unless lock.flock(File::LOCK_EX | File::LOCK_NB)
            raise AttemptErrors::Conflict, "assignment authority already owns its listener"
          end
          start_hitl_service!
          path = @service.fetch("socket_path")
          if File.exist?(path) || File.symlink?(path)
            raise AttemptErrors::Conflict, "existing authority endpoint requires verified installer recovery"
          end
          @listener = UNIXServer.new(path)
          File.chmod(0o660, path)
          @endpoint = wire.socket_identity(path)
          until @stopped
            if @hitl_thread && !@hitl_thread.alive?
              raise Ace::Runtime::RuntimeUnavailableError, "protected HITL boundary stopped before its authority"
            end
            ready = IO.select([@listener], nil, nil, 0.25)
            next unless ready
            socket = @listener.accept_nonblock(exception: false)
            next if socket == :wait_readable
            admitted = @mutex.synchronize do
              if @connections.size < CONNECTIONS
                @connections << socket
                true
              end
            end
            unless admitted
              refusal(socket, "busy")
              socket.close
              next
            end
            @mutex.synchronize do
              @handlers.reject! { |handler| !handler.alive? }
              @handlers << Thread.new(socket) { |connection| receive(connection) }
            end
          end
        rescue IOError, Errno::EBADF
          raise unless @stopped
        ensure
          stop
          stop_hitl_service!
          # Closing a stream does not cancel a handler already inside dispatch.
          # The owner lock and endpoint remain held until every handler ends.
          @mutex.synchronize { @handlers.dup }.each(&:join)
          @lifecycle.close if @endpoint && @lifecycle.respond_to?(:close)
          if @endpoint && same_endpoint?(path)
            File.unlink(path)
          end
          lock&.close
        end

        def request_stop
          @stopped = true
        end

        def stop
          @stopped = true
          @listener&.close unless @listener&.closed?
          @mutex.synchronize { @connections.each { |socket| socket.close unless socket.closed? } }
        end

        private

        # The existing HITL boundary is a sibling owned by this listener's
        # lifetime. It must be ready before assignment ingress is opened.
        def start_hitl_service!
          return unless @hitl_service
          ready = Queue.new
          @hitl_thread = Thread.new do
            @hitl_service.run(on_ready: -> { ready << :ready })
          rescue Exception => error
            @hitl_failure = error
            ready << error
          end
          @hitl_thread.report_on_exception = false
          result = ready.pop(timeout: 5)
          raise Ace::Runtime::RuntimeUnavailableError, "protected HITL boundary startup timed out" if result.nil?
          raise result if result.is_a?(Exception)
        end

        def stop_hitl_service!
          return unless @hitl_thread
          @hitl_service.stop
          @hitl_thread.join
        end

        def same_endpoint?(path)
          wire.socket_identity(path) == @endpoint
        rescue StandardError
          false
        end

        def verify_listener!
          raise NotImplementedError, "source composition must verify its installed listener"
        end

        def dispatch_request(socket, request, peer, role, deadline, frame_bytes:)
          params = request.fetch("params")
          admitted_transfer = false
          Molecules::EvidenceJournal.with_event_read_operation do
            binding = @lifecycle.transfer_binding(request) if @lifecycle.respond_to?(:transfer_binding)
            if binding
              raise AttemptErrors::UnauthorizedIdentity, "transfer role differs" unless binding.fetch(:roles).include?(role)
              raise ArgumentError, "transfer control header is oversized" if frame_bytes > 16_384
              authorize_transfer!(request: request, peer: peer, role: role, deadline: deadline)
              admitted_transfer = @mutex.synchronize do
                if @transfers < 2
                  @transfers += 1
                  true
                end
              end
              raise AttemptErrors::Conflict, "transfer capacity is busy" unless admitted_transfer
              codec = transfer_codec
              if binding.fetch(:direction) == :upload
                result = codec.receive(socket, descriptor: params.fetch("transfer"), purpose: binding.fetch(:purpose), deadline: deadline) do |input|
                  dispatch_lifecycle(request: request, peer: peer, role: role, transfer: input, deadline: deadline)
                end
              else
                result = dispatch_lifecycle(request: request, peer: peer, role: role, deadline: deadline)
                parts = result.fetch(:transfer_parts)
                descriptor = codec.descriptor(parts, purpose: binding.fetch(:purpose))
                result = result.merge(data: result.fetch(:data).merge("transfer" => descriptor))
              end
            else
              raise ArgumentError, "unexpected transfer descriptor" if params.key?("transfer")
              result = dispatch_lifecycle(request: request, peer: peer, role: role, deadline: deadline)
            end
            wire.write(socket, {"status" => "ok", "data" => result.fetch(:data),
              "transport" => {"replayed" => result.fetch(:replayed, false)}}, deadline: deadline, limit: 16_384)
            if binding && binding.fetch(:direction) == :download
              codec.send(socket, parts: parts, descriptor: descriptor, purpose: binding.fetch(:purpose), deadline: deadline)
            end
          end
        ensure
          @mutex.synchronize { @transfers -= 1 } if admitted_transfer
        end

        def authorize_transfer!(request:, peer:, role:, deadline:)
          @lifecycle.authorize_transfer!(request: request, peer: peer, role: role)
        end

        def dispatch_lifecycle(request:, peer:, role:, deadline:, transfer: nil)
          options = {request: request, peer: peer, role: role}
          options[:transfer] = transfer if transfer
          @lifecycle.dispatch(**options)
        end

        # These closed read operations have no request body. Half-close proves
        # framing completion before status or artifact data can be exposed.
        def bodyless_read!(socket, deadline)
          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise ArgumentError, "read request framing is incomplete" unless remaining.positive? && IO.select([socket], nil, nil, remaining)
            bytes = socket.read_nonblock(1, exception: false)
            next if bytes == :wait_readable
            raise ArgumentError, "unexpected read request body" unless bytes.nil?
            return
          end
        end

        def transfer_codec
          @mutex.synchronize do
            @transfer_codec ||= begin
              root = @service.fetch("state_root")
              PrivateDirectory.verify!(root)
              spool = File.join(root, "transfers")
              Dir.mkdir(spool, 0o700) unless File.exist?(spool) || File.symlink?(spool)
              TransferCodec.new(root: spool)
            end
          end
        end

        def refusal(socket, code)
          wire.write(socket, {"status" => "error", "error" => {"code" => code, "message" => "Protected authority refused #{code}"}},
            deadline: wire.deadline(0.1))
        rescue StandardError
          nil
        end

        def wire
          Ace::Runtime::Molecules::ProtectedSocket
        end
      end
    end
  end
end
