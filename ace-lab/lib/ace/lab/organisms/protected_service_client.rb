# frozen_string_literal: true

require_relative "protected_service_listener"

module Ace
  module Lab
    module Organisms
      # Worker-side short claim exchange. No local journal/executor fallback;
      # outcome/recovery remains the existing protected authority service API.
      class ProtectedServiceClient
        def initialize(mapping_id:, service_id:, deployment: Ace::Assign::Authority::Deployment.load,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new, wire: Ace::Runtime::Molecules::ProtectedSocket)
          @deployment, @kernel, @wire, @mapping_id = deployment, kernel, wire, mapping_id
          @map = deployment.mapping(mapping_id)
          project = deployment.project(@map.fetch("project_id"))
          @selection = project.fetch("service_receivers").fetch(service_id)
          @credentials = project.fetch("peer_credentials").fetch(@selection.fetch("executor_uid").to_s)
          @scratch = project.fetch("peer_credentials").fetch(@map.fetch("worker_uid").to_s).fetch("scratch_root")
        end

        def preview_workspace_prune(intent:)
          intent = Atoms::ProtectedWorkspacePrunePreview.intent!(JSON.parse(JSON.generate(intent)))
          bytes = JSON.generate(intent)
          deadline = @wire.deadline(5)
          @deployment.verify!(@mapping_id, kernel: @kernel)
          caller = @kernel.capture(Process.pid)
          unless caller.values_at("uid", "gid", "groups") == @map.values_at("worker_uid", "worker_gid", "worker_groups")
            raise SecurityError, "preview caller differs"
          end
          codec = Ace::Assign::Authority::TransferCodec.new(root: @scratch)
          descriptor = codec.descriptor([bytes], purpose: :service_input)
          path = @selection.fetch("socket_path")
          before = @wire.socket_identity(path)
          raise SecurityError, "preview receiver owner differs" unless before.last == @selection.fetch("executor_uid")
          @wire.connect(path, deadline: deadline) do |socket|
            peer = @kernel.peer(socket)
            unless peer.values_at("uid", "gid", "groups") == [@selection.fetch("executor_uid"), @credentials.fetch("gid"), @credentials.fetch("groups")] &&
                @wire.socket_identity(path) == before
              raise SecurityError, "preview receiver peer changed"
            end
            @wire.write(socket, {"version" => 1, "kind" => "preview_workspace_prune", "transfer" => descriptor},
              deadline: deadline, limit: ProtectedServiceListener::LIMIT)
            codec.send(socket, parts: [bytes], descriptor: descriptor, purpose: :service_input, deadline: deadline)
            socket.shutdown(Socket::SHUT_WR)
            guarded = Ace::Runtime::Molecules::ProtectedSocket::Ingress.new(socket)
            result = @wire.read(guarded, deadline: deadline, limit: ProtectedServiceListener::LIMIT)
            eof!(guarded, deadline)
            raise SecurityError, "preview result unavailable" unless result.is_a?(Hash) && result.key?("maintenance_context")
            Atoms::ProtectedWorkspacePrunePreview.context!(result.fetch("maintenance_context"))
            Atoms::ProtectedWorkspacePrunePreview.result!(result, intent: intent, context: result.fetch("maintenance_context"))
          end
        end

        def submit(submission:, input_bytes:, mutation_id:)
          unless submission.is_a?(Hash) && submission.keys.sort == ProtectedServiceReceiver::SUBMISSION.sort &&
              input_bytes.is_a?(String) && mutation_id.is_a?(String) && mutation_id.match?(Ace::Assign::Molecules::JournalMutation::ID)
            raise ArgumentError, "receiver submission is invalid"
          end
          submission = JSON.parse(JSON.generate(submission))
          bytes = input_bytes.dup.freeze
          mutation_id = mutation_id.dup.freeze
          deadline = @wire.deadline(5)
          @deployment.verify!(@mapping_id, kernel: @kernel)
          caller = @kernel.capture(Process.pid)
          unless caller.values_at("uid", "gid", "groups") == @map.values_at("worker_uid", "worker_gid", "worker_groups")
            raise SecurityError, "receiver caller differs"
          end
          codec = Ace::Assign::Authority::TransferCodec.new(root: @scratch)
          descriptor = codec.descriptor([bytes], purpose: :service_input)
          path = @selection.fetch("socket_path")
          before = @wire.socket_identity(path)
          raise SecurityError, "receiver endpoint owner differs" unless before.last == @selection.fetch("executor_uid")
          @wire.connect(path, deadline: deadline) do |socket|
            peer = @kernel.peer(socket)
            unless peer.values_at("uid", "gid", "groups") == [@selection.fetch("executor_uid"), @credentials.fetch("gid"), @credentials.fetch("groups")] &&
                @wire.socket_identity(path) == before
              raise SecurityError, "receiver endpoint peer changed"
            end
            @wire.write(socket, {"version" => 1, "submission" => submission,
              "mutation_id" => mutation_id, "transfer" => descriptor}, deadline: deadline, limit: ProtectedServiceListener::LIMIT)
            codec.send(socket, parts: [bytes], descriptor: descriptor, purpose: :service_input, deadline: deadline)
            socket.shutdown(Socket::SHUT_WR)
            guarded = Ace::Runtime::Molecules::ProtectedSocket::Ingress.new(socket)
            reply = @wire.read(guarded, deadline: deadline, limit: ProtectedServiceListener::LIMIT)
            eof!(guarded, deadline)
            validate_reply!(reply, submission.fetch("request_id"))
            reply
          end
        rescue Ace::Runtime::RuntimeUnavailableError, IOError, SystemCallError, Timeout::Error
          {"version" => 1, "type" => "service_claim_unconfirmed", "required_action" => "inspect_canonical_service_status"}
        end

        private

        def eof!(socket, deadline)
          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            unless remaining.positive? && IO.select([socket], nil, nil, remaining)
              raise Ace::Runtime::RuntimeUnavailableError, "receiver reply EOF deadline expired"
            end
            byte = socket.read_nonblock(1, exception: false)
            next if byte == :wait_readable
            raise SecurityError, "receiver reply has trailing bytes" unless byte.nil?
            return
          end
        end

        def validate_reply!(reply, request_id)
          unless reply.is_a?(Hash) && reply["version"].is_a?(Integer) && reply["version"] == 1
            raise SecurityError, "receiver claim reply is invalid"
          end
          if reply["type"] == "service_claim_refused"
            raise SecurityError, "receiver claim refusal is invalid" unless reply.keys.sort == %w[code type version] && %w[busy unavailable].include?(reply["code"])
            return
          end
          data = reply["data"]
          unless reply.keys.sort == %w[data type version] && reply["type"] == "service_claim_accepted" &&
              data.is_a?(Hash) && (data.keys - %w[request_id generation journal_commit state claim replayed]).empty? &&
              data["request_id"] == request_id && data["generation"].is_a?(Integer) && data["generation"].positive? &&
              data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              %w[uncertain succeeded failed failed-settled].include?(data["state"]) && [true, false].include?(data["replayed"]) &&
              (!data.key?("claim") || %w[created retained].include?(data["claim"]))
            raise SecurityError, "receiver canonical claim identity differs"
          end
        end
      end
    end
  end
end
