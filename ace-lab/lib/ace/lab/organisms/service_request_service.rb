# frozen_string_literal: true

require "open3"
require "ace/assign"

module Ace
  module Lab
    module Organisms
      # Coordinates the generic request contract. ace-assign owns the durable
      # claim and receipt; this class never writes evidence files directly.
      class ServiceRequestService
        def initialize(topology: nil, policy: nil, coordinator: nil, executor: nil, repo_root: Dir.pwd)
          @topology = topology || TopologyService.from_config
          @policy = policy
          @coordinator = coordinator || Ace::Assign::Organisms::AttemptCoordinator.new(repo_root: repo_root)
          @executor = executor || Molecules::ServiceExecutor.new
          @repo_root = repo_root
        end

        def request(project:, assignment:, attempt:, operation:, input_path:, authorization:, request_id:, dry_run: false)
          {project: project, assignment: assignment, attempt: attempt, request: request_id}.each do |name, value|
            raise ArgumentError, "invalid #{name} ID" unless value.is_a?(String) &&
              value.match?(Molecules::ServicePolicy::ID)
          end
          input = Atoms::ServiceInput.load(input_path)
          target = Atoms::ServiceInput.target(input)
          route = @topology.route(project: project, capability: operation)
          return route.envelope unless route.ok?
          service_id = route.data.fetch("entry").fetch("id")
          trusted = Molecules::GrantResolver.trusted_document(Ace::Lab.authorization_path) unless @policy
          policy = @policy || Molecules::ServicePolicy.new(trusted)
          head = current_head
          binding = {"request_id" => request_id, "assignment_id" => assignment, "attempt_id" => attempt,
                     "project_id" => project, "operation" => operation,
                     "input_digest" => Atoms::ServiceInput.digest(input), "target" => target,
                     "candidate_head" => head, "caller_uid" => Process.uid}
          binding["authorization"] = authorization
          binding["service_id"] = service_id
          binding["caller_uid"] = Process.uid
          validate_attempt!(binding)
          begin
            operation_policy = policy.operation!(operation, project: project, service_id: service_id)
            policy.authorize!(authorization, binding)
          rescue SecurityError, Ace::Lab::InvalidConfigurationError
            @coordinator.reject_service_request(binding, reason: "policy_rejected") unless dry_run
            raise
          end

          if dry_run
            preview = {"outcome" => "accepted", "dry_run" => true, "request_id" => request_id,
                       "project" => project, "operation" => operation, "service_id" => service_id,
                       "target" => target, "candidate_head" => head}
            return {"status" => "ok", "data" => preview}
          end

          claimed = @coordinator.claim_service_request(binding)
          return result(claimed) unless claimed["state"] == "accepted" && claimed["journal_commit"]

          # From here, a crash or lost executor response must not authorize a
          # replay. Record uncertainty before invoking an external process.
          @coordinator.transition_service_request(request_id, state: "uncertain")
          receipt = @executor.execute(operation: operation_policy, request: binding, input: input,
            policy: policy, authorization: authorization)
          return result(@coordinator.service_request_status(request_id)) if receipt.nil?

          state = receipt.fetch("outcome")
          full_receipt = Models::ServiceReceipt.build(binding, receipt)
          result(@coordinator.transition_service_request(request_id, state: state, receipt: full_receipt))
        rescue ArgumentError => e
          failure("invalid_input", e.message)
        rescue SecurityError => e
          failure("unauthorized", e.message)
        rescue Ace::Lab::InvalidConfigurationError => e
          failure("invalid_configuration", e.message)
        rescue Ace::Assign::AttemptErrors::Conflict => e
          failure("conflict", e.message)
        rescue Ace::Assign::AttemptErrors::NotFound, Ace::Assign::AttemptErrors::ReceiptRejected => e
          failure("invalid_attempt", e.message)
        rescue Ace::Assign::AttemptErrors::InvalidState => e
          failure("invalid_attempt", e.message)
        rescue Ace::Assign::AttemptErrors::EvidenceUnavailable => e
          failure("evidence_unavailable", e.message)
        end

        def status(request_id:)
          request = @coordinator.service_request_status(request_id)
          return failure("missing", "service request not found") unless request
          return failure("unauthorized", "caller does not own the request") unless request["caller_uid"] == Process.uid
          visibility = @topology.services(project: request["project_id"])
          return visibility.envelope unless visibility.ok?
          result(request)
        rescue ArgumentError => e
          failure("invalid_input", e.message)
        rescue Ace::Assign::AttemptErrors::EvidenceUnavailable => e
          failure("evidence_unavailable", e.message)
        end

        private

        def validate_attempt!(binding)
          attempt = @coordinator.service_attempt(binding)
          unless attempt.candidate_head.nil? || attempt.candidate_head == binding["candidate_head"]
            raise SecurityError, "request is not bound to an active managed attempt"
          end
        end

        def current_head
          out, _stderr, status = Open3.capture3("git", "rev-parse", "HEAD", chdir: @repo_root)
          raise SecurityError, "candidate head is unavailable" unless status.success?
          out.strip
        end

        def result(request)
          public = request.slice("request_id", "assignment_id", "attempt_id", "project_id", "operation",
            "input_digest", "target", "candidate_head", "service_id", "state", "receipt")
          {"status" => "ok", "data" => public.merge("outcome" => request.fetch("state"))}
        end

        def failure(code, message)
          {"status" => "error", "error" => {"code" => code, "message" => message}}
        end
      end
    end
  end
end
