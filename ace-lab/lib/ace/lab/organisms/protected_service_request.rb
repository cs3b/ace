# frozen_string_literal: true
require "ace/assign/authority/protected_assignment_context"
require "ace/assign/organisms/protected_delivery_coordinator"
require_relative "protected_service_client"

module Ace
  module Lab
    module Organisms
      # Public selection adapter. The original authority and fixed receiver
      # own every grant/effect; this adapter has no local journal or executor.
      class ProtectedServiceRequest
        FLAGS = %i[mapping scope service candidate_head candidate_generation expected_generation input_digest target artifact_digest].freeze
        LIMIT = 16_384

        def initialize(context: Ace::Assign::Authority::ProtectedAssignmentContext.load, ingress_factory: nil)
          @context = context
          @ingress = ingress_factory || ->(**selection) { ProtectedServiceClient.new(**selection) }
        end

        def selected?(options)
          @context.protected_participant? || @context.mapping_hint? || FLAGS.any? { |key| !options[key].nil? }
        end

        def request(project:, assignment:, attempt:, operation:, input_path:, authorization:, request_id:, **options)
          refuse_nonworker!
          unless (options.keys - %i[mapping scope service candidate_head candidate_generation expected_generation dry_run]).empty?
            raise ArgumentError, "protected request rejects incompatible options"
          end
          raise ArgumentError, "protected service request requires merge and no dry-run" unless operation == "merge" && !options[:dry_run]
          validate!(project, assignment, attempt, request_id, options)
          unless authorization.is_a?(String) && authorization.match?(Molecules::ServicePolicy::ID) &&
              options[:service].is_a?(String) && options[:service].match?(Molecules::ServicePolicy::ID) &&
              options[:expected_generation].is_a?(Integer) && options[:expected_generation].positive?
            raise ArgumentError, "protected service request requires receiver, authorization and original generation"
          end
          input = Atoms::ServiceInput.load(input_path)
          unless input.keys.sort == %w[delivery method target] && input["target"].is_a?(Hash) &&
              input["target"].keys.sort == %w[artifact_digest resource] &&
              input["delivery"] == Ace::Git::Atoms::DeliveryParameters.validate(input["delivery"]) &&
              Ace::Git::Organisms::PullRequestLifecycle::MERGE_METHODS.map(&:to_s).include?(input["method"])
            raise ArgumentError, "protected service input requires normalized merge selection"
          end
          target = Atoms::ServiceInput.target(input)
          reference = Ace::Git::Atoms::PrReference.parse(target.fetch("resource"))
          unless reference && reference.repository_url
            raise ArgumentError, "protected merge target requires an exact PR URL"
          end
          digest = Atoms::ServiceInput.digest(input)
          prepared = resolve!(project, assignment, attempt, options)
          selection = {"project_id" => project, "mapping_id" => options.fetch(:mapping), "assignment_id" => assignment,
            "attempt_id" => attempt, "scope" => options.fetch(:scope), "service_id" => options.fetch(:service),
            "candidate_head" => options.fetch(:candidate_head), "candidate_generation" => options.fetch(:candidate_generation),
            "expected_generation" => options.fetch(:expected_generation), "request_id" => request_id,
            "input_digest" => digest, "target" => target}
          submission = {"assignment_id" => assignment, "attempt_id" => attempt, "expected_generation" => options.fetch(:expected_generation),
            "candidate_generation" => options.fetch(:candidate_generation), "head" => options.fetch(:candidate_head),
            "request_id" => request_id, "operation" => "merge", "input_digest" => digest, "target" => target,
            "authorization" => authorization}
          mutation = Digest::SHA256.hexdigest("qkb.merge.claim:v1:#{assignment}:#{attempt}:#{request_id}")
          claim = @context.with_installed_selection(options: options, input: prepared) do |deployment, kernel, mapping|
            @ingress.call(mapping_id: mapping, service_id: options.fetch(:service), deployment: deployment, kernel: kernel)
              .submit(submission: submission, input_bytes: JSON.generate(input), mutation_id: mutation)
          end
          envelope = if claim.fetch("type") == "service_claim_accepted"
            {"status" => "ok", "data" => {"selection" => selection, "claim" => claim}}
          else
            code = claim.fetch("type")
            {"status" => "error", "error" => {"code" => code,
              "message" => "inspect original canonical service status; no automatic resubmission",
              "selection" => selection, "claim" => claim}}
          end
          bounded!(envelope)
        end

        def status(request_id:, **options)
          refuse_nonworker!
          unless (options.keys - %i[project assignment attempt mapping scope candidate_head candidate_generation input_digest target artifact_digest format]).empty?
            raise ArgumentError, "protected status rejects incompatible options"
          end
          project, assignment, attempt = options.values_at(:project, :assignment, :attempt)
          validate!(project, assignment, attempt, request_id, options)
          unless options[:input_digest].is_a?(String) && options[:input_digest].match?(Atoms::ServiceInput::SHA256)
            raise ArgumentError, "protected status requires original input digest"
          end
          target = Atoms::ServiceInput.target({"target" => {"resource" => options[:target], "artifact_digest" => options[:artifact_digest]}})
          resolve!(project, assignment, attempt, options)
          data = Ace::Assign::Organisms::ProtectedDeliveryCoordinator.new(client: @context.client(options: options), project_id: project)
            .perform(assignment_id: assignment, attempt_id: attempt, operation: "status", service_request_id: request_id,
              candidate_head: options.fetch(:candidate_head), candidate_generation: options.fetch(:candidate_generation),
              input_digest: options.fetch(:input_digest), target: target)
          bounded!({"status" => "ok", "data" => data})
        end

        private

        def refuse_nonworker!
          if @context.protected_participant? && !@context.protected_worker?
            raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "protected service request/status is worker-only"
          end
        end

        def validate!(project, assignment, attempt, request_id, options)
          unless [project, assignment, attempt, request_id, options[:mapping]].all? { |value| value.is_a?(String) && value.match?(Molecules::ServicePolicy::ID) } &&
              options[:scope].is_a?(String) && options[:scope].match?(Ace::Assign::Authority::PreparedWork::SCOPE) &&
              options[:candidate_head].is_a?(String) && options[:candidate_head].match?(/\A[0-9a-f]{40}\z/) &&
              options[:candidate_generation].is_a?(Integer) && options[:candidate_generation].positive?
            raise ArgumentError, "protected service requires exact original scoped selectors"
          end
        end

        def resolve!(project, assignment, attempt, options)
          input = @context.resolve(options: options.merge(attempt: attempt), assignment_id: assignment, scope: options.fetch(:scope))
          unless input && input.descriptor.values_at("project_id", "assignment_id", "attempt_id", "scope", "mapping_id") ==
              [project, assignment, attempt, options.fetch(:scope), options.fetch(:mapping)]
            raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "original prepared service selection differs"
          end
          input
        end

        def bounded!(envelope)
          raise ArgumentError, "protected service output exceeds bound" if JSON.generate(envelope).bytesize > LIMIT
          envelope
        end
      end
    end
  end
end
