# frozen_string_literal: true
require "securerandom"
require_relative "deployment"
require_relative "transfer_codec"
require_relative "campaign_execution"
require_relative "candidate_transfer"
require_relative "../molecules/canonical_evidence"
require_relative "../molecules/execution_scope_lineage"

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
          if operation == "register_assignment" && (!upload_parts || purpose != :candidate || download)
            raise ArgumentError, "prepared registration requires fixed candidate upload"
          end
          if operation == "evidence_fetch" && (!download || purpose != (%w[prepared_work campaign_candidate].include?(params["kind"]) ? :candidate : :artifacts) || upload_parts)
            raise ArgumentError, "evidence fetch requires source-fixed kind download"
          end
          if operation == "submit_result" && (!upload_parts || purpose != :receipt_artifacts || download)
            raise ArgumentError, "result submission requires fixed receipt upload"
          end
          if operation == "campaign_export_result" && (!download || purpose != :artifacts || upload_parts || mutation_id)
            raise ArgumentError, "campaign result requires fixed read-only artifact download"
          end
          if operation == "campaign_record_round" && (!upload_parts || purpose != :receipt_artifacts || download)
            raise ArgumentError, "campaign round requires fixed bounded upload"
          end
          @deployment.verify!(mapping_id, kernel: @kernel)
          wire = Ace::Runtime::Molecules::ProtectedSocket
          path = @service.fetch("socket_path")
          before = wire.socket_identity(path)
          raise Ace::Runtime::RuntimeUnavailableError, "authority endpoint owner differs" unless before.last == @service.fetch("uid")
          raise ArgumentError, "cannot upload and download on one request" if upload_parts && download
          prepared_download = operation == "evidence_fetch" && %w[prepared_work campaign_candidate].include?(params["kind"])
          codec = transfer_codec if upload_parts || download && !prepared_download
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
            if %w[bind_inbox finish recover request_review review_status launch_review_intent cancel_review assignment_inventory evidence_fetch observe_execution_scope close_execution_scope stop_attempt prompt_status launch_input_inhibit_selection launch_input_inhibit_completion launch_prompt_intent launch_prompt_completion claim_service_settlement workspace_prune_preview_context].include?(operation) || (operation == "attempt_status" && params.key?("result_candidate_generation"))
              socket.shutdown(Socket::SHUT_WR)
            end
            if upload_parts
              codec.send(socket, parts: upload_parts, descriptor: descriptor, purpose: purpose, deadline: deadline)
              socket.shutdown(Socket::SHUT_WR)
            end
            result = wire.read(socket, deadline: deadline, limit: 16_384)
            unless result.is_a?(Hash) && result["status"] == "ok" && result["data"].is_a?(Hash)
              code = result.is_a?(Hash) ? result.dig("error", "code") : nil
              raise AttemptErrors::BoundedResultUnavailable, "protected authority result exceeds frame bound" if code == "bounded_result"
              raise AttemptErrors::EvidenceUnavailable, "protected authority refused (#{code || 'invalid_response'})"
            end
            transport = result.fetch("transport")
            unless transport.is_a?(Hash) && transport.keys == ["replayed"] && [true, false].include?(transport["replayed"])
              raise AttemptErrors::EvidenceUnavailable, "authority replay metadata is unavailable"
            end
            if operation == "evidence_fetch"
              if %w[prepared_work campaign_candidate].include?(params["kind"]) && transport.fetch("replayed")
                raise AttemptErrors::EvidenceUnavailable, "prepared fetch cannot replay a mutation"
              end
              validate_evidence_download!(result.fetch("data"), params)
            end
            parts = if download
              codec = prepared_transfer_codec(result.fetch("data").fetch("descriptor")) if prepared_download
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
          if params["kind"] == "prepared_work"
            validate_prepared_download!(data, params)
            return
          end
          if params["kind"] == "campaign_candidate"
            validate_campaign_candidate_download!(data, params)
            return
          end
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

        def validate_prepared_download!(data, params)
          descriptor, transfer = data.values_at("descriptor", "transfer")
          fields = %w[version kind purpose artifact project_id mapping_id assignment_id attempt_id task_id scope definition_digest selection_sha256 prepared_head prepared_tree manifest_bytes manifest_sha256 registration_generation registration_commit original_binding_digest ref bytes sha256 task_context_entry original_worker_identity original_worker_scratch_root workspace_exclusion].sort
          valid = data.keys.sort == %w[descriptor generation journal_commit transfer] && descriptor.is_a?(Hash) && descriptor.keys.sort == fields &&
            descriptor["version"].is_a?(Integer) && descriptor["version"] == 1 &&
            params.values_at("kind", "purpose_id", "artifact_id") == %w[prepared_work original_prepared_work prepared_bundle] &&
            descriptor.values_at("kind", "purpose", "artifact") == %w[prepared_work original_prepared_work prepared_bundle] &&
            descriptor["project_id"] == @map.fetch("project_id") && descriptor["mapping_id"] == mapping_id &&
            %w[assignment_id attempt_id].all? { |key| descriptor[key] == params[key] } &&
            descriptor["task_id"].is_a?(String) && descriptor["task_id"].match?(Deployment::TOKEN) &&
            descriptor["scope"].is_a?(String) && descriptor["scope"].bytesize.between?(1, 128) && descriptor["scope"].match?(/\A[0-9]+(?:\.[0-9]+)*\z/) &&
            %w[definition_digest selection_sha256 manifest_sha256 original_binding_digest sha256].all? { |key| descriptor[key].is_a?(String) && descriptor[key].match?(/\A[0-9a-f]{64}\z/) } &&
            %w[prepared_head prepared_tree].all? { |key| descriptor[key].is_a?(String) && descriptor[key].match?(/\A[0-9a-f]{40}\z/) } &&
            descriptor["manifest_bytes"].is_a?(Integer) && descriptor["manifest_bytes"].between?(1, 32_768) &&
            descriptor["registration_generation"].is_a?(Integer) && descriptor["registration_generation"].positive? &&
            descriptor["bytes"].is_a?(Integer) && descriptor["bytes"].between?(1, TransferCodec::LIMITS.fetch(:candidate).first) &&
            descriptor["registration_commit"].is_a?(String) && descriptor["registration_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
            descriptor["ref"] == "execution/prepared/#{params.fetch('assignment_id')}-#{descriptor['sha256']}.bundle" &&
            data["generation"].is_a?(Integer) && data["generation"].positive? &&
            data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
            transfer.is_a?(Hash) && transfer.keys.sort == %w[bytes parts sha256 version] && transfer["version"].is_a?(Integer) && transfer["version"] == 1 &&
            transfer.values_at("bytes", "sha256") == descriptor.values_at("bytes", "sha256") && transfer["parts"] == [descriptor.slice("bytes", "sha256")]
          raise AttemptErrors::EvidenceUnavailable, "original prepared download descriptor differs" unless valid
          TaskContextEntry.validate!(descriptor.fetch("task_context_entry"))
          Molecules::LifecycleExclusion.workspace_reader(projection: descriptor.fetch("workspace_exclusion"))
          unless descriptor.dig("workspace_exclusion", "root_resource", "view_path") ==
              "/run/ace/lifecycle-exclusion/#{descriptor.fetch('mapping_id')}"
            raise AttemptErrors::EvidenceUnavailable, "original prepared lifecycle mapping differs"
          end
          identity = descriptor.fetch("original_worker_identity")
          birth = identity.is_a?(Hash) && identity["started_at"]
          boot = birth.is_a?(String) && birth.split(":", -1)[1]
          Molecules::ExecutionScopeLineage.validate_process_identity!(identity, boot_id: boot)
          root = descriptor.fetch("original_worker_scratch_root")
          unless root.is_a?(String) && root.valid_encoding? && root.bytesize.between?(2, 4096) &&
              root.start_with?("/") && !root.include?("\0") && File.expand_path(root) == root
            raise AttemptErrors::EvidenceUnavailable, "original prepared scratch root differs"
          end
        rescue ArgumentError, KeyError
          raise AttemptErrors::EvidenceUnavailable, "original prepared download descriptor differs"
        end

        def validate_campaign_candidate_download!(data, params)
          descriptor, transfer = data.values_at("descriptor", "transfer")
          fields = %w[head tree bytes sha256 candidate_generation campaign_execution mapping_id assignment_id attempt_id
            project_id original_worker_identity original_worker_scratch_root original_binding_digest].sort
          unless data.keys.sort == %w[descriptor generation journal_commit transfer] &&
              descriptor.is_a?(Hash) && descriptor.keys.sort == fields &&
              params.values_at("purpose_id", "artifact_id") == %w[original_campaign_candidate candidate_bundle] &&
              descriptor["mapping_id"] == mapping_id && descriptor["project_id"] == @map.fetch("project_id") &&
              %w[assignment_id attempt_id].all? { |key| descriptor[key] == params[key] } &&
              %w[head tree].all? { |key| descriptor[key].is_a?(String) && descriptor[key].match?(CandidateTransfer::SHA) } &&
              %w[sha256 original_binding_digest].all? { |key| descriptor[key].is_a?(String) && descriptor[key].match?(/\A[0-9a-f]{64}\z/) } &&
              descriptor["candidate_generation"].is_a?(Integer) && descriptor["candidate_generation"].positive? &&
              descriptor["bytes"].is_a?(Integer) && descriptor["bytes"].between?(1, CandidateTransfer::MAX_BYTES) &&
              descriptor["campaign_execution"].is_a?(Hash) && descriptor["campaign_execution"].keys.sort == CampaignExecution::FIELDS &&
              data["generation"].is_a?(Integer) && data["generation"].positive? &&
              data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              transfer.is_a?(Hash) && transfer.keys.sort == %w[bytes parts sha256 version] && transfer["version"] == 1 &&
              transfer["version"].is_a?(Integer) &&
              transfer.values_at("bytes", "sha256") == descriptor.values_at("bytes", "sha256") && transfer["parts"] == [descriptor.slice("bytes", "sha256")]
            raise AttemptErrors::EvidenceUnavailable, "original campaign candidate download differs"
          end
          identity = descriptor.fetch("original_worker_identity")
          birth = identity.is_a?(Hash) && identity["started_at"]
          Molecules::ExecutionScopeLineage.validate_process_identity!(identity, boot_id: birth.to_s.split(":", -1)[1])
          root = descriptor.fetch("original_worker_scratch_root")
          unless root.is_a?(String) && root.valid_encoding? && root.bytesize.between?(2, 4096) &&
              root.start_with?("/") && !root.include?("\0") && File.expand_path(root) == root
            raise AttemptErrors::EvidenceUnavailable, "original campaign scratch root differs"
          end
        rescue ArgumentError, KeyError
          raise AttemptErrors::EvidenceUnavailable, "original campaign candidate download differs"
        end

        def prepared_transfer_codec(descriptor)
          peer = @kernel.capture(Process.pid)
          original = descriptor.fetch("original_worker_identity")
          unless peer.values_at("uid", "gid", "groups") == original.values_at("uid", "gid", "groups")
            raise AttemptErrors::UnauthorizedIdentity, "original prepared scratch principal differs"
          end
          TransferCodec.new(root: descriptor.fetch("original_worker_scratch_root"))
        end
      end
    end
  end
end
