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

        def initialize(service:, lifecycle:, services: [])
          unless services.is_a?(Array) && services.uniq.size == services.size &&
              services.all? { |owned| owned.respond_to?(:run) && owned.respond_to?(:stop) }
            raise ArgumentError, "authority services require distinct source-owned run/stop lifetimes"
          end
          @service, @lifecycle, @services = service, lifecycle, services.dup.freeze
          @service_threads = []
          @activation_gates = []
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
          path = @service.fetch("socket_path")
          if File.exist?(path) || File.symlink?(path)
            raise AttemptErrors::Conflict, "existing authority endpoint requires verified installer recovery"
          end
          @listener = UNIXServer.new(path)
          @endpoint = wire.socket_identity(path)
          File.chmod(0o660, path)
          start_services!
          verify_services!
          @activation_gates.each { |gate| gate << :activate }
          until @stopped
            verify_services!
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
          begin
            stop
            stop_services!
          ensure
            # Closing a stream does not cancel an admitted transaction. Hold
            # the owner lock and endpoint until every handler has ended.
            begin
              @mutex.synchronize { @handlers.dup }.each(&:join)
              @lifecycle.close if @endpoint && @lifecycle.respond_to?(:close)
            ensure
              begin
                File.unlink(path) if @endpoint && same_endpoint?(path)
              ensure
                lock&.close
              end
            end
          end
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

        # Installed HITL and merge listeners share the assignment owner lock.
        # Every selected boundary must be ready before assignment ingress opens;
        # a stopped boundary closes admission until the complete owner restarts.
        def start_services!
          @services.each do |owned|
            ready = Queue.new
            activation = Queue.new
            @activation_gates << activation
            thread = Thread.new do
              owned.run(on_ready: lambda do
                ready << :ready
                unless activation.pop == :activate
                  raise Ace::Runtime::RuntimeUnavailableError, "authority startup was cancelled"
                end
              end)
            rescue Exception => error
              ready << error
            ensure
              ready << :stopped
            end
            thread.report_on_exception = false
            @service_threads << [owned, thread]
            result = ready.pop(timeout: 5)
            raise Ace::Runtime::RuntimeUnavailableError, "authority service startup did not become ready" unless result == :ready || result.is_a?(Exception)
            raise result if result.is_a?(Exception)
          end
        end

        def verify_services!
          unless @service_threads.all? { |_, thread| thread.alive? }
            raise Ace::Runtime::RuntimeUnavailableError, "an owned service stopped before its authority"
          end
        end

        def stop_services!
          errors = []
          @activation_gates.each { |gate| gate << :cancel }
          @service_threads.reverse_each do |owned, _|
            owned.stop
          rescue Exception => error
            errors << error
          end
          @service_threads.each do |_, thread|
            thread.join
          rescue Exception => error
            errors << error
          end
          raise errors.first unless errors.empty?
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
