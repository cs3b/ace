# frozen_string_literal: true

module Ace
  module Lab
    module Organisms
      class ProtectedServiceReceiver
        RECOVERY_BINDING = %w[assignment_id attempt_id candidate_generation head request_id].freeze
        RECOVERY_EXECUTION = %w[mapping_id candidate_generation head claim_binding dispatch_phase].freeze
        CLEANUP_RECOVERY_EXECUTION = (RECOVERY_EXECUTION + %w[operation_owner_binding executor_process_binding
          request_event_digest dispatch_event_digest]).freeze
        RECOVERY_CHALLENGE = %w[request_id input_digest claim_binding no_effect_challenge challenge_generation
          failure_event_digest failure_generation challenge_event_digest].freeze

        def recover_no_effect(binding:, input_bytes:, mutation_id:, expected_generation:)
          request_id = nil
          recovery_binding!(binding, input_bytes, mutation_id, expected_generation)
          params = immutable(binding)
          input_bytes = input_bytes.dup.freeze
          mutation_id = mutation_id.dup.freeze
          recovery_binding!(params, input_bytes, mutation_id, expected_generation)
          request_id = params.fetch("request_id")
          recovery_executor!
          status, context, input = recovery_status!(params, input_bytes)
          return projection(status) if %w[succeeded failed-settled].include?(status.fetch("state"))
          unless context["challenge"]
            claim_params = params.merge("expected_generation" => expected_generation)
            begin
              @client.call("claim_service_settlement", claim_params, mutation_id: mutation_id)
            rescue Ace::Runtime::RuntimeUnavailableError
              # Recover a possibly accepted challenge through current status,
              # never refreshing the original generation or silently claiming.
            end
            status, context, input = recovery_status!(params, input_bytes)
            return projection(status) if %w[succeeded failed-settled].include?(status.fetch("state"))
            return uncertain(request_id) unless context["challenge"]
          end
          operation = recovery_inspector!(context)
          root = Ace::Assign::Authority::PrivateDirectory.verify!(@receiver.fetch("staging_root"))
          directory = Dir.mktmpdir("recovery-", root)
          File.chmod(0o700, directory)
          identity = File.lstat(directory)
          envelope = immutable("version" => 1, "kind" => "service_no_effect_inspection",
            "request" => context.fetch("request"), "input" => input.fetch(:input),
            "execution" => context.fetch("execution"), "challenge" => context.fetch("challenge"))
          # The selected domain inspector produces absence observations; this
          # owner cannot derive them from a timeout or process/scope cleanup.
          if context.dig("request", "operation") == "prune-preserved-workspace"
            return uncertain(request_id) unless @cleanup_owner && context.dig("execution", "dispatch_phase") == "dispatch_started"
            artifacts = cleanup_inspection_evidence!(context, input.fetch(:input))
            response = {"outcome" => "failed", "request_id" => request_id,
              "input_digest" => context.dig("request", "input_digest"), "evidence" => artifacts.each_with_index.map do |artifact, index|
                {"ref" => index.zero? ? "cleanup-inspection-no-effect" : "cleanup-inspection-selection", "sha256" => Digest::SHA256.hexdigest(artifact)}
              end}
          else
            response = @handler.execute(operation: immutable(operation), envelope: envelope, candidate_root: directory)
          end
          return uncertain(request_id) unless response && response["outcome"] == "failed" &&
            response["request_id"] == request_id && response["input_digest"] == context.dig("request", "input_digest")
          artifacts ||= Ace::Assign::Authority::EvidenceTransfer.read_staged(root: directory, evidence: response.fetch("evidence"))
          receipt = context.fetch("request").merge("outcome" => "failed", "evidence" => response.fetch("evidence"))
          bytes = JSON.generate(receipt)
          completion_params = params.merge("claim_binding" => context.dig("execution", "claim_binding"),
            "reconciliation_challenge" => context.fetch("challenge").slice("no_effect_challenge", "challenge_generation", "challenge_event_digest"),
            "receipt_sha256" => Digest::SHA256.hexdigest(bytes))
          @client.call("complete_no_effect", completion_params,
            mutation_id: Digest::SHA256.hexdigest("no-effect:#{mutation_id}"),
            upload_parts: [bytes] + artifacts, purpose: :receipt_artifacts)
          # Protected status invokes the shared canonical receipt/import reader.
          # Never accept a terminal state string without that authentication.
          settled, = recovery_status!(params, input_bytes)
          return uncertain(request_id) unless settled["state"] == "failed-settled"
          cleanup_staging(directory, identity, prefix: "recovery-")
          projection(settled)
        rescue Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError, Ace::Lab::InvalidConfigurationError,
          SecurityError, ArgumentError, KeyError, TypeError, SystemCallError
          uncertain(request_id)
        end

        private

        def recovery_binding!(binding, bytes, mutation_id, generation)
          unless binding.is_a?(Hash) && binding.keys.sort == RECOVERY_BINDING.sort &&
              %w[assignment_id attempt_id request_id].all? { |key| binding[key].is_a?(String) && binding[key].match?(Ace::Assign::Molecules::JournalMutation::ID) } &&
              binding["head"].is_a?(String) && binding["head"].match?(Ace::Assign::Authority::CandidateTransfer::SHA) &&
              binding["candidate_generation"].is_a?(Integer) && binding["candidate_generation"] >= 0 &&
              generation.is_a?(Integer) && generation.positive? && bytes.is_a?(String) &&
              mutation_id.is_a?(String) && mutation_id.match?(Ace::Assign::Molecules::JournalMutation::ID)
            raise ArgumentError, "original recovery binding is invalid"
          end
        end

        def recovery_executor!
          me = @kernel.capture(Process.pid)
          credentials = @project.fetch("peer_credentials").fetch(@receiver.fetch("executor_uid").to_s)
          unless me["uid"] == @receiver.fetch("executor_uid") && me["gid"] == credentials.fetch("gid") &&
              me["groups"] == credentials.fetch("groups")
            raise SecurityError, "recovery executor differs"
          end
          @kernel.live!(me)
        end

        def recovery_status!(params, bytes)
          reply = @client.call("service_status", params)
          data = reply.data
          context = data.fetch("settlement_context")
          unless context.is_a?(Hash) && context.keys.sort == %w[version request execution challenge].sort &&
              context["version"].is_a?(Integer) && context["version"] == 1
            raise SecurityError, "canonical recovery context is malformed"
          end
          request, execution, challenge = context.values_at("request", "execution", "challenge")
          execution_fields = request.is_a?(Hash) && request["operation"] == "prune-preserved-workspace" &&
            execution.is_a?(Hash) && execution["dispatch_phase"] == "dispatch_started" ? CLEANUP_RECOVERY_EXECUTION : RECOVERY_EXECUTION
          unless request.is_a?(Hash) && request.keys.sort == Ace::Assign::Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS.sort &&
              execution.is_a?(Hash) && execution.keys.sort == execution_fields.sort &&
              %w[assignment_id attempt_id request_id].all? { |key| request[key] == params.fetch(key) } &&
              request["project_id"] == @map.fetch("project_id") && request["executor_uid"] == @receiver.fetch("executor_uid") &&
              request["transport"] == "unix" && request["candidate_head"] == params.fetch("head") &&
              execution["mapping_id"] == @mapping_id && execution["candidate_generation"] == params.fetch("candidate_generation") &&
              execution["head"] == params.fetch("head") && %w[issued dispatch_started].include?(execution["dispatch_phase"]) &&
              %w[uncertain failed succeeded failed-settled].include?(data["state"]) &&
              data["request_id"] == params.fetch("request_id") && data["service_id"] == @service_id
            raise SecurityError, "canonical recovery original binding differs"
          end
          if !challenge.nil? && (!challenge.is_a?(Hash) || challenge.keys.sort != RECOVERY_CHALLENGE.sort ||
              !%w[challenge_generation failure_generation].all? { |key| challenge[key].is_a?(Integer) && challenge[key].positive? } ||
              challenge["request_id"] != request["request_id"] || challenge["input_digest"] != request["input_digest"] ||
              challenge["claim_binding"] != execution["claim_binding"])
            raise SecurityError, "canonical recovery challenge differs"
          end
          input = @inputs.input_binding(bytes, expected_digest: request.fetch("input_digest"),
            expected_target: request.fetch("target"), operation: request.fetch("operation"))
          [data, immutable(context), input]
        end

        def cleanup_inspection_evidence!(context, input)
          request, execution = context.values_at("request", "execution")
          result = @cleanup_owner.inspect!(request: request.slice("request_id", "input_digest").merge(
            "claim_binding" => execution.fetch("claim_binding"),
            "request_event_digest" => execution.fetch("request_event_digest"),
            "dispatch_event_digest" => execution.fetch("dispatch_event_digest"), "input" => input,
            "challenge_ref" => context.fetch("challenge").slice("challenge_event_digest")),
            operation_owner_binding: execution.fetch("operation_owner_binding"))
          ref, bytes = result.values_at(:inspection_ref, :bytes)
          unless ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] && bytes.is_a?(String) &&
              bytes.bytesize.between?(1, 65_536) && ref["bytes"].is_a?(Integer) && ref["bytes"] == bytes.bytesize &&
              ref["sha256"] == Digest::SHA256.hexdigest(bytes)
            raise SecurityError, "original cleanup inspection result differs"
          end
          selection = {"schema" => Ace::Assign::Authority::ServiceCleanupEvidence::ROOT_INSPECTION_SELECTION_SCHEMA,
            "request_id" => request.fetch("request_id"), "input_digest" => request.fetch("input_digest"),
            "operation_owner_binding_digest" => Ace::Assign::Atoms::EvidenceDigest.digest(execution.fetch("operation_owner_binding")),
            "inspection_ref" => ref}
          [bytes, JSON.generate(selection)].freeze
        end

        def recovery_inspector!(context)
          request = context.fetch("request")
          policy = Molecules::ServicePolicy.new(Molecules::GrantResolver.trusted_document(Ace::Lab.authorization_path))
          policy.inspection!(request.fetch("operation"), project: @map.fetch("project_id"),
            service_id: @service_id, executor_uid: @receiver.fetch("executor_uid"))
        end
      end
    end
  end
end
