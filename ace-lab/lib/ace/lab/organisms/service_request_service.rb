# frozen_string_literal: true

require "digest"
require "fileutils"
require "open3"
require "ace/assign"

module Ace
  module Lab
    module Organisms
      # Coordinates the generic request contract. ace-assign owns the durable
      # claim and receipt; this class never writes evidence files directly.
      class ServiceRequestService
        # Immutable request identity: a replay must match every field; the
        # candidate head is deliberately absent because replays return the
        # head recorded at claim time.
        SERVICE_REPLAY_FIELDS = %w[project_id operation input_digest assignment_id attempt_id
          target authorization caller_uid request_id].freeze

        def initialize(topology: nil, policy: nil, coordinator: nil, executor: nil, repo_root: nil)
          @topology = topology || TopologyService.from_config
          @policy = policy
          @repo_root = repo_root || git_toplevel
          @coordinator = coordinator ||
            Ace::Assign::Organisms::AttemptCoordinator.new(repo_root: @repo_root)
          @executor = executor || Molecules::ServiceExecutor.new
        end

        def request(project:, assignment:, attempt:, operation:, input_path:, authorization:, request_id:, dry_run: false)
          {project: project, assignment: assignment, attempt: attempt, request: request_id}.each do |name, value|
            raise ArgumentError, "invalid #{name} ID" unless value.is_a?(String) &&
              value.match?(Molecules::ServicePolicy::ID)
          end
          input = Atoms::ServiceInput.load(input_path)
          target = Atoms::ServiceInput.target(input)
          # An identical retry returns the stored outcome — with the head
          # recorded at claim time — without re-checking attempt, policy, or
          # routing: a completed request must survive attempt terminality,
          # authorization expiry, routing changes, and candidate-head
          # advance. Any changed immutable field under the same request ID is
          # a conflict, never a replay.
          existing = @coordinator.service_request_status(request_id)
          if existing
            # Current project visibility gates replays: a revoked grant must
            # not expose stored receipts, though the old operation route and
            # authorization decision do not need to remain active.
            visibility = @topology.services(project: project)
            return visibility.envelope unless visibility.ok?
            supplied = {"request_id" => request_id, "assignment_id" => assignment, "attempt_id" => attempt,
                        "project_id" => project, "operation" => operation,
                        "input_digest" => Atoms::ServiceInput.digest(input), "target" => target,
                        "caller_uid" => Process.uid, "authorization" => authorization}
            changed = SERVICE_REPLAY_FIELDS.find do |field|
              existing[field] != supplied.fetch(field)
            end
            if changed
              raise Ace::Assign::AttemptErrors::Conflict,
                "Service request #{request_id} has different #{changed}"
            end
            if dry_run
              # A preview of an existing request still validates current
              # eligibility and reports itself as a dry run.
              @coordinator.request_eligible!(existing)
              return {"status" => "ok", "data" => result(existing).fetch("data").merge("dry_run" => true)}
            end
            return result(existing)
          end
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
          # The trusted policy owns executor identity and transport; the
          # journaled claim binds them so only that executor identity can
          # later complete the receipt. A local operation whose configured
          # executor is not this process is refused before any claim, so no
          # authorization is consumed by a dispatch that cannot happen.
          binding["executor_uid"] = operation_policy.fetch("executor_uid")
          binding["transport"] = transport = operation_policy.fetch("transport", "local")
          if transport == "local" &&
              (Process.uid != binding["executor_uid"] || Process.euid != binding["executor_uid"])
            # A preview records nothing: the durable rejection is only for
            # real submissions, so the request ID stays reusable.
            @coordinator.reject_service_request(binding, reason: "executor_identity_unavailable") unless dry_run
            raise SecurityError, "current OS identity is not the configured executor"
          end

          if dry_run
            # The preview applies the same read-only eligibility checks as
            # the claim — review evidence for external effects and the
            # current candidate head — so it cannot promise acceptance for a
            # request that would fail on submission.
            @coordinator.request_eligible!(binding)
            preview = {"outcome" => "accepted", "dry_run" => true, "request_id" => request_id,
                       "project" => project, "operation" => operation, "service_id" => service_id,
                       "target" => target, "candidate_head" => head}
            return {"status" => "ok", "data" => preview}
          end

          # The claim itself records uncertain (dispatch intent): a crash
          # after the claim leaves uncertainty, never a stranded accepted
          # state that a retry would return without dispatching.
          claimed = @coordinator.claim_service_request(binding)
          return result(claimed) unless claimed["state"] == "uncertain" && claimed["journal_commit"]

          # The executor reloads the trusted policy from disk at the effect
          # boundary: a revocation after the claim must still stop dispatch.
          begin
            receipt = @executor.execute(operation: operation_policy, request: binding, input: input,
              policy_loader: policy_loader, authorization: authorization,
              head_loader: -> { current_head })
          rescue SecurityError, Ace::Lab::InvalidConfigurationError => e
            # Refusal before invocation: no effect was attempted. When this
            # process is the executor identity (local transport), record a
            # proven no-effect settlement instead of stranding uncertainty.
            settle_pre_invocation_refusal(binding, request_id, e)
            raise
          end
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

        # A refusal raised before the handler was invoked proves no effect
        # was attempted. When this process runs as the executor identity
        # (local transport), record the proven no-effect settlement with an
        # executor-owned attestation; otherwise the claim stays uncertain
        # for evidence-based reconciliation.
        def settle_pre_invocation_refusal(binding, request_id, error)
          return unless binding["transport"] == "local" && Process.uid == binding["executor_uid"]
          evidence_dir = File.join(@repo_root, "evidence", "service")
          FileUtils.mkdir_p(evidence_dir)
          attestation = File.join(evidence_dir, "#{request_id}-no-effect")
          content = "ace-service-attestation request:#{request_id} " \
            "input:#{binding.fetch("input_digest")} outcome:failed no-effect:true\n" \
            "refusal: #{error.message}\n"
          # Exclusive creation without following symlinks: the caller-controlled
          # request ID must never truncate an existing file, and the artifact
          # must stay private to pass the executor-owned verification.
          File.open(attestation, File::WRONLY | File::CREAT | File::EXCL, 0600) do |file|
            file.write(content)
          end
          receipt = Models::ServiceReceipt.build(binding, {
            "outcome" => "failed",
            "evidence" => [{"ref" => "evidence/service/#{request_id}-no-effect",
                            "sha256" => Digest::SHA256.hexdigest(content)}],
            "executor_uid" => binding.fetch("executor_uid")
          })
          @coordinator.reconcile_service_no_effect(request_id, receipt: receipt)
        rescue Ace::Assign::AttemptErrors::InvalidState, Ace::Assign::AttemptErrors::ReceiptRejected,
               Ace::Assign::AttemptErrors::NotFound, Errno::ENOENT, Errno::EACCES, Errno::EEXIST
          nil
        end

        # The Git toplevel (not a package directory that happens to hold a
        # Rakefile) bounds evidence verification for nested invocations.
        def git_toplevel
          out, status = Open3.capture2("git", "rev-parse", "--show-toplevel")
          (status&.success? ? out.strip : Dir.pwd)
        rescue Errno::ENOENT
          Dir.pwd
        end

        def policy_loader
          if @policy
            -> { @policy }
          else
            -> { Molecules::ServicePolicy.new(Molecules::GrantResolver.trusted_document(Ace::Lab.authorization_path)) }
          end
        end

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
          # failed-settled is internal bookkeeping: the documented public
          # outcome stays "failed"; the state field distinguishes settlement.
          outcome = request.fetch("state") == "failed-settled" ? "failed" : request.fetch("state")
          {"status" => "ok", "data" => public.merge("outcome" => outcome)}
        end

        def failure(code, message)
          {"status" => "error", "error" => {"code" => code, "message" => message}}
        end
      end
    end
  end
end
