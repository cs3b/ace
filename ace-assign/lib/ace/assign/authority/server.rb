# frozen_string_literal: true

require_relative "deployment"
require_relative "socket_server"

module Ace
  module Assign
    module Authority
      # Protected admission is mandatory for this source-selected composition.
      class Server < SocketServer
        def initialize(authority_id:, lifecycle:, deployment: Deployment.load,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new, composition: "launch", hitl_service: nil)
          @authority_id, @deployment, @kernel, @composition = authority_id, deployment, kernel, composition
          deployment.verify_composition!(authority_id, composition: composition)
          super(service: deployment.authority(authority_id), lifecycle: lifecycle, hitl_service: hitl_service)
        end

        private

        def verify_listener!
          @kernel.supported!
          me = @kernel.capture(Process.pid)
          unless principal?(me, @service, "uid", "gid", "groups")
            raise AttemptErrors::UnauthorizedIdentity, "listener principal differs from installed authority"
          end
          @deployment.verify_receiver_paths!(@authority_id)
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
          context_query = %w[inbox_context_original].include?(request["operation"])
          if context_query || !owner_contexts.empty?
            unless context_query && @composition == "services" && request["mutation_id"].nil? &&
                owner_contexts.key?(params.fetch("inbox_context_id")) && frame.fetch(:bytesize) <= 16_384
              raise AttemptErrors::UnauthorizedIdentity, "context owner is exclusive to its fixed read-only inbox queries"
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
          if %w[bind_inbox finish recover request_review review_status launch_review_intent cancel_review evidence_fetch assignment_inventory observe_execution_scope close_execution_scope stop_attempt prompt_status launch_input_inhibit_selection launch_input_inhibit_completion launch_prompt_intent launch_prompt_completion claim_service_settlement workspace_prune_preview_context].include?(request["operation"]) ||
              @composition == "services" && %w[attempt_status inbox_context_original].include?(request["operation"])
            raise ArgumentError, "review control header is oversized" if %w[request_review review_status cancel_review launch_review_intent].include?(request["operation"]) && frame.fetch(:bytesize) > 16_384
            bodyless_read!(socket, deadline)
          end
          if request["operation"] == "gate_ready"
            raise AttemptErrors::UnauthorizedIdentity, "gate readiness requires worker peer" unless role == :worker
            @lifecycle.gate_ready(request: request, peer: peer, socket: socket, deadline: deadline)
          else
            dispatch_request(socket, request, peer, role, deadline, frame_bytes: frame.fetch(:bytesize))
          end
        rescue ArgumentError, KeyError, AttemptErrors::MalformedTransfer
          refusal(socket, "invalid_input")
        rescue AttemptErrors::UnauthorizedIdentity, SecurityError
          refusal(socket, "unauthorized")
        rescue AttemptErrors::Conflict
          refusal(socket, "conflict")
        rescue AttemptErrors::NotFound
          refusal(socket, "missing")
        rescue AttemptErrors::BoundedResultUnavailable
          refusal(socket, "bounded_result")
        rescue StandardError
          refusal(socket, "evidence_unavailable")
        ensure
          socket.close unless socket.closed?
          @mutex.synchronize do
            @connections.delete(socket)
            @transfers -= 1 if admitted_transfer
          end
        end

        def principal?(identity, mapping, uid, gid, groups)
          identity["uid"] == mapping[uid] && identity["gid"] == mapping[gid] && identity["groups"] == mapping[groups]
        end
      end
    end
  end
end
