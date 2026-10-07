# frozen_string_literal: true
require "socket"
require "fileutils"
require_relative "deployment"
require_relative "transfer_codec"

module Ace
  module Assign
    module Authority
      # Existing assignment owner transport; kernel peers select roles, never argv.
      class Server
        CONNECTIONS = 16
        def initialize(authority_id:, lifecycle:, deployment: Deployment.load,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new, composition: "launch")
          @authority_id, @lifecycle, @deployment, @kernel = authority_id, lifecycle, deployment, kernel
          @composition = composition
          deployment.verify_composition!(authority_id, composition: composition)
          @service = deployment.authority(authority_id)
          @mutex = Mutex.new
          @connections = []
          @handlers = []
          @transfers = 0
          @stopped = false
        end

        def serve
          @kernel.supported!
          me = @kernel.capture(Process.pid)
          unless principal?(me, @service, "uid", "gid", "groups")
            raise AttemptErrors::UnauthorizedIdentity, "listener principal differs from installed authority"
          end
          @deployment.verify_receiver_paths!(@authority_id)
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
          File.chmod(0o660, path)
          @endpoint = wire.socket_identity(path)
          until @stopped
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

        def same_endpoint?(path)
          wire.socket_identity(path) == @endpoint
        rescue StandardError
          false
        end

        def receive(socket)
          deadline = wire.deadline(30)
          peer = @kernel.peer(socket)
          frame = wire.read(socket, deadline: [deadline, wire.deadline(5)].min, with_size: true)
          request = frame.fetch(:data)
          unless request.is_a?(Hash) && request.keys.sort == %w[mutation_id operation params project_id version] &&
              request["version"].is_a?(Integer) && request["version"] == 1 && request["operation"].is_a?(String) && request["params"].is_a?(Hash)
            raise ArgumentError, "invalid authority envelope"
          end
          deadline = wire.deadline(90) if %w[reserve_attempt close_execution_scope stop_attempt].include?(request.fetch("operation"))
          params = request.fetch("params")
          map = @deployment.verify!(params.fetch("mapping_id"), kernel: @kernel, authority_state: true)
          unless map["authority_id"] == @authority_id && map["project_id"] == request["project_id"]
            raise AttemptErrors::UnauthorizedIdentity, "mapping belongs to another authority or project"
          end
          project = @deployment.project(map.fetch("project_id"))
          owner_contexts = project.fetch("inbox_contexts", {}).select do |_id, context|
            context.fetch("native_mapping_id") == params.fetch("mapping_id") &&
              context.fetch("owner_credentials").values_at("uid", "gid", "groups") == peer.values_at("uid", "gid", "groups")
          end
          context_query = request["operation"] == "inbox_context_completion"
          if context_query || !owner_contexts.empty?
            unless context_query && @composition == "services" && request["mutation_id"].nil? &&
                owner_contexts.key?(params.fetch("inbox_context_id")) && frame.fetch(:bytesize) <= 16_384
              raise AttemptErrors::UnauthorizedIdentity, "context owner is exclusive to its completion query"
            end
            role = :context_owner
          end
          if request["operation"] == "native_readiness"
            unless @composition == "launch" && request["mutation_id"].nil? && params.keys == ["mapping_id"] &&
                frame.fetch(:bytesize) <= 16_384
              raise ArgumentError, "private readiness envelope differs"
            end
            admitted_transfer = @mutex.synchronize do
              if @transfers < 2
                @transfers += 1
                true
              end
            end
            raise AttemptErrors::Conflict, "readiness transfer capacity is busy" unless admitted_transfer
            @lifecycle.native_readiness!(mapping_id: params.fetch("mapping_id"), peer: peer, socket: socket,
              codec: transfer_codec, deadline: wire.deadline(10))
            return
          end
          role ||= if principal?(peer, map, "launcher_uid", "launcher_gid", "launcher_groups")
            :launcher
          elsif principal?(peer, map, "worker_uid", "worker_gid", "worker_groups")
            :worker
          end
          unless role
            project = @deployment.project(map.fetch("project_id"))
            configured = project.fetch("peer_credentials")[peer.fetch("uid").to_s]
            if configured && peer["gid"] == configured["gid"] && peer["groups"] == configured["groups"]
              {reviewer: "reviewer_uids", executor: "service_executor_uids", supervisor: "supervisor_uids"}.each do |candidate, key|
                role ||= candidate if project.fetch(key).include?(peer.fetch("uid"))
              end
            end
          end
          raise AttemptErrors::UnauthorizedIdentity, "unmapped kernel peer" unless role
          if request["operation"] == "launch_control"
            raise AttemptErrors::UnauthorizedIdentity, "Private launcher control requires launcher peer" unless role == :launcher
            raise ArgumentError, "Private launcher header is oversized" unless frame.fetch(:bytesize) <= 16_384
            @lifecycle.serve_launch_control!(request: request, peer: peer, socket: socket, codec: transfer_codec, deadline: deadline)
            return
          end
          if %w[observe_execution_scope close_execution_scope stop_attempt prompt_status launch_input_inhibit_selection launch_input_inhibit_completion launch_prompt_intent launch_prompt_completion claim_service_settlement].include?(request["operation"]) ||
              @composition == "services" && %w[attempt_status evidence_fetch inbox_context_completion].include?(request["operation"])
            bodyless_read!(socket, deadline)
          end
          if request["operation"] == "gate_ready"
            raise AttemptErrors::UnauthorizedIdentity, "gate readiness requires worker peer" unless role == :worker
            @lifecycle.gate_ready(request: request, peer: peer, socket: socket, deadline: deadline)
          else
            binding = @lifecycle.transfer_binding(request.fetch("operation")) if @lifecycle.respond_to?(:transfer_binding)
            if binding
              raise AttemptErrors::UnauthorizedIdentity, "transfer role differs" unless binding.fetch(:roles).include?(role)
              raise ArgumentError, "transfer control header is oversized" if frame.fetch(:bytesize) > 16_384
              @lifecycle.authorize_transfer!(request: request, peer: peer, role: role)
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
                  @lifecycle.dispatch(request: request, peer: peer, role: role, transfer: input)
                end
              else
                result = @lifecycle.dispatch(request: request, peer: peer, role: role)
                parts = result.fetch(:transfer_parts)
                descriptor = codec.descriptor(parts, purpose: binding.fetch(:purpose))
                result = result.merge(data: result.fetch(:data).merge("transfer" => descriptor))
              end
            else
              raise ArgumentError, "unexpected transfer descriptor" if params.key?("transfer")
              result = @lifecycle.dispatch(request: request, peer: peer, role: role)
            end
            wire.write(socket, {"status" => "ok", "data" => result.fetch(:data),
              "transport" => {"replayed" => result.fetch(:replayed, false)}}, deadline: deadline, limit: 16_384)
            if binding && binding.fetch(:direction) == :download
              codec.send(socket, parts: parts, descriptor: descriptor, purpose: binding.fetch(:purpose), deadline: deadline)
            end
          end
        rescue ArgumentError, KeyError, AttemptErrors::MalformedTransfer
          refusal(socket, "invalid_input")
        rescue AttemptErrors::UnauthorizedIdentity
          refusal(socket, "unauthorized")
        rescue AttemptErrors::Conflict
          refusal(socket, "conflict")
        rescue AttemptErrors::NotFound
          refusal(socket, "missing")
        rescue StandardError
          refusal(socket, "evidence_unavailable")
        ensure
          socket.close unless socket.closed?
          @mutex.synchronize do
            @connections.delete(socket)
            @transfers -= 1 if admitted_transfer
          end
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

        def principal?(identity, mapping, uid, gid, groups)
          identity["uid"] == mapping[uid] && identity["gid"] == mapping[gid] && identity["groups"] == mapping[groups]
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
