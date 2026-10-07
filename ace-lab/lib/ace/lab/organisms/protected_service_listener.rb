# frozen_string_literal: true

require "socket"
require_relative "protected_service_worker"

module Ace
  module Lab
    module Organisms
      # Fixed receiver ingress. The short connection observes canonical claim
      # acceptance; it does not own or cancel the admitted execution lifetime.
      class ProtectedServiceListener
        LIMIT = 16_384
        REQUEST_KEYS = %w[mutation_id submission transfer version].freeze

        def initialize(mapping_id:, service_id:, deployment: Ace::Assign::Authority::Deployment.load,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new, receiver: nil,
          wire: Ace::Runtime::Molecules::ProtectedSocket)
          @deployment, @kernel, @wire = deployment, kernel, wire
          @map = deployment.mapping(mapping_id)
          project = deployment.project(@map.fetch("project_id"))
          @selection = project.fetch("service_receivers").fetch(service_id)
          @credentials = project.fetch("peer_credentials").fetch(@selection.fetch("executor_uid").to_s)
          @path = @selection.fetch("socket_path")
          @worker = ProtectedServiceWorker.new(receiver: receiver || ProtectedServiceReceiver.new(
            mapping_id: mapping_id, service_id: service_id, deployment: deployment, kernel: kernel))
          @stopping = false
        end

        def serve
          own_principal!
          parent = File.dirname(@path)
          @wire.root_path!(parent, directory: true, owner: @selection.fetch("executor_uid"))
          # The installed receiver must actually be able to publish a socket
          # accessible to its mapped worker. No ambient ACL/root fixup exists.
          unless @credentials.fetch("gid") == @map.fetch("worker_gid") || @credentials.fetch("groups").include?(@map.fetch("worker_gid"))
            raise SecurityError, "receiver socket group is unavailable"
          end
          @lock = File.open("#{@path}.lock", File::RDWR | File::CREAT | File::NOFOLLOW, 0o600)
          stat = @lock.stat
          unless stat.file? && stat.uid == Process.uid && stat.nlink == 1 && (stat.mode & 0o7777) == 0o600
            raise SecurityError, "receiver listener lock differs"
          end
          unless @lock.flock(File::LOCK_EX | File::LOCK_NB)
            raise Ace::Assign::AttemptErrors::Conflict, "receiver listener already active"
          end
          remove_stale_endpoint!
          @listener = UNIXServer.new(@path)
          File.chown(nil, @map.fetch("worker_gid"), @path)
          File.chmod(0o660, @path)
          @identity = @wire.socket_identity(@path)
          until @stopping
            begin
              socket = @listener.accept
              receive(socket)
            ensure
              socket&.close
              socket = nil
            end
          end
        rescue IOError, Errno::EBADF
          raise unless @stopping
        ensure
          # Never release listener exclusion while an admitted worker exists.
          # Actual operation transport supplies its separate bounded lifetime.
          @worker.close(timeout: 1) until @worker.close(timeout: 0)
          @listener&.close
          remove_owned_endpoint!
          @lock&.close
        end

        def stop
          @stopping = true
          @worker.close(timeout: 0)
          @listener&.close
        end

        private

        def receive(socket)
          deadline = @wire.deadline(5)
          peer = @kernel.peer(socket)
          unless peer.values_at("uid", "gid", "groups") == @map.values_at("worker_uid", "worker_gid", "worker_groups")
            raise SecurityError, "receiver worker peer differs"
          end
          guarded = Ingress.new(socket)
          request = @wire.read(guarded, deadline: deadline, limit: LIMIT)
          strict_request!(request)
          codec = Ace::Assign::Authority::TransferCodec.new(root: @selection.fetch("staging_root"))
          bytes = codec.receive(guarded, descriptor: request.fetch("transfer"), purpose: :service_input, deadline: deadline) { |input| input.bytes }
          completed = Queue.new
          @worker.start(submission: request.fetch("submission"), peer: peer,
            input_bytes: bytes, mutation_id: request.fetch("mutation_id"), deadline: deadline,
            on_claim: lambda do |identity|
              begin
                @wire.write(socket, {"version" => 1, "type" => "service_claim_accepted", "data" => identity},
                  deadline: deadline, limit: LIMIT)
              rescue Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError
                # Only bounded transport failure is swallowed. Original work
                # continues and its accepted identity is observed via status.
                nil
              ensure
                completed << true
              end
            end)
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          completed.pop(timeout: remaining) if remaining.positive?
        rescue Ace::Assign::AttemptErrors::Conflict
          refuse(socket, "busy", deadline)
        rescue SecurityError, ArgumentError, KeyError, TypeError, Ace::Assign::Error,
          Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError, Timeout::Error
          refuse(socket, "unavailable", deadline)
        end

        def strict_request!(request)
          unless request.is_a?(Hash) && request.keys.sort == REQUEST_KEYS &&
              request["version"].is_a?(Integer) && request["version"] == 1 &&
              request["transfer"].is_a?(Hash) && request["transfer"]["version"].is_a?(Integer) && request["transfer"]["version"] == 1 &&
              request["mutation_id"].is_a?(String) && request["mutation_id"].match?(Ace::Assign::Molecules::JournalMutation::ID) &&
              request["submission"].is_a?(Hash) && request["submission"].keys.sort == ProtectedServiceReceiver::SUBMISSION.sort
            raise ArgumentError, "receiver request is invalid"
          end
          walk = [[request, 0]]
          until walk.empty?
            value, depth = walk.pop
            raise ArgumentError, "receiver request depth exceeds bound" if depth > 16
            children = value.is_a?(Hash) ? value.values : (value.is_a?(Array) ? value : [])
            children.each { |child| walk << [child, depth + 1] }
          end
        end

        def refuse(socket, code, deadline)
          @wire.write(socket, {"version" => 1, "type" => "service_claim_refused", "code" => code}, deadline: deadline, limit: LIMIT)
        rescue Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError
          nil
        end

        def own_principal!
          me = @kernel.capture(Process.pid)
          unless me.values_at("uid", "gid", "groups") == [@selection.fetch("executor_uid"), @credentials.fetch("gid"), @credentials.fetch("groups")]
            raise SecurityError, "receiver listener principal differs"
          end
          @kernel.live!(me)
        end

        def remove_stale_endpoint!
          stat = File.lstat(@path)
          unless stat.socket? && stat.uid == Process.uid
            raise SecurityError, "receiver endpoint differs"
          end
          File.unlink(@path)
        rescue Errno::ENOENT
          nil
        end

        def remove_owned_endpoint!
          File.unlink(@path) if @identity && @wire.socket_identity(@path) == @identity
        rescue Errno::ENOENT
          nil
        end

        # The same wrapper guards both JSON and binary input/EOF, so ancillary
        # descriptors cannot be hidden in a later transfer read.
        class Ingress
          def initialize(socket)
            @socket = socket
          end

          def to_io
            @socket
          end

          def read_nonblock(length, exception: false)
            result = @socket.recvmsg_nonblock(length, 0, 4096, scm_rights: true, exception: exception)
            return result if result == :wait_readable
            return nil if result.nil?
            bytes, _, flags, *controls = result
            controls.each { |control| control.unix_rights&.each(&:close) if control.cmsg_is?(Socket::SOL_SOCKET, Socket::SCM_RIGHTS) }
            raise SecurityError, "receiver ancillary input is forbidden" unless controls.empty? && (flags & Socket::MSG_CTRUNC).zero?
            bytes.empty? ? nil : bytes
          end
        end
      end
    end
  end
end
