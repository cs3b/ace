# frozen_string_literal: true
require "securerandom"
require_relative "deployment"
require_relative "transfer_codec"
require_relative "../molecules/canonical_evidence"

module Ace
  module Assign
    module Authority
      class Client
        Reply = Struct.new(:data, :replayed, :parts, keyword_init: true)
        attr_reader :mapping_id
        def initialize(mapping_id:, deployment: Deployment.load, kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @mapping_id, @deployment, @kernel = mapping_id, deployment, kernel
          @map = deployment.mapping(mapping_id)
          @service = deployment.authority(@map.fetch("authority_id"))
        end

        def call(operation, params, mutation_id: nil, timeout: nil, upload_parts: nil, download: false, purpose: nil)
          if operation == "evidence_fetch" && (!download || purpose != :artifacts || upload_parts)
            raise ArgumentError, "evidence fetch requires fixed artifacts download"
          end
          if operation == "submit_result" && (!upload_parts || purpose != :receipt_artifacts || download)
            raise ArgumentError, "result submission requires fixed receipt upload"
          end
          @deployment.verify!(mapping_id, kernel: @kernel)
          wire = Ace::Runtime::Molecules::ProtectedSocket
          path = @service.fetch("socket_path")
          before = wire.socket_identity(path)
          raise Ace::Runtime::RuntimeUnavailableError, "authority endpoint owner differs" unless before.last == @service.fetch("uid")
          raise ArgumentError, "cannot upload and download on one request" if upload_parts && download
          codec = transfer_codec if upload_parts || download
          descriptor = codec.descriptor(upload_parts, purpose: purpose) if upload_parts
          parameters = upload_parts ? params.merge("transfer" => descriptor) : params
          cap = %w[reserve_attempt close_execution_scope stop_attempt].include?(operation) ? 90 : 30
          duration = timeout || (cap == 90 ? 90 : 5)
          unless duration.is_a?(Numeric) && duration.positive? && duration.finite?
            raise ArgumentError, "authority timeout must be finite and positive"
          end
          deadline = wire.deadline([duration, cap].min)
          wire.connect(path, deadline: deadline) do |socket|
            peer = @kernel.peer(socket)
            unless peer["uid"] == @service.fetch("uid") && peer["gid"] == @service.fetch("gid") &&
                peer["groups"] == @service.fetch("groups") && wire.socket_identity(path) == before
              raise AttemptErrors::UnauthorizedIdentity, "authority endpoint peer changed"
            end
            wire.write(socket, {"version" => 1, "operation" => operation,
              "mutation_id" => mutation_id, "project_id" => @map.fetch("project_id"),
              "params" => parameters.merge("mapping_id" => mapping_id)}, deadline: deadline, limit: upload_parts || download ? 16_384 : wire::LIMIT)
            if %w[evidence_fetch observe_execution_scope close_execution_scope stop_attempt prompt_status launch_input_inhibit_selection launch_input_inhibit_completion launch_prompt_intent launch_prompt_completion claim_service_settlement].include?(operation) || (operation == "attempt_status" && params.key?("result_candidate_generation"))
              socket.shutdown(Socket::SHUT_WR)
            end
            if upload_parts
              codec.send(socket, parts: upload_parts, descriptor: descriptor, purpose: purpose, deadline: deadline)
              socket.shutdown(Socket::SHUT_WR)
            end
            result = wire.read(socket, deadline: deadline, limit: 16_384)
            unless result.is_a?(Hash) && result["status"] == "ok" && result["data"].is_a?(Hash)
              code = result.is_a?(Hash) ? result.dig("error", "code") : nil
              raise AttemptErrors::EvidenceUnavailable, "protected authority refused (#{code || 'invalid_response'})"
            end
            transport = result.fetch("transport")
            unless transport.is_a?(Hash) && transport.keys == ["replayed"] && [true, false].include?(transport["replayed"])
              raise AttemptErrors::EvidenceUnavailable, "authority replay metadata is unavailable"
            end
            validate_evidence_download!(result.fetch("data"), params) if operation == "evidence_fetch"
            parts = if download
              codec.receive(socket, descriptor: result.fetch("data").fetch("transfer"), purpose: purpose, deadline: deadline) do |input|
                Array.new(input.count) { |index| input.bytes(index: index) }
              end
            end
            Reply.new(data: result.fetch("data"), replayed: transport.fetch("replayed"), parts: parts)
          end
        rescue SystemCallError, IOError
          raise AttemptErrors::EvidenceUnavailable, "protected authority connection unavailable; no local fallback"
        end
        # Fixed original-launcher stream. Public calls retain their existing
        # complete-upload EOF contract; no caller-selected framing flag exists.
        def with_launch_control(state:)
          @deployment.verify!(mapping_id, kernel: @kernel)
          wire = Ace::Runtime::Molecules::ProtectedSocket
          path = @service.fetch("socket_path")
          before = wire.socket_identity(path)
          raise Ace::Runtime::RuntimeUnavailableError, "Authority endpoint owner differs" unless before.last == @service.fetch("uid")
          deadline = wire.deadline(30)
          wire.connect(path, deadline: deadline) do |socket|
            peer = @kernel.peer(socket)
            unless peer.values_at("uid", "gid", "groups") == @service.values_at("uid", "gid", "groups") && wire.socket_identity(path) == before
              raise AttemptErrors::UnauthorizedIdentity, "Authority stream peer changed"
            end
            wire.write(socket, {"version" => 1, "operation" => "launch_control", "mutation_id" => nil,
              "project_id" => @map.fetch("project_id"), "params" => state.slice("assignment_id", "attempt_id").merge("mapping_id" => mapping_id)},
              deadline: deadline, limit: 16_384)
            ready = wire.read(socket, deadline: deadline, limit: 16_384)
            validate_launch_control_ready!(ready, state)
            yield socket, transfer_codec, ready
          end
        rescue IOError, SystemCallError
          raise AttemptErrors::EvidenceUnavailable, "Original launch control connection is unavailable"
        end

        private

        def validate_launch_control_ready!(ready, state)
          unless ready.is_a?(Hash) && ready.keys.sort == %w[attempt_id generation journal_commit original_binding_digest type version] &&
              ready["version"].is_a?(Integer) && ready["version"] == 1 && ready["type"] == "launch_control_ready" &&
              ready["attempt_id"] == state.fetch("attempt_id") && ready["generation"].is_a?(Integer) && ready["generation"].positive? &&
              ready["journal_commit"].is_a?(String) && ready["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              ready["original_binding_digest"].is_a?(String) && ready["original_binding_digest"].match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::EvidenceUnavailable, "Original launch control admission is unavailable"
          end
          true
        end

        def validate_evidence_download!(data, params)
          descriptor, transfer = data.values_at("descriptor", "transfer")
          unless data.keys.sort == %w[descriptor generation journal_commit transfer] &&
              Molecules::CanonicalEvidence.valid_descriptor?(descriptor) &&
              descriptor["project_id"] == @map.fetch("project_id") &&
              {"assignment_id" => "assignment_id", "attempt_id" => "attempt_id", "kind" => "kind",
                "request_id_or_event_id" => "purpose_id", "artifact_id" => "artifact_id"}.all? { |field, key| descriptor[field] == params[key] } &&
              data["generation"].is_a?(Integer) && data["generation"] >= 0 &&
              data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A[0-9a-f]{40,64}\z/) &&
              transfer.is_a?(Hash) && transfer.keys.sort == %w[bytes parts sha256 version] && transfer["version"] == 1 &&
              transfer["bytes"] == descriptor["bytes"] && transfer["sha256"] == descriptor["sha256"] &&
              transfer["parts"] == [descriptor.slice("bytes", "sha256")]
            raise AttemptErrors::EvidenceUnavailable, "canonical download descriptor differs"
          end
        end

        def transfer_codec
          peer = @kernel.capture(Process.pid)
          project = @deployment.project(@map.fetch("project_id"))
          installed = project.fetch("peer_credentials").fetch(peer.fetch("uid").to_s)
          unless peer["gid"] == installed["gid"] && peer["groups"] == installed["groups"]
            raise AttemptErrors::UnauthorizedIdentity, "transfer scratch principal differs"
          end
          TransferCodec.new(root: installed.fetch("scratch_root"))
        end
      end
    end
  end
end
